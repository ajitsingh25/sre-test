import json
import os
import psycopg2
import psycopg2.pool
import logging
import threading
import sentry_sdk
from sentry_sdk.integrations.aws_lambda import AwsLambdaIntegration
import boto3
from botocore.exceptions import ClientError
import time
import socket
from sentry_sdk import set_level

set_level("warning")

# ✅ Initialize Sentry
SENTRY_DSN = os.getenv("SENTRY_DSN")  # Fetch from environment variable
sentry_sdk.init(
    dsn=SENTRY_DSN,
    max_breadcrumbs=50,
    debug=True,
    enable_tracing=True,
    # Add data like request headers and IP for users, if applicable;
    # see https://docs.sentry.io/platforms/python/data-management/data-collected/ for more info
    send_default_pii=True,
    # Set traces_sample_rate to 1.0 to capture 100%
    # of transactions for tracing.
    traces_sample_rate=1.0,
    # Set profiles_sample_rate to 1.0 to profile 100%
    # of sampled transactions.
    # We recommend adjusting this value in production.
    profiles_sample_rate=1.0,
    integrations=[
        AwsLambdaIntegration(timeout_warning=True),
    ],
)

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Database credentials from environment variables
DB_HOST = os.getenv("DB_HOST")
DB_NAME = os.getenv("DB_NAME")
DB_SECRET_NAME = os.getenv("DB_SECRET_NAME")  # ✅ Fetch secret name from environment variables

# Connection pool and pool lock
DB_POOL = None
POOL_LOCK = threading.Lock()

# Thread-local storage for connections
CONNECTION_LOCAL = threading.local()
SCHEMA_INITIALIZED = False  # Tracks if schema was initialized

def get_db_credentials():
    """Fetches database credentials (username, password)
    from AWS Secrets Manager using Secret Name."""
    if not DB_SECRET_NAME:
        raise ValueError("❌ Missing DB_SECRET_NAME environment variable")

    session = boto3.session.Session()
    client = session.client(service_name="secretsmanager", region_name="eu-central-1")

    try:
        logger.info(f"🔍 Fetching DB credentials from Secrets Manager: {DB_SECRET_NAME}")
        response = client.get_secret_value(SecretId=DB_SECRET_NAME)

        secret = json.loads(response["SecretString"])
        username = secret.get("username")
        password = secret.get("password")

        if not username or not password:
            raise ValueError("❌ Retrieved secret is missing username or password")

        logger.info(f"✅ Successfully retrieved credentials. Username = {username}")
        return username, password
    except ClientError as e:
        sentry_sdk.capture_exception(e)  # ✅ Send error to Sentry
        logger.error(f"❌ Failed to retrieve database credentials: {e}")
        raise

def initialize_db_pool():
    """Initializes the connection pool (thread-safe)."""
    global DB_POOL
    with POOL_LOCK:
        if DB_POOL is None:
            try:
                db_user, db_password = get_db_credentials()  # ✅ Fetch credentials dynamically
                logger.info("✅ Credentials retrieved. Attempting to create DB pool.")

                DB_POOL = psycopg2.pool.SimpleConnectionPool(
                    minconn=1,
                    maxconn=10,
                    host=DB_HOST,
                    dbname=DB_NAME,
                    user=db_user,
                    password=db_password,
                    connect_timeout=10,
                    sslmode="require"
                )

                logger.info("✅ Database connection pool initialized.")
            except psycopg2.Error as e:
                sentry_sdk.capture_exception(e)  # ✅ Send error to Sentry
                logger.error(f"❌ Failed to initialize connection pool: {e}")
                raise

def get_db_connection(retries=3, delay=2):
    """Retrieves a connection from the pool with retries (thread-safe)."""
    global DB_POOL
    if DB_POOL is None:
        initialize_db_pool()

    for attempt in range(1, retries + 1):
        try:
            logger.info(f"🔍 Attempting to get DB connection (Attempt {attempt})...")
            conn = DB_POOL.getconn()
            with conn.cursor() as cur:
                cur.execute("SELECT 1")  # ✅ Validate connection before using
            logger.info("✅ Successfully acquired DB connection.")
            return conn
        except psycopg2.OperationalError as e:
            logger.error(f"❌ Database connection attempt {attempt} failed: {e}")
            time.sleep(delay)  # ✅ Implement retry delay
        except Exception as e:
            sentry_sdk.capture_exception(e)  # ✅ Send error to Sentry
            logger.error(f"❌ Unexpected connection error: {e}")

    raise Exception("❌ Unable to establish a database connection after retries.")

def return_db_connection(conn):
    """Returns a connection to the pool (thread-safe)."""
    global DB_POOL
    if DB_POOL and conn:
        try:
            DB_POOL.putconn(conn)
            if hasattr(CONNECTION_LOCAL, "conn") and CONNECTION_LOCAL.conn is conn:
                delattr(CONNECTION_LOCAL, "conn")  # ✅ Remove from thread-local
        except psycopg2.Error as e:
            sentry_sdk.capture_exception(e)  # ✅ Send error to Sentry
            logger.error(f"❌ Error returning connection: {e}")

def initialize_database():
    """Initializes the database schema (creates tables if needed, runs only once per cold start)."""
    global SCHEMA_INITIALIZED
    if SCHEMA_INITIALIZED:
        return

    conn = None
    cur = None
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS tasks (
                id SERIAL PRIMARY KEY,
                description TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)
        conn.commit()
        SCHEMA_INITIALIZED = True
        logger.info("✅ Database schema initialized.")
    except psycopg2.Error as e:
        sentry_sdk.capture_exception(e)  # ✅ Send error to Sentry
        logger.error(f"❌ Failed to initialize database schema: {e}")
    finally:
        if cur:
            cur.close()
        if conn:
            return_db_connection(conn)  # ✅ Ensure connection is returned to pool

def lambda_handler(event, context):
    """Handles POST /tasks request."""
    logger.info("🔍 Lambda function started. Checking required environment variables.")

    sentry_sdk.set_context("Lambda Execution", {"event": event})  # ✅ Attach event context for debugging

    conn = None
    cur = None  # ✅ Ensure cur is always initialized

    try:
        # ✅ Ensure environment variables are set
        required_vars = ["DB_HOST", "DB_NAME", "DB_SECRET_NAME"]
        if not all(os.getenv(var) for var in required_vars):
            raise ValueError(f"❌ Missing environment variables: {required_vars}")

        initialize_database()  # ✅ Initialize schema only once per cold start

        # ✅ Validate request body
        if "body" not in event or not event["body"]:
            return generate_response(400, {"error": "Missing request body."})

        try:
            body = json.loads(event["body"])
        except json.JSONDecodeError:
            return generate_response(400, {"error": "Invalid JSON in request body."})

        description = body.get("description", "").strip()
        if not description:
            return generate_response(400, {"error": "Description is required."})

        # ✅ Get a database connection
        conn = get_db_connection()
        cur = conn.cursor()

        # ✅ Insert new task
        cur.execute("INSERT INTO tasks (description) VALUES (%s) RETURNING id", (description,))
        task_id = cur.fetchone()[0]
        conn.commit()

        logger.info(f"✅ Task created with ID: {task_id}")
        return generate_response(201, {"message": "Task created.", "task_id": task_id})

    except ValueError as e:
        sentry_sdk.capture_exception(e)  # ✅ Send error to Sentry
        logger.error(f"❌ Value Error: {e}")
        return generate_response(400, {"error": str(e)})

    except psycopg2.Error as e:
        sentry_sdk.capture_exception(e)  # ✅ Send error to Sentry
        logger.error(f"❌ Database Error: {e}")
        return generate_response(500, {"error": "Database error.", "details": str(e)})

    except Exception as e:
        sentry_sdk.capture_exception(e)  # ✅ Send error to Sentry
        logger.exception("❌ Unexpected error:")
        return generate_response(500, {"error": "Internal Server Error."})

    finally:
        if cur:
            cur.close()
        if conn:
            return_db_connection(conn)  # ✅ Always return connection to the pool

def generate_response(status_code, body):
    """Generates API Gateway response with CORS."""
    return {
        "statusCode": status_code,
        "headers": {
            "Access-Control-Allow-Origin": "*",  # Customize for production
            "Access-Control-Allow-Methods": "POST, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type",
            "Content-Type": "application/json"
        },
        "body": json.dumps(body)
    }
