"""
Lambda function that checks for the latest AMI matching a specified filter and
compares it to a specified launch template, updating it if necessary. This
ensures launch templates are always configured with the latest AMI, which is
of particular use with auto scaling group auto refresh.

Environment variables:
  * AMI_FILTERS: A string representation of AMI filter key/value pairs. For
    example:
      name=amzn2-ami-hvm-2.*-x86_64-ebs;owner-alias=amazon
      - Pairs are separated by ;
      - Key and value are separated by =
      - Value is separated on , for lists

  * LAUNCH_TEMPLATE_NAME: The name of the launch template to check and update
  * LAUNCH_TEMPLATE_VERSION: The version string of the launch template to check,
    such as '$Latest', '$Default', or a specific version.
  * AWS_REGION: The AWS region to run in
"""
import boto3
import logging
import os

from dateutil import parser

ami_filters             = os.environ.get('AMI_FILTERS').split(';')
launch_template         = os.environ.get('LAUNCH_TEMPLATE_NAME')
launch_template_version = os.environ.get('LAUNCH_TEMPLATE_VERSION')
aws_region              = os.environ.get('AWS_REGION')

logger = logging.getLogger()
logger.setLevel(logging.INFO)

"""
Function to structure a string of key/value pairs into a filter for 'describe_instances()'

Example of a filter:
    name=amzn2-ami-hvm-2.*-x86_64-ebs;owner-alias=amazon

* Filter pairs are separated by ';'
* Key/Values are separated by '='
* Values are split by ','

Returns a dict
"""
def filter_pair(the_filter):
    key, value = the_filter.split('=')
    value = value.split(',')
    ret = {"Name": key, "Values": value}
    return(ret)

"""
Function to return the latest AMI ID matching specified filters
"""
def latest_ami(client):
    filters = list(map(filter_pair, (ami_filters)))

    list_of_images = client.describe_images(Owners=['amazon'], Filters=filters)['Images']
    latest = None

    for image in list_of_images:
        if not latest:
            latest = image
            continue

        if parser.parse(image['CreationDate']) > parser.parse(latest['CreationDate']):
            latest = image

    return latest['ImageId']

"""
Function that returns a specified launch template
"""
def get_launch_template(client):
    return client.describe_launch_template_versions(LaunchTemplateName=launch_template, Versions=[launch_template_version])['LaunchTemplateVersions'][0]

"""
Function that returns a launch template's current ImageId
"""
def current_ami(client):
    return get_launch_template(client)['LaunchTemplateData']['ImageId']

"""
Function to update a launch template ImageId
"""
def update_launch_template(client, **kwargs):
    try:
        response = client.create_launch_template_version(
            DryRun=False,
            LaunchTemplateName=kwargs['Name'],
            SourceVersion=str(kwargs['SourceVersion']),
            LaunchTemplateData={ "ImageId": latest_ami() },
            VersionDescription=f"Automatic update for AMI {latest_ami()}"
        )
        logging.info(f"Setting the launch template default version to {str(response['LaunchTemplateVersion']['VersionNumber'])}")

        client.modify_launch_template(
            LaunchTemplateName=kwargs['Name'],
            DefaultVersion=str(response['LaunchTemplateVersion']['VersionNumber'])
        )
    except:
        logging.critical("Failed to update launch template.")

def handler(event, context):
    # boto3 ec2 client used by several calls below
    client = boto3.client('ec2', region_name=aws_region)

    if latest_ami(client) == current_ami(client):
        logging.info(f"Latest AMI={latest_ami(client)}; Launch Template current AMI: {current_ami(client)}")
    else:
        logging.warning(f"Latest AMI={latest_ami(client)}; Launch Template current AMI: {current_ami(client)}; the launch template will be updated")
        update_launch_template(
            client,
            Name=launch_template,
            SourceVersion=get_launch_template(client)['VersionNumber']
        )

if __name__ == "__main__":
    handler(None, None)
