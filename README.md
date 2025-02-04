# Serverless Task Management API

## 🚀 Overview
This project sets up a **serverless task management API** using:
- **AWS Lambda** (Backend)
- **API Gateway** (API Management)
- **RDS (PostgreSQL) via RDS Proxy** (Database)
- **S3 + CloudFront** (Frontend Hosting)
- **Monitoring with Sentry, Splunk (aws kinesis) & CloudWatch dashboard**
- **CI CD Pipeline with AWS CodePipeline**

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
### Run Terraform Pipeline from AWS Console or CLI
``` sh
aws codepipeline start-pipeline-execution --name <PIPELINE_NAME>
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
- Frontend [Front Page](https://d2em6al9r5u3g1.cloudfront.net/index.html)
- CloudWatch Dashboard (API & Lambda Logs) [CloudWatch Dashboard](https://eu-central-1.console.aws.amazon.com/cloudwatch/home#dashboards:name=SRE-API-Metrics)
- Splunk Dashboard (Aggregated AWS Logs) [Splunk Dashboard](https://prd-p-gcxgi.splunkcloud.com/en-GB/app/search/search?earliest=-24h%40h&latest=now&q=search%20index%3D*&display.page.search.mode=smart&dispatch.sample_ratio=1&workload_pool=&sid=1738687772.9026)
- Sentry Dashboard (Error Monitoring) [Sentry Issues](https://comet-rocks-uc.sentry.io/issues/?project=4508747779145808&query=&referrer=issue-list&statsPeriod=14d)

