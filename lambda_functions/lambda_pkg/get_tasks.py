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
        logger.info(f"Connecting to DB: {DB_HOST}, User: {DB_USER}, DB: {DB_NAME}")
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
        return None

def lambda_handler(event, context):
    """Handles GET /tasks request"""
    conn = None
    cur = None
    try:
        # ✅ Ensure all environment variables are set
        if not all([DB_HOST, DB_NAME, DB_USER, DB_PASSWORD]):
            raise ValueError("Missing database configuration in environment variables")

        # ✅ Establish Database Connection
        conn = get_db_connection()
        if conn is None:
            return {
                "statusCode": 500,
                "headers": {
                "Access-Control-Allow-Origin": "*",
                "Content-Type": "application/json"
            },
                "body": json.dumps({"error": "Database connection failed"})
            }

        cur = conn.cursor()

        # ✅ Retrieve all tasks
        cur.execute("SELECT id, description, created_at FROM tasks ORDER BY created_at DESC;")
        tasks = cur.fetchall()

        # ✅ Convert results to JSON format
        task_list = [{"id": t[0], "description": t[1], "created_at": str(t[2])} for t in tasks]

        logger.info(f"Retrieved {len(task_list)} tasks successfully.")

        return {
            "statusCode": 200,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Content-Type": "application/json"
            },
            "body": json.dumps(task_list)
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

    finally:
        # ✅ Close connections properly
        if cur is not None:
            cur.close()
        if conn is not None:
            conn.close()
