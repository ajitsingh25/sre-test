# Serverless Task Management API

## 🚀 Overview
This project sets up a **serverless task management API** using:
- **AWS Lambda** (Backend)
- **API Gateway** (API Management)
- **RDS (PostgreSQL) via RDS Proxy** (Database)
- **S3 + CloudFront** (Frontend Hosting)
- **Monitoring with Sentry, Splunk & CloudWatch**

---

## **Setup Instructions**
### **Prerequisites**
- Install **Terraform**: [Terraform Install Guide](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- Install **AWS CLI**: [AWS CLI Install Guide](https://aws.amazon.com/cli/)
- Configure AWS credentials:
  ```sh
    aws configure
  ```

---
###  **Deploy the Infrastructure**

#### Clone the Repository
``` sh
git clone <repo-url>
cd <repo-folder>
```
### Initialize Terraform
``` sh
terraform init
```
### Apply Terraform Configuration
``` sh
terraform apply
```
---

## **Testing the API**
### Test POST /tasks (Create a Task)
##### Run the following cURL command:
``` sh
curl -X POST "https://vo8nww9fy3.execute-api.eu-central-1.amazonaws.com/prod/tasks" \
     -H "Content-Type: application/json" \
     -d '{"description": "Buy groceries"}'
```
#### Expected Response:
``` json
{
  "message": "Task created.",
  "task_id": 123
}
```
###  Test GET /tasks (Fetch All Tasks)
##### Run the following cURL command:
``` sh
curl -X GET "https://vo8nww9fy3.execute-api.eu-central-1.amazonaws.com/prod/tasks"
```
#### Expected Response:
``` json
[
  {
    "id": 1,
    "description": "Buy groceries",
    "created_at": "2025-02-02T10:00:00"
  }
]
```
---
## *Observability Dashboards*
### Use these links to monitor logs & errors:

- CloudWatch Dashboard (API & Lambda Logs) [CloudWatch Dashboard]()
- Splunk Dashboard (Aggregated AWS Logs) [Splunk Dashboard]()
- Sentry Dashboard (Error Monitoring) [Sentry Issues]()

---

## *Resources*
- AWS Lambda Documentation: [AWS Lambda]()
- Terraform AWS Provider: [Terraform AWS]()
- Splunk Docs: [Splunk for AWS]()
- Sentry Docs: [Sentry for AWS Lambda]()
