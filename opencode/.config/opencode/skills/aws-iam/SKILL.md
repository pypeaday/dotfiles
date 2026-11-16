---
name: aws-iam
description: 'Create and debug AWS IAM policies with least-privilege. Triggers on "IAM policy", "permission denied", "access denied", "not authorized", "create role".'
---

# AWS IAM Skill

Create least-privilege IAM policies and debug access issues.

## When to Use

- Create IAM roles/policies
- Debug "Access Denied" errors
- Audit existing permissions
- Set up cross-account access
- Configure service roles

## Policy Principles

### Least Privilege
- Specific actions, not `*`
- Specific resources, not `*`
- Add Condition blocks when possible
- Use managed policies over inline

### Policy Structure
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "DescriptiveName",
    "Effect": "Allow",
    "Action": ["s3:GetObject"],
    "Resource": "arn:aws:s3:::bucket/path/*",
    "Condition": {
      "StringEquals": {"aws:PrincipalTag/team": "myteam"}
    }
  }]
}
```

## Debug Access Denied

### 1. Identify the Error
```bash
# Check CloudTrail for denied requests
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=<operation> \
  --query 'Events[?contains(CloudTrailEvent, `AccessDenied`)]'
```

### 2. Simulate Policy
```bash
# Test if policy allows action
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::123456789:role/MyRole \
  --action-names s3:GetObject \
  --resource-arns arn:aws:s3:::mybucket/mykey
```

### 3. Common Causes
| Error | Check | Fix |
|-------|-------|-----|
| Explicit deny | Check SCPs, permission boundaries | Remove deny statement |
| Missing action | Policy doesn't include action | Add specific action |
| Wrong resource | ARN doesn't match | Fix resource ARN pattern |
| Condition failed | Condition block not met | Check tags, VPC, etc. |

## Common Patterns

### S3 Read-Only
```json
{
  "Effect": "Allow",
  "Action": ["s3:GetObject", "s3:ListBucket"],
  "Resource": [
    "arn:aws:s3:::bucket",
    "arn:aws:s3:::bucket/*"
  ]
}
```

### Lambda Execution Role
```json
{
  "Effect": "Allow",
  "Action": [
    "logs:CreateLogGroup",
    "logs:CreateLogStream",
    "logs:PutLogEvents"
  ],
  "Resource": "arn:aws:logs:*:*:log-group:/aws/lambda/*"
}
```

### EKS Pod Role (IRSA)
```json
{
  "Effect": "Allow",
  "Principal": {"Federated": "arn:aws:iam::ACCOUNT:oidc-provider/OIDC"},
  "Action": "sts:AssumeRoleWithWebIdentity",
  "Condition": {
    "StringEquals": {
      "OIDC:sub": "system:serviceaccount:NAMESPACE:SA_NAME"
    }
  }
}
```

### Cross-Account Access
```json
{
  "Effect": "Allow",
  "Principal": {"AWS": "arn:aws:iam::OTHER_ACCOUNT:root"},
  "Action": "sts:AssumeRole",
  "Condition": {
    "StringEquals": {"sts:ExternalId": "UNIQUE_ID"}
  }
}
```

## Quick Commands

```bash
# List attached policies
aws iam list-attached-role-policies --role-name MyRole

# Get policy document
aws iam get-role-policy --role-name MyRole --policy-name MyPolicy

# Who can assume this role?
aws iam get-role --role-name MyRole --query 'Role.AssumeRolePolicyDocument'

# Test credentials
aws sts get-caller-identity
```

## Policy Evaluation Logic

When AWS evaluates a request, it follows this order:

```
1. Explicit DENY in any policy?          → DENY (game over)
2. SCP (Organizations) allows it?        → If no: DENY
3. Permission boundary allows it?        → If no: DENY
4. Session policy allows it?             → If no: DENY
5. Identity-based policy allows it?      → If yes: ALLOW
6. Resource-based policy allows it?      → If yes: ALLOW (for same account)
7. Nothing matched                       → DENY (implicit)
```

Key insight: **Explicit deny always wins.** Even if a policy says Allow, a Deny elsewhere overrides it.

### Service Control Policies (SCPs)
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "DenyNonApprovedRegions",
    "Effect": "Deny",
    "Action": "*",
    "Resource": "*",
    "Condition": {
      "StringNotEquals": {
        "aws:RequestedRegion": ["us-east-1", "us-west-2"]
      }
    }
  }]
}
```
SCPs are guardrails at the Organization/OU level. They restrict what member accounts can do but don't grant permissions.

### Permission Boundaries
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": ["s3:*", "logs:*", "lambda:*"],
    "Resource": "*"
  }]
}
```
```bash
# Attach as permission boundary
aws iam put-role-permission-boundary \
  --role-name DeveloperRole \
  --permissions-boundary arn:aws:iam::123456789:policy/DeveloperBoundary
```
Permission boundaries set the **maximum** permissions a role/user can have. The effective permissions are the intersection of identity policy AND boundary.

## Attribute-Based Access Control (ABAC)

```json
{
  "Effect": "Allow",
  "Action": ["s3:GetObject", "s3:PutObject"],
  "Resource": "arn:aws:s3:::project-*",
  "Condition": {
    "StringEquals": {
      "s3:ExistingObjectTag/team": "${aws:PrincipalTag/team}"
    }
  }
}
```
ABAC uses tags to control access without creating per-resource policies. Tag principals and resources, then write conditions that match them.

## IAM Access Analyzer

```bash
# Find unused permissions
aws accessanalyzer list-findings --analyzer-arn <arn>

# Generate policy from CloudTrail activity
aws accessanalyzer start-policy-generation \
  --policy-generation-details '{"principalArn":"arn:aws:iam::123:role/MyRole"}'

# Check for external access
aws accessanalyzer list-findings --analyzer-arn <arn> \
  --filter '{"status":{"eq":["ACTIVE"]}}'
```

Use Access Analyzer to:
- Find resources shared externally (S3, SQS, Lambda, KMS, IAM roles)
- Generate least-privilege policies from CloudTrail logs
- Validate policies before deploying

## Red Flags

- `"Action": "*"` -> Too broad
- `"Resource": "*"` -> Too broad
- No `Condition` -> Consider adding
- Inline policies -> Use managed policies
- Long-lived access keys -> Use IAM roles
- No permission boundary on developer roles -> Add one
- SCP not restricting regions -> Add region restriction
- No Access Analyzer enabled -> Turn it on
