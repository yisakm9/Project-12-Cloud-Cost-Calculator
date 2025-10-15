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
    "Amazon Elastic Compute Cloud - Compute": "EC2 (Compute)",
    "Amazon Simple Storage Service": "S3 (Storage)",
    "Amazon Relational Database Service": "RDS (Database)",
    "AWS Lambda": "Lambda (Serverless Functions)",
    "Amazon API Gateway": "API Gateway (API Management)",
    "AWS Secrets Manager": "AWS Secrets Manager",
    "AWS Cost Explorer": "AWS Cost Explorer"
}
# --- END NEW DICTIONARY ---

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