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

def lambda_handler(event, context):
    """
    This function fetches the AWS cost and usage report for the last 7 days
    and sends a summary email using SES.
    """
    if not SENDER_EMAIL or not RECIPIENT_EMAIL:
        return {
            'statusCode': 400,
            'body': 'Error: SENDER_EMAIL and RECIPIENT_EMAIL environment variables must be set.'
        }

    # Define the time period for the cost report
    end_date = datetime.now()
    start_date = end_date - timedelta(days=7)
    
    start_str = start_date.strftime('%Y-%m-%d')
    end_str = end_date.strftime('%Y-%m-%d')

    try:
        # Get cost and usage data from AWS Cost Explorer
        response = cost_explorer.get_cost_and_usage(
            TimePeriod={
                'Start': start_str,
                'End': end_str
            },
            Granularity='DAILY',
            Metrics=['UnblendedCost'],
            GroupBy=[
                {
                    'Type': 'DIMENSION',
                    'Key': 'SERVICE'
                }
            ]
        )

        # Process the response to create an email body
        email_body = _create_email_body(response, start_str, end_str)
        
        # Send the email report using SES
        _send_email(email_body, start_str, end_str)

        return {
            'statusCode': 200,
            'body': 'Cost report email sent successfully!'
        }

    except Exception as e:
        print(f"An error occurred: {e}")
        return {
            'statusCode': 500,
            'body': f'Error generating or sending cost report: {str(e)}'
        }

def _create_email_body(response, start_date, end_date):
    """Formats the Cost Explorer response into an HTML email body."""
    
    report_lines = ["<h2>AWS Cost Report Summary</h2>",
                    f"<p><b>Reporting Period:</b> {start_date} to {end_date}</p>",
                    "<table border='1'><tr><th>Service</th><th>Cost (USD)</th></tr>"]
    
    total_cost = 0.0
    
    # Aggregate costs by service
    service_costs = {}
    for result in response['ResultsByTime']:
        for group in result['Groups']:
            service_name = group['Keys'][0]
            cost = float(group['Metrics']['UnblendedCost']['Amount'])
            if service_name in service_costs:
                service_costs[service_name] += cost
            else:
                service_costs[service_name] = cost
            total_cost += cost

    # Sort services by cost in descending order
    sorted_services = sorted(service_costs.items(), key=lambda item: item[1], reverse=True)

    for service, cost in sorted_services:
        if cost > 0: # Only include services with a cost
            report_lines.append(f"<tr><td>{service}</td><td>{cost:.2f}</td></tr>")
    
    report_lines.append("</table>")
    report_lines.append(f"<p><b>Total Estimated Cost: ${total_cost:.2f}</b></p>")
    
    return "".join(report_lines)

def _send_email(body, start_date, end_date):
    """Sends an email using Amazon SES."""
    
    subject = f"AWS Weekly Cost Report: {start_date} to {end_date}"
    
    ses.send_email(
        Source=SENDER_EMAIL,
        Destination={'ToAddresses': [RECIPIENT_EMAIL]},
        Message={
            'Subject': {'Data': subject},
            'Body': {'Html': {'Data': body}}
        }
    )