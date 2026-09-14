---
name: aws-infra
description: 'Read-only AWS infrastructure discovery using AWS CLI. Triggers on "list instances", "show buckets", "describe vpc", "what''s in this account", "check IAM roles", or any AWS resource lookup. Supports multi-account via --profile.'
---

# AWS Infrastructure Skill (Read-Only)

Discover AWS resources using the native AWS CLI. Designed for multi-account environments with SSO.

## NEVER RUN THESE COMMANDS

The following patterns are **FORBIDDEN** - never execute them:

| Pattern | Reason |
|---------|--------|
| `aws * delete*` | Deletes resources |
| `aws * remove*` | Removes resources |
| `aws * terminate*` | Terminates instances |
| `aws * put*` | Writes/overwrites data |
| `aws * create*` | Creates resources |
| `aws * update*` | Updates resources |
| `aws * modify*` | Modifies resources |
| `aws * start-instances` | Starts EC2 instances |
| `aws * stop-instances` | Stops EC2 instances |
| `aws * reboot*` | Reboots instances |
| `aws s3 rm` | Deletes S3 objects |
| `aws s3 mv` | Moves S3 objects |
| `aws s3 cp` (to S3) | Writes to S3 |
| `aws s3 sync` (to S3) | Syncs to S3 |
| `aws iam attach*` | Attaches policies |
| `aws iam detach*` | Detaches policies |
| `aws iam add*` | Adds IAM resources |
| `aws iam delete*` | Deletes IAM resources |
| `aws iam put*` | Writes IAM policies |

## SAFE READ-ONLY COMMANDS

These patterns are safe to run:

| Pattern | Use |
|---------|-----|
| `aws * describe*` | Describe resources |
| `aws * list*` | List resources |
| `aws * get*` | Get resource details |
| `aws s3 ls` | List S3 contents |
| `aws s3api head-*` | Get S3 object metadata |
| `aws s3api get-*` | Get S3 bucket/object info |
| `aws sts get-caller-identity` | Check current identity |
| `aws logs filter-log-events` | Query logs |
| `aws logs start-query` | CloudWatch Insights |
| `aws logs get-query-results` | Get Insights results |

## Multi-Account Usage

### List Available Profiles
```bash
grep '^\[profile' ~/.aws/config | sed 's/\[profile //' | sed 's/\]//'
```

### Switch Accounts
Always use `--profile` to target a specific account:
```bash
aws --profile reman-dev.RemanAdmin_775255424688 s3 ls
aws --profile ics-vision-prod.ICSAdmin_158134245097 ec2 describe-instances
```

### Check Current Identity
```bash
aws sts get-caller-identity
aws --profile <profile-name> sts get-caller-identity
```

### Login if Session Expired
```bash
aws sso login
# Or for specific profile:
aws sso login --profile <profile-name>
```

## Common Query Patterns

### EC2 Instances
```bash
# List all instances with name and state
aws ec2 describe-instances \
  --query 'Reservations[].Instances[].[InstanceId,State.Name,Tags[?Key==`Name`].Value|[0]]' \
  --output table

# Running instances only
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].[InstanceId,InstanceType,Tags[?Key==`Name`].Value|[0]]' \
  --output table

# Find by tag
aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=production" \
  --output table
```

### S3 Buckets
```bash
# List all buckets
aws s3 ls

# List bucket contents
aws s3 ls s3://bucket-name/ --recursive --summarize

# Get bucket location
aws s3api get-bucket-location --bucket bucket-name

# Check if bucket is public
aws s3api get-public-access-block --bucket bucket-name

# Get bucket policy
aws s3api get-bucket-policy --bucket bucket-name
```

### Lambda Functions
```bash
# List functions
aws lambda list-functions \
  --query 'Functions[].[FunctionName,Runtime,LastModified]' \
  --output table

# Get function details
aws lambda get-function --function-name my-function

# Get function configuration
aws lambda get-function-configuration --function-name my-function
```

### IAM Roles & Policies
```bash
# List roles
aws iam list-roles \
  --query 'Roles[].[RoleName,CreateDate]' \
  --output table

# Get role details
aws iam get-role --role-name my-role

# List attached policies for a role
aws iam list-attached-role-policies --role-name my-role

# Get inline policy
aws iam get-role-policy --role-name my-role --policy-name my-policy

# List users
aws iam list-users \
  --query 'Users[].[UserName,CreateDate]' \
  --output table

# List access keys for a user
aws iam list-access-keys --user-name my-user
```

### Security Groups
```bash
# List security groups
aws ec2 describe-security-groups \
  --query 'SecurityGroups[].[GroupId,GroupName,VpcId]' \
  --output table

# Find groups with 0.0.0.0/0 ingress (public access)
aws ec2 describe-security-groups \
  --filters "Name=ip-permission.cidr,Values=0.0.0.0/0" \
  --query 'SecurityGroups[].[GroupId,GroupName]' \
  --output table

# Get specific security group rules
aws ec2 describe-security-group-rules \
  --filters "Name=group-id,Values=sg-xxx"
```

### VPC
```bash
# List VPCs
aws ec2 describe-vpcs \
  --query 'Vpcs[].[VpcId,CidrBlock,Tags[?Key==`Name`].Value|[0]]' \
  --output table

# List subnets
aws ec2 describe-subnets \
  --query 'Subnets[].[SubnetId,VpcId,CidrBlock,AvailabilityZone]' \
  --output table

# List route tables
aws ec2 describe-route-tables \
  --query 'RouteTables[].[RouteTableId,VpcId]' \
  --output table
```

### EKS
```bash
# List clusters
aws eks list-clusters

# Describe cluster
aws eks describe-cluster --name my-cluster

# List nodegroups
aws eks list-nodegroups --cluster-name my-cluster

# Describe nodegroup
aws eks describe-nodegroup --cluster-name my-cluster --nodegroup-name my-ng
```

### RDS
```bash
# List databases
aws rds describe-db-instances \
  --query 'DBInstances[].[DBInstanceIdentifier,DBInstanceClass,Engine,DBInstanceStatus]' \
  --output table

# Get database details
aws rds describe-db-instances --db-instance-identifier my-db
```

### CloudWatch Logs
```bash
# List log groups
aws logs describe-log-groups \
  --query 'logGroups[].[logGroupName,storedBytes]' \
  --output table

# Query logs (last hour)
aws logs filter-log-events \
  --log-group-name /aws/lambda/my-function \
  --start-time $(( $(date +%s) - 3600 ))000 \
  --filter-pattern "ERROR"

# CloudWatch Insights query
aws logs start-query \
  --log-group-name /aws/lambda/my-function \
  --start-time $(( $(date +%s) - 3600 )) \
  --end-time $(date +%s) \
  --query-string 'fields @timestamp, @message | filter @message like /ERROR/'
```

### Secrets Manager
```bash
# List secrets (metadata only - does NOT reveal values)
aws secretsmanager list-secrets \
  --query 'SecretList[].[Name,LastChangedDate]' \
  --output table

# Describe secret (metadata only)
aws secretsmanager describe-secret --secret-id my-secret

# NOTE: get-secret-value is read-only but reveals secret values
# Only use when explicitly needed
```

### ECS
```bash
# List clusters
aws ecs list-clusters

# Describe cluster
aws ecs describe-clusters --clusters my-cluster

# List services in cluster
aws ecs list-services --cluster my-cluster

# List tasks in cluster
aws ecs list-tasks --cluster my-cluster
```

### Load Balancers
```bash
# List ALBs/NLBs
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[].[LoadBalancerName,Type,State.Code]' \
  --output table

# List target groups
aws elbv2 describe-target-groups \
  --query 'TargetGroups[].[TargetGroupName,Protocol,Port]' \
  --output table
```

## Output Formats

```bash
# Table (human readable)
aws ec2 describe-instances --output table

# JSON (for parsing with jq)
aws ec2 describe-instances --output json

# Text (simple, tab-separated)
aws ec2 describe-instances --output text

# YAML
aws ec2 describe-instances --output yaml
```

## JQ Patterns for JSON Parsing

```bash
# Extract specific fields
aws ec2 describe-instances --output json | \
  jq '.Reservations[].Instances[] | {id: .InstanceId, state: .State.Name}'

# Filter by condition
aws ec2 describe-instances --output json | \
  jq '.Reservations[].Instances[] | select(.State.Name == "running")'

# Count resources
aws s3api list-buckets --output json | jq '.Buckets | length'

# Get tag value
aws ec2 describe-instances --output json | \
  jq '.Reservations[].Instances[] | {id: .InstanceId, name: (.Tags // [] | map(select(.Key == "Name")) | .[0].Value // "unnamed")}'

# Filter and format
aws lambda list-functions --output json | \
  jq -r '.Functions[] | [.FunctionName, .Runtime, .MemorySize] | @tsv'
```

## Region Handling

```bash
# Query specific region
aws ec2 describe-instances --region us-west-2

# Query all regions (loop)
for region in $(aws ec2 describe-regions --query 'Regions[].RegionName' --output text); do
  echo "=== $region ==="
  aws ec2 describe-instances --region $region --query 'Reservations[].Instances[].InstanceId' --output text
done
```

## Tips

- Always use `--profile` for multi-account work
- Use `--query` to filter results server-side (faster, less data transfer)
- Use `--output table` for human-readable output
- Use `--output json | jq` for scripting and complex filtering
- Use `--region` to target specific regions
- Run `aws sso login` if you get credential errors
- Combine `--query` with `--output table` for clean reports
- Use `--no-paginate` carefully - can return huge results
