import sys
import json
import os
import pytest
import boto3
from moto import mock_aws
from unittest.mock import patch, MagicMock
from datetime import datetime

# ✅ Set environment variables BEFORE importing `get_tasks.py`
os.environ["DB_SECRET_NAME"] = "mock-db-secret"
os.environ["AWS_REGION"] = "us-east-1"
os.environ["DB_HOST"] = "localhost"
os.environ["DB_NAME"] = "test_db"
os.environ["LOG_LEVEL"] = "INFO"
os.environ["SENTRY_DSN"] = ""

# ✅ Ensure Python can find the `lambda_functions` module
sys.path.append("./lambda_functions")

# ✅ Now import get_tasks.py
from lambda_functions.get_tasks import get_db_credentials, initialize_db_pool, lambda_handler, generate_response

# ✅ Set Environment Variables for Testing
@pytest.fixture(autouse=True)
def set_env_vars():
    """Fixture to mock environment variables"""
    with patch.dict(os.environ, {
        "DB_SECRET_NAME": "mock-db-secret",
        "AWS_REGION": "us-east-1",
        "DB_HOST": "localhost",
        "DB_NAME": "test_db",
        "LOG_LEVEL": "INFO",  # ✅ Ensure LOG_LEVEL is set
        "SENTRY_DSN": ""
    }):
        yield


# ✅ Mock AWS Secrets Manager
@mock_aws
def test_get_db_credentials():
    """Test fetching database credentials from AWS Secrets Manager."""
    
    # ✅ Create a mock Secrets Manager client
    client = boto3.client("secretsmanager", region_name="us-east-1")

    # ✅ Mock secret value
    secret_name = "mock-db-secret"
    secret_value = json.dumps({"username": "test_user", "password": "test_pass"})
    client.create_secret(Name=secret_name, SecretString=secret_value)

    # ✅ Patch environment variable
    with patch.dict(os.environ, {"DB_SECRET_NAME": secret_name, "AWS_REGION": "us-east-1"}):
        username, password = get_db_credentials()

    # ✅ Assert values are correctly retrieved
    assert username == "test_user"
    assert password == "test_pass"

# ✅ Mock Database Connection
@patch("lambda_functions.get_tasks.psycopg2.pool.SimpleConnectionPool")
@patch("lambda_functions.get_tasks.get_db_credentials", return_value=("test_user", "test_pass"))
def test_initialize_db_pool(mock_get_db_credentials, mock_conn_pool):
    """Test database connection pool initialization."""

    # ✅ Mock the connection pool
    mock_conn_pool.return_value = MagicMock()

    # ✅ Call the function (now it uses the mocked `get_db_credentials`)
    initialize_db_pool()

    # ✅ Ensure get_db_credentials was called once
    mock_get_db_credentials.assert_called_once()

    # ✅ Assert that the connection pool was initialized
    mock_conn_pool.assert_called_once_with(
        minconn=1,
        maxconn=10,
        host=os.getenv("DB_HOST"),
        dbname=os.getenv("DB_NAME"),
        user="test_user",
        password="test_pass",
        connect_timeout=10,
        sslmode="require"
    )


# ✅ Test Lambda Handler with a Mocked Database Response
@patch("lambda_functions.get_tasks.get_db_connection")
@patch("lambda_functions.get_tasks.return_db_connection")
@patch("sentry_sdk.init")  # ✅ Mock Sentry to avoid log issues
def test_lambda_handler(mock_sentry, mock_return_db, mock_get_db):
    """Test Lambda handler logic with Sentry mocked."""

    # ✅ Create a fake database response with `datetime` objects
    mock_cursor = MagicMock()
    mock_cursor.fetchall.return_value = [
        (1, "Test Task 1", datetime(2025, 2, 4, 12, 0, 0)),  # ✅ Use datetime object
        (2, "Test Task 2", datetime(2025, 2, 4, 12, 30, 0))  # ✅ Use datetime object
    ]

    mock_conn = MagicMock()
    mock_conn.cursor.return_value.__enter__.return_value = mock_cursor
    mock_get_db.return_value = mock_conn

    # ✅ Call Lambda function
    response = lambda_handler({}, {})

    # ✅ Expected response
    expected_body = json.dumps([
        {"id": 1, "description": "Test Task 1", "created_at": "2025-02-04T12:00:00"},
        {"id": 2, "description": "Test Task 2", "created_at": "2025-02-04T12:30:00"}
    ])

    assert response["statusCode"] == 200
    assert response["body"] == expected_body
    
def test_lambda_handler_missing_env():
    """Test Lambda handler when environment variables are missing."""

    with patch.dict(os.environ, {}, clear=True):  # ✅ Remove all environment variables
        response = lambda_handler({}, {})

    assert response["statusCode"] == 400
    assert "Missing environment variables" in response["body"]

# ✅ Test Generate Response Helper Function
def test_generate_response():
    """Test the generate_response function."""
    
    response = generate_response(200, {"message": "Success"})
    
    assert response["statusCode"] == 200
    assert response["headers"]["Access-Control-Allow-Origin"] == "*"
    assert json.loads(response["body"]) == {"message": "Success"}
