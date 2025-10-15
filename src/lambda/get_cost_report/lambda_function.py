# src/lambda/get_cost_report/lambda_function.py

import boto3
import os
from datetime import datetime, timedelta

# Initialize AWS clients
cost_explorer = boto3.client('ce', region_name='us-east-1')
ses = boto3.client('ses', region_name='us-east-1')

# Environment variables
SENDER_EMAIL = os.environ.get('SENDER_EMAIL')
RECIPIENT_EMAIL = os.environ.get('RECIPIENT_EMAIL')

# --- NEW MAPPING DICTIONARY ---
# This dictionary maps the technical service names from Cost Explorer to user-friendly names.
# You can add more services here as you see them in your reports.
SERVICE_MAPPINGS = {
    # --- Compute ---
    "Amazon Elastic Compute Cloud - Compute": "EC2 (Compute)",
    "AWS Lambda": "Lambda (Serverless Compute)",
    "Amazon Elastic Container Service": "ECS (Containers)",
    "Amazon Elastic Kubernetes Service": "EKS (Managed Kubernetes)",
    "AWS Fargate": "Fargate (Serverless Containers)",
    "Amazon Lightsail": "Lightsail (Simple VPS)",
    "AWS Batch": "Batch (Managed Batch Processing)",
    "AWS Outposts": "Outposts (Hybrid Cloud)",
    "AWS Local Zones": "Local Zones (Edge Compute)",

    # --- Storage ---
    "Amazon Simple Storage Service": "S3 (Object Storage)",
    "Amazon Elastic Block Store": "EBS (Block Storage)",
    "Amazon Elastic File System": "EFS (File Storage)",
    "Amazon FSx": "FSx (Windows/Lustre File System)",
    "AWS Backup": "Backup (Centralized Backup)",
    "AWS Storage Gateway": "Storage Gateway (Hybrid Storage)",
    "Amazon S3 Glacier": "Glacier (Archival Storage)",
    "AWS Snowball": "Snowball (Edge Data Transfer)",

    # --- Database ---
    "Amazon Relational Database Service": "RDS (Relational Database)",
    "Amazon Aurora": "Aurora (High Performance RDS)",
    "Amazon DynamoDB": "DynamoDB (NoSQL Database)",
    "Amazon Redshift": "Redshift (Data Warehouse)",
    "Amazon ElastiCache": "ElastiCache (In-memory Cache)",
    "Amazon Neptune": "Neptune (Graph Database)",
    "Amazon DocumentDB": "DocumentDB (MongoDB Compatible)",
    "Amazon Keyspaces": "Keyspaces (Managed Cassandra)",
    "AWS Database Migration Service": "DMS (Database Migration)",

    # --- Networking & Content Delivery ---
    "Amazon CloudFront": "CloudFront (CDN)",
    "Amazon Route 53": "Route 53 (DNS Service)",
    "Elastic Load Balancing": "ELB (Load Balancer)",
    "AWS Global Accelerator": "Global Accelerator (Traffic Optimization)",
    "AWS Transit Gateway": "Transit Gateway (Network Hub)",
    "AWS Direct Connect": "Direct Connect (Dedicated Network)",
    "Amazon VPC": "VPC (Virtual Private Cloud)",
    "AWS VPN": "VPN (Secure Network Connection)",
    "AWS PrivateLink": "PrivateLink (Private Connectivity)",
    "AWS Cloud WAN": "Cloud WAN (Global Networking)",

    # --- Developer Tools ---
    "AWS CodeBuild": "CodeBuild (Build Service)",
    "AWS CodeCommit": "CodeCommit (Git Repository)",
    "AWS CodeDeploy": "CodeDeploy (Deployment Service)",
    "AWS CodePipeline": "CodePipeline (CI/CD Orchestration)",
    "AWS Cloud9": "Cloud9 (Online IDE)",
    "AWS X-Ray": "X-Ray (Tracing & Monitoring)",
    "AWS CloudShell": "CloudShell (CLI in Browser)",

    # --- Management & Governance ---
    "AWS CloudFormation": "CloudFormation (IaC Templates)",
    "AWS Config": "Config (Resource Compliance)",
    "AWS CloudTrail": "CloudTrail (Activity Logs)",
    "Amazon CloudWatch": "CloudWatch (Monitoring)",
    "AWS Systems Manager": "Systems Manager (Ops Management)",
    "AWS Trusted Advisor": "Trusted Advisor (Best Practices)",
    "AWS Control Tower": "Control Tower (Governed Accounts)",
    "AWS Organizations": "Organizations (Account Management)",
    "AWS Service Catalog": "Service Catalog (Resource Templates)",
    "AWS License Manager": "License Manager (License Tracking)",
    "AWS Budgets": "Budgets (Cost Tracking)",
    "AWS Cost Explorer": "Cost Explorer (Billing Analytics)",

    # --- Security, Identity, Compliance ---
    "AWS Identity and Access Management": "IAM (Access Control)",
    "AWS Certificate Manager": "ACM (SSL Certificates)",
    "AWS WAF": "WAF (Web Application Firewall)",
    "AWS Shield": "Shield (DDoS Protection)",
    "AWS Secrets Manager": "Secrets Manager (Credential Storage)",
    "AWS KMS": "KMS (Encryption Keys)",
    "Amazon GuardDuty": "GuardDuty (Threat Detection)",
    "AWS Security Hub": "Security Hub (Unified Security View)",
    "AWS Detective": "Detective (Security Analysis)",
    "AWS Firewall Manager": "Firewall Manager (Central Policy)",
    "AWS Key Management Service": "KMS (Encryption Key Management)",

    # --- Analytics & Big Data ---
    "Amazon Athena": "Athena (Query S3 Data)",
    "Amazon EMR": "EMR (Hadoop/Spark Cluster)",
    "AWS Glue": "Glue (ETL Service)",
    "Amazon Kinesis": "Kinesis (Streaming Data)",
    "Amazon OpenSearch Service": "OpenSearch (Search & Analytics)",
    "AWS Data Pipeline": "Data Pipeline (Workflow Orchestration)",
    "AWS Lake Formation": "Lake Formation (Data Lake Management)",
    "AWS QuickSight": "QuickSight (Business Intelligence)",
    "AWS Data Exchange": "Data Exchange (Data Marketplace)",

    # --- Machine Learning & AI ---
    "Amazon SageMaker": "SageMaker (Machine Learning)",
    "Amazon Comprehend": "Comprehend (NLP)",
    "Amazon Rekognition": "Rekognition (Image/Video Analysis)",
    "Amazon Polly": "Polly (Text to Speech)",
    "Amazon Transcribe": "Transcribe (Speech to Text)",
    "Amazon Translate": "Translate (Language Translation)",
    "Amazon Lex": "Lex (Conversational AI)",
    "Amazon Textract": "Textract (Document OCR)",
    "Amazon Forecast": "Forecast (Time Series Prediction)",
    "Amazon Personalize": "Personalize (Recommendation Engine)",
    "AWS Inferentia": "Inferentia (ML Inference Chip)",
    "AWS Bedrock": "Bedrock (Foundation Models)",

    # --- Application Integration ---
    "Amazon Simple Queue Service": "SQS (Message Queue)",
    "Amazon Simple Notification Service": "SNS (Pub/Sub Messaging)",
    "AWS Step Functions": "Step Functions (Workflow Orchestration)",
    "Amazon EventBridge": "EventBridge (Event Bus)",
    "Amazon AppFlow": "AppFlow (SaaS Integration)",
    "Amazon MQ": "MQ (Managed Message Broker)",

    # --- Migration & Transfer ---
    "AWS Migration Hub": "Migration Hub (Migration Tracking)",
    "AWS Transfer Family": "Transfer Family (SFTP/FTPS/FTP)",
    "AWS DataSync": "DataSync (Data Transfer)",
    "AWS Application Migration Service": "MGN (Lift & Shift)",
    "AWS Server Migration Service": "SMS (Server Migration)",
    "AWS Snow Family": "Snow Family (Edge Migration)",

    # --- End-User Computing ---
    "Amazon WorkSpaces": "WorkSpaces (VDI Service)",
    "Amazon AppStream 2.0": "AppStream (Application Streaming)",
    "Amazon WorkDocs": "WorkDocs (Collaboration)",
    "Amazon WorkMail": "WorkMail (Email Service)",

    # --- Business Applications ---
    "Amazon Chime": "Chime (Video Conferencing)",
    "Amazon Connect": "Connect (Contact Center)",
    "Amazon Pinpoint": "Pinpoint (User Engagement)",

    # --- IoT ---
    "AWS IoT Core": "IoT Core (Device Connectivity)",
    "AWS IoT Greengrass": "IoT Greengrass (Edge Computing)",
    "AWS IoT Analytics": "IoT Analytics (Data Processing)",
    "AWS IoT Device Defender": "IoT Device Defender (Security)",
    "AWS IoT TwinMaker": "IoT TwinMaker (Digital Twins)",

    # --- Quantum / Emerging ---
    "Amazon Braket": "Braket (Quantum Computing)"
}


def lambda_handler(event, context):
    """
    This function fetches the AWS cost and usage report for the last 7 days
    and sends a summary email using SES.
    """
    # ... (the rest of this function remains unchanged) ...
    if not SENDER_EMAIL or not RECIPIENT_EMAIL:
        return {'statusCode': 400, 'body': 'Environment variables not set.'}
    end_date = datetime.now()
    start_date = end_date - timedelta(days=7)
    start_str = start_date.strftime('%Y-%m-%d')
    end_str = end_date.strftime('%Y-%m-%d')
    try:
        response = cost_explorer.get_cost_and_usage(TimePeriod={'Start': start_str, 'End': end_str}, Granularity='DAILY', Metrics=['UnblendedCost'], GroupBy=[{'Type': 'DIMENSION', 'Key': 'SERVICE'}])
        email_body = _create_email_body(response, start_str, end_str)
        _send_email(email_body, start_str, end_str)
        return {'statusCode': 200, 'body': 'Cost report email sent successfully!'}
    except Exception as e:
        print(f"An error occurred: {e}")
        return {'statusCode': 500, 'body': f'Error generating or sending cost report: {str(e)}'}

def _create_email_body(response, start_date, end_date):
    """Formats the Cost Explorer response into an HTML email body."""
    
    report_lines = ["<html><body>",
                    "<h2>AWS Cost Report Summary</h2>",
                    f"<p><b>Reporting Period:</b> {start_date} to {end_date}</p>",
                    "<table border='1' cellpadding='5' cellspacing='0'><tr style='background-color:#f2f2f2;'><th>Service</th><th>Cost (USD)</th></tr>"]
    
    total_cost = 0.0
    service_costs = {}
    for result in response['ResultsByTime']:
        for group in result['Groups']:
            service_name = group['Keys'][0]
            cost = float(group['Metrics']['UnblendedCost']['Amount'])
            service_costs[service_name] = service_costs.get(service_name, 0.0) + cost
            total_cost += cost

    sorted_services = sorted(service_costs.items(), key=lambda item: item[1], reverse=True)

    for service, cost in sorted_services:
        if cost > 0:
            # --- APPLY THE MAPPING ---
            # Use the dictionary's .get() method for a safe lookup.
            # If the service name isn't in our map, it uses the original name as a fallback.
            friendly_name = SERVICE_MAPPINGS.get(service, service)
            report_lines.append(f"<tr><td>{friendly_name}</td><td style='text-align:right;'>{cost:.2f}</td></tr>")
            # --- END CHANGE ---
    
    report_lines.append(f"<tr><td style='font-weight:bold;'>Total Estimated Cost</td><td style='text-align:right; font-weight:bold;'>${total_cost:.2f}</td></tr>")
    report_lines.append("</table></body></html>")
    return "".join(report_lines)

def _send_email(body, start_date, end_date):
    """Sends an email using Amazon SES."""
    # ... (this function remains unchanged) ...
    subject = f"AWS Weekly Cost Report: {start_date} to {end_date}"
    ses.send_email(Source=SENDER_EMAIL, Destination={'ToAddresses': [RECIPIENT_EMAIL]}, Message={'Subject': {'Data': subject}, 'Body': {'Html': {'Data': body}}})