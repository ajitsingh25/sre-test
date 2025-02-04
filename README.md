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
##### Create AWS Pipeline
##### CLone Repo
``` sh
git clone https://github.com/ajitsingh25/sre-test/
cd pipeline
```
##### Initialize Terraform
``` sh
terraform init
```
##### Apply Terraform Configuration
``` sh
terraform plan -out=out.plan
terraform apply "out.plan"
```
### **OR** 
##### Create AWS Infrastructure Manually
##### Initialize Terraform
``` sh
cd infrastructure
terraform init
```
##### Apply Terraform Configuration
``` sh
terraform plan -out=out.plan
terraform apply "out.plan"
```
---

## **Testing the API**
### Test POST /tasks (Create a Task)
##### Run the following cURL command:

``` sh
api_endpoint = "https://wicxsz9iwc.execute-api.us-west-2.amazonaws.com"

api_endpoint = "wicxsz9iwc.execute-api.us-west-2.amazonaws.com"
curl -X POST https://${api_endpoint}/prod/tasks \
  -H "Content-Type: application/json" \
  -d '{"description": "Test task"}'
      
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
curl -X GET "https://${api_endpoint}/prod/tasks"
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
