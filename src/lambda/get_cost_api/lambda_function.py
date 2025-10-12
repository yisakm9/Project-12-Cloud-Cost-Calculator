# src/lambda/get_cost_api/lambda_function.py

import boto3
import json
from datetime import datetime, timedelta

# Initialize AWS Cost Explorer client
cost_explorer = boto3.client('ce', region_name='us-east-1')

def lambda_handler(event, context):
    """
    API Gateway handler to fetch the AWS cost report for the last 7 days
    and return it as a JSON response with CORS headers.
    """
    end_date = datetime.now()
    start_date = end_date - timedelta(days=7)
    
    start_str = start_date.strftime('%Y-%m-%d')
    end_str = end_date.strftime('%Y-%m-%d')

    try:
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

        # Process the response into a structured dictionary
        payload = _process_cost_data(response, start_str, end_str)

        return {
            'statusCode': 200,
            'headers': {
                # Required for CORS
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'GET'
            },
            'body': json.dumps(payload)
        }

    except Exception as e:
        print(f"An error occurred: {e}")
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': f'Failed to retrieve cost data: {str(e)}'})
        }

def _process_cost_data(response, start_date, end_date):
    """Formats the Cost Explorer response into a clean dictionary."""
    
    total_cost = 0.0
    service_costs = {}
    
    for result in response['ResultsByTime']:
        for group in result['Groups']:
            service_name = group['Keys'][0]
            cost = float(group['Metrics']['UnblendedCost']['Amount'])
            
            # Aggregate costs over the period
            service_costs[service_name] = service_costs.get(service_name, 0.0) + cost
            total_cost += cost

    # Sort services by cost in descending order
    sorted_services = sorted(service_costs.items(), key=lambda item: item[1], reverse=True)
    
    # Filter out services with zero cost
    services_with_cost = [{'service': service, 'cost': round(cost, 2)} for service, cost in sorted_services if cost > 0]

    return {
        'reportingPeriod': {
            'start': start_date,
            'end': end_date
        },
        'totalCost': round(total_cost, 2),
        'costsByService': services_with_cost
    }