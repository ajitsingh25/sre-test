import json
import boto3
import base64

# Your secret's name and region
secret_name = "rds!db-44362882-803c-49e3-9823-aa2975fcd8cf"
region_name = "eu-central-1"

#Set up our Session and Client
session = boto3.session.Session()
client = session.client(
    service_name='secretsmanager',
    region_name=region_name
)

# def lambda_handler(event, context):

# Calling SecretsManager
get_secret_value_response = client.get_secret_value(
    SecretId=secret_name
)

#Raw Response
print(get_secret_value_response)

#Extracting the key/value from the secret
secret = get_secret_value_response['SecretString']
print(secret)
