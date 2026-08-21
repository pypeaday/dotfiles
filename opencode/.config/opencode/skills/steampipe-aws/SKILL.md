---
name: steampipe-aws
description: 'Query AWS infrastructure using steampipe SQL. Triggers on "what resources", "find instances", "list buckets", "show IAM", "audit AWS", "security groups", or any AWS resource discovery task.'
---

# Steampipe AWS Skill

Query AWS infrastructure using SQL via steampipe CLI.

## When to Use Steampipe vs AWS CLI

| Use Steampipe When | Use AWS CLI (`aws-infra` skill) When |
|--------------------|--------------------------------------|
| Cross-resource joins (EC2 + SGs + VPCs) | Single-resource inspection |
| Bulk audit (all unencrypted volumes) | One-off checks (`describe-instances`) |
| Complex filtering with SQL | Simple `--query` JMESPath filters |
| Security compliance scans | Script automation |
| Multi-table analysis | When steampipe isn't installed |

**Rule of thumb:** If you'd write a `for` loop with `aws` CLI, use steampipe instead.

## When to Use

- Discover AWS resources across accounts
- Audit security configurations
- Find resources by tags, regions, or properties
- Investigate IAM policies and permissions
- Check compliance and security posture
- Troubleshoot infrastructure issues

## How to Query

```bash
steampipe query "SELECT * FROM aws_s3_bucket LIMIT 5"
steampipe query --output json "SELECT name, region FROM aws_ec2_instance"
steampipe query --output csv "SELECT * FROM aws_iam_role"
```

## Common Tables

### Compute
| Table | Description |
|-------|-------------|
| `aws_ec2_instance` | EC2 instances |
| `aws_lambda_function` | Lambda functions |
| `aws_ecs_cluster` | ECS clusters |
| `aws_ecs_service` | ECS services |
| `aws_eks_cluster` | EKS clusters |

### Storage
| Table | Description |
|-------|-------------|
| `aws_s3_bucket` | S3 buckets |
| `aws_ebs_volume` | EBS volumes |
| `aws_rds_db_instance` | RDS databases |
| `aws_dynamodb_table` | DynamoDB tables |

### Networking
| Table | Description |
|-------|-------------|
| `aws_vpc` | VPCs |
| `aws_vpc_subnet` | Subnets |
| `aws_vpc_security_group` | Security groups |
| `aws_vpc_security_group_rule` | SG rules |
| `aws_route53_zone` | Route53 zones |
| `aws_elb_load_balancer` | Classic ELBs |
| `aws_elbv2_load_balancer` | ALB/NLB |

### IAM & Security
| Table | Description |
|-------|-------------|
| `aws_iam_user` | IAM users |
| `aws_iam_role` | IAM roles |
| `aws_iam_policy` | IAM policies |
| `aws_iam_access_key` | Access keys |
| `aws_kms_key` | KMS keys |
| `aws_secretsmanager_secret` | Secrets Manager |

### Monitoring
| Table | Description |
|-------|-------------|
| `aws_cloudwatch_alarm` | CloudWatch alarms |
| `aws_cloudwatch_log_group` | Log groups |
| `aws_cloudtrail_trail` | CloudTrail trails |

## Query Patterns

### Find Public Resources
```sql
-- Public S3 buckets
SELECT name, region, bucket_policy_is_public
FROM aws_s3_bucket
WHERE bucket_policy_is_public = true;

-- Public security group rules
SELECT group_id, type, ip_protocol, from_port, to_port, cidr_ipv4
FROM aws_vpc_security_group_rule
WHERE cidr_ipv4 = '0.0.0.0/0';
```

### Find by Tags
```sql
-- EC2 instances by tag
SELECT instance_id, tags ->> 'Name' as name, instance_state
FROM aws_ec2_instance
WHERE tags ->> 'Environment' = 'production';

-- Resources missing required tags
SELECT instance_id, tags
FROM aws_ec2_instance
WHERE tags ->> 'Owner' IS NULL;
```

### IAM Analysis
```sql
-- Roles with admin access
SELECT name, assume_role_policy_std
FROM aws_iam_role
WHERE attached_policy_arns @> '["arn:aws:iam::aws:policy/AdministratorAccess"]';

-- Old access keys
SELECT user_name, access_key_id, create_date, status
FROM aws_iam_access_key
WHERE create_date < now() - interval '90 days';
```

### Cross-Resource Joins
```sql
-- EC2 instances with their security groups
SELECT 
  i.instance_id,
  i.tags ->> 'Name' as name,
  sg.group_name
FROM aws_ec2_instance i
JOIN aws_vpc_security_group sg 
  ON sg.group_id = ANY(i.security_groups);
```

### Cost-Related
```sql
-- Large EC2 instances
SELECT instance_id, instance_type, tags ->> 'Name' as name
FROM aws_ec2_instance
WHERE instance_type LIKE '%.xlarge%' OR instance_type LIKE '%.2xlarge%';

-- Unattached EBS volumes
SELECT volume_id, size, create_time
FROM aws_ebs_volume
WHERE jsonb_array_length(attachments) = 0;
```

## Output Formats

```bash
# Table (default, human-readable)
steampipe query "SELECT name FROM aws_s3_bucket"

# JSON (for parsing)
steampipe query --output json "SELECT name FROM aws_s3_bucket"

# CSV (for export)
steampipe query --output csv "SELECT name FROM aws_s3_bucket"

# Line (key=value)
steampipe query --output line "SELECT name FROM aws_s3_bucket"
```

## Tips

- Use `LIMIT` to avoid huge result sets
- Use `--output json` when you need to parse results
- Filter by `region` if you only care about specific regions
- Use `->> ` for JSONB tag access
- Tables are named `aws_{service}_{resource}`
- Run `steampipe plugin install aws` if plugin not installed
- Check connection with `steampipe query "SELECT 1"`
