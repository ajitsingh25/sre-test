import json
from tasks import lambda_handler

def test_get_tasks():
    event = {"httpMethod": "GET"}
    response = lambda_handler(event, None)
    assert response["statusCode"] == 200

def test_post_task():
    event = {
        "httpMethod": "POST",
        "body": json.dumps({"description": "Test Task"})
    }
    response = lambda_handler(event, None)
    assert response["statusCode"] == 201
