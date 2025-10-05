# src/lambda/get_cost_report/lambda_function.py

import boto3
import os
from datetime import datetime, timedelta

cost_explorer = boto3.client('ce', region_name='us-east-1')
ses = boto3.client('ses', region_name='us-east-1') # Ensure SES client is also in us-east-1

SENDER_EMAIL = os.environ.get('SENDER_EMAIL')
RECIPIENT_EMAIL = os.environ.get('RECIPIENT_EMAIL')

def lambda_handler(event, context):
    if not SENDER_EMAIL or not RECIPIENT_EMAIL:
        print("Error: SENDER_EMAIL and RECIPIENT_EMAIL environment variables must be set.")
        return {'statusCode': 400, 'body': 'Environment variables not set.'}

    end_date = datetime.now()
    start_date = end_date - timedelta(days=7)
    start_str = start_date.strftime('%Y-%m-%d')
    end_str = end_date.strftime('%Y-%m-%d')

    try:
        response = cost_explorer.get_cost_and_usage(
            TimePeriod={'Start': start_str, 'End': end_str},
            Granularity='DAILY',
            Metrics=['UnblendedCost'],
            GroupBy=[{'Type': 'DIMENSION', 'Key': 'SERVICE'}]
        )
        email_body = _create_email_body(response, start_str, end_str)
        _send_email(email_body, start_str, end_str)
        return {'statusCode': 200, 'body': 'Cost report email sent successfully!'}
    except Exception as e:
        print(f"An error occurred: {e}")
        # Optionally send an error email
        _send_error_email(str(e))
        return {'statusCode': 500, 'body': f'Error: {str(e)}'}

def _create_email_body(response, start_date, end_date):
    report_lines = [
        "<html><body>",
        "<h2>AWS Cost Report Summary</h2>",
        f"<p><b>Reporting Period:</b> {start_date} to {end_date}</p>",
        "<table border='1' cellpadding='5' cellspacing='0'>",
        "<tr style='background-color:#f2f2f2;'><th>Service</th><th>Cost (USD)</th></tr>"
    ]
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
            report_lines.append(f"<tr><td>{service}</td><td style='text-align:right;'>{cost:.2f}</td></tr>")
    
    report_lines.append(f"<tr><td style='font-weight:bold;'>Total Estimated Cost</td><td style='text-align:right; font-weight:bold;'>${total_cost:.2f}</td></tr>")
    report_lines.append("</table></body></html>")
    return "".join(report_lines)

def _send_email(body, start_date, end_date):
    subject = f"AWS Weekly Cost Report: {start_date} to {end_date}"
    ses.send_email(
        Source=SENDER_EMAIL,
        Destination={'ToAddresses': [RECIPIENT_EMAIL]},
        Message={'Subject': {'Data': subject}, 'Body': {'Html': {'Data': body}}}
    )
    
def _send_error_email(error_message):
    """Sends a notification if the function fails."""
    subject = "Error: AWS Cost Report Lambda Failed"
    body = f"The cost report Lambda function failed with the following error:\n\n{error_message}"
    try:
        ses.send_email(
            Source=SENDER_EMAIL,
            Destination={'ToAddresses': [RECIPIENT_EMAIL]},
            Message={'Subject': {'Data': subject}, 'Body': {'Text': {'Data': body}}}
        )
    except Exception as e:
        print(f"Failed to send error email: {e}")