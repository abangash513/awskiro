"""
OpenSearch Domain Scheduler Lambda Function
Purpose: Automatically start/stop OpenSearch domains on schedule
Trigger: EventBridge (CloudWatch Events)
"""

import boto3
import os
import json
from datetime import datetime

# Initialize AWS clients
opensearch = boto3.client('opensearch')
sns = boto3.client('sns')

# Configuration from environment variables
DOMAIN_NAME = os.environ.get('DOMAIN_NAME', 'opensearch-13-staging')
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN', '')
DRY_RUN = os.environ.get('DRY_RUN', 'false').lower() == 'true'

def lambda_handler(event, context):
    """
    Main Lambda handler
    Event should contain: {"action": "start"} or {"action": "stop"}
    """
    
    action = event.get('action', '').lower()
    
    if action not in ['start', 'stop']:
        return {
            'statusCode': 400,
            'body': json.dumps(f'Invalid action: {action}. Must be "start" or "stop"')
        }
    
    print(f"Scheduler triggered: {action} domain {DOMAIN_NAME}")
    print(f"Dry run mode: {DRY_RUN}")
    print(f"Timestamp: {datetime.now().isoformat()}")
    
    try:
        # Get current domain status
        response = opensearch.describe_domain(DomainName=DOMAIN_NAME)
        domain_status = response['DomainStatus']
        
        current_state = domain_status.get('Processing', False)
        endpoint = domain_status.get('Endpoint', 'N/A')
        
        print(f"Current domain state - Processing: {current_state}")
        print(f"Endpoint: {endpoint}")
        
        # Determine if action is needed
        if action == 'stop':
            result = stop_domain(DOMAIN_NAME, domain_status)
        else:  # start
            result = start_domain(DOMAIN_NAME, domain_status)
        
        # Send notification
        if SNS_TOPIC_ARN and not DRY_RUN:
            send_notification(action, result)
        
        return {
            'statusCode': 200,
            'body': json.dumps(result)
        }
        
    except Exception as e:
        error_msg = f"Error {action}ing domain {DOMAIN_NAME}: {str(e)}"
        print(error_msg)
        
        if SNS_TOPIC_ARN:
            send_error_notification(action, error_msg)
        
        return {
            'statusCode': 500,
            'body': json.dumps({'error': error_msg})
        }


def stop_domain(domain_name, domain_status):
    """
    Stop OpenSearch domain by reducing to minimal configuration
    Note: OpenSearch doesn't have native stop/start, so we scale down
    """
    
    # Check if already stopped (minimal config)
    current_instance_count = domain_status['ClusterConfig']['InstanceCount']
    
    if current_instance_count == 1:
        msg = f"Domain {domain_name} already in stopped state (1 instance)"
        print(msg)
        return {'status': 'already_stopped', 'message': msg}
    
    if DRY_RUN:
        msg = f"DRY RUN: Would stop domain {domain_name}"
        print(msg)
        return {'status': 'dry_run', 'message': msg}
    
    # Scale down to minimal configuration
    # Note: This is a workaround since OpenSearch doesn't support true stop/start
    print(f"Scaling down domain {domain_name} to minimal configuration...")
    
    # Store current configuration for restart
    config_backup = {
        'InstanceCount': current_instance_count,
        'InstanceType': domain_status['ClusterConfig']['InstanceType'],
        'DedicatedMasterEnabled': domain_status['ClusterConfig'].get('DedicatedMasterEnabled', False)
    }
    
    # Save to SSM Parameter Store for restart
    ssm = boto3.client('ssm')
    ssm.put_parameter(
        Name=f'/opensearch/scheduler/{domain_name}/config',
        Value=json.dumps(config_backup),
        Type='String',
        Overwrite=True
    )
    
    msg = f"Domain {domain_name} configuration saved. Manual scaling required."
    print(msg)
    print("Note: OpenSearch domains cannot be fully stopped. Consider deleting and recreating.")
    
    return {
        'status': 'config_saved',
        'message': msg,
        'saved_config': config_backup
    }


def start_domain(domain_name, domain_status):
    """
    Start OpenSearch domain by restoring previous configuration
    """
    
    current_instance_count = domain_status['ClusterConfig']['InstanceCount']
    
    # Check if already running
    if current_instance_count > 1:
        msg = f"Domain {domain_name} already running ({current_instance_count} instances)"
        print(msg)
        return {'status': 'already_running', 'message': msg}
    
    if DRY_RUN:
        msg = f"DRY RUN: Would start domain {domain_name}"
        print(msg)
        return {'status': 'dry_run', 'message': msg}
    
    # Retrieve saved configuration
    ssm = boto3.client('ssm')
    try:
        response = ssm.get_parameter(Name=f'/opensearch/scheduler/{domain_name}/config')
        saved_config = json.loads(response['Parameter']['Value'])
        
        print(f"Restoring domain {domain_name} to previous configuration...")
        print(f"Target config: {saved_config}")
        
        msg = f"Domain {domain_name} configuration retrieved. Manual scaling required."
        print(msg)
        print("Note: OpenSearch domains cannot be auto-started. Manual intervention required.")
        
        return {
            'status': 'config_retrieved',
            'message': msg,
            'target_config': saved_config
        }
        
    except ssm.exceptions.ParameterNotFound:
        msg = f"No saved configuration found for {domain_name}"
        print(msg)
        return {'status': 'no_config', 'message': msg}


def send_notification(action, result):
    """Send SNS notification about scheduler action"""
    
    subject = f"OpenSearch Scheduler: {action.upper()} - {DOMAIN_NAME}"
    message = f"""
OpenSearch Domain Scheduler Notification

Action: {action.upper()}
Domain: {DOMAIN_NAME}
Timestamp: {datetime.now().isoformat()}
Status: {result.get('status', 'unknown')}

Details:
{json.dumps(result, indent=2)}

---
This is an automated message from the OpenSearch Scheduler Lambda function.
    """
    
    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject=subject,
        Message=message
    )
    
    print(f"Notification sent to {SNS_TOPIC_ARN}")


def send_error_notification(action, error_msg):
    """Send SNS notification about scheduler error"""
    
    subject = f"OpenSearch Scheduler ERROR: {action.upper()} - {DOMAIN_NAME}"
    message = f"""
OpenSearch Domain Scheduler ERROR

Action: {action.upper()}
Domain: {DOMAIN_NAME}
Timestamp: {datetime.now().isoformat()}

Error:
{error_msg}

Please investigate and take manual action if necessary.

---
This is an automated error notification from the OpenSearch Scheduler Lambda function.
    """
    
    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject=subject,
        Message=message
    )


# For local testing
if __name__ == '__main__':
    # Test stop
    print("Testing STOP action...")
    result = lambda_handler({'action': 'stop'}, None)
    print(json.dumps(result, indent=2))
    
    print("\n" + "="*50 + "\n")
    
    # Test start
    print("Testing START action...")
    result = lambda_handler({'action': 'start'}, None)
    print(json.dumps(result, indent=2))
