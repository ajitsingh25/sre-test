import json
import os
import psycopg2
import logging

# ✅ Setup logging for better debugging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# ✅ Fetch database credentials from environment variables
DB_HOST = os.getenv("DB_HOST")
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")

def get_db_connection():
    """Establish a connection to the PostgreSQL RDS database"""
    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            connect_timeout=15,
            sslmode="require"
        )
        return conn
    except psycopg2.OperationalError as e:
        logger.error(f"Database connection failed: {e}")
        raise

def lambda_handler(event, context):
    """Handles POST /tasks request"""
    try:
        # ✅ Ensure all environment variables are set
        if not all([DB_HOST, DB_NAME, DB_USER, DB_PASSWORD]):
            raise ValueError("Missing database configuration in environment variables")

        # ✅ Ensure event body is parsed correctly
        if "body" not in event:
            return {
                "statusCode": 400,
                "headers": {
                "Access-Control-Allow-Origin": "*",
                "Content-Type": "application/json"
            },
                "body": json.dumps({"error": "Invalid request: No body found"})
            }

        body = json.loads(event["body"])
        description = body.get("description")

        if not description:
            return {
                "statusCode": 400,
                "headers": {
                "Access-Control-Allow-Origin": "*",
                "Content-Type": "application/json"
            },
                "body": json.dumps({"error": "Description is required"})
            }

        # ✅ Connect to RDS and insert task
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("INSERT INTO tasks (description) VALUES (%s) RETURNING id;", (description,))
        task_id = cur.fetchone()[0]
        conn.commit()
        cur.close()
        conn.close()

        logger.info(f"Task {task_id} created successfully.")

        return {
            "statusCode": 201,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Content-Type": "application/json"
            },
            "body": json.dumps({"message": "Task created", "task_id": task_id})
        }

    except psycopg2.OperationalError as e:
        logger.error(f"Database connection failed: {e}")
        return {
            "statusCode": 500,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Content-Type": "application/json"
            },
            "body": json.dumps({"error": "Database connection failed", "details": str(e)})
        }

    except ValueError as e:
        logger.error(f"Configuration error: {e}")
        return {
            "statusCode": 500,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Content-Type": "application/json"
            },
            "body": json.dumps({"error": "Configuration error", "details": str(e)})
        }

    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        return {
            "statusCode": 500,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Content-Type": "application/json"
            },
            "body": json.dumps({"error": "Internal Server Error", "details": str(e)})
        }
