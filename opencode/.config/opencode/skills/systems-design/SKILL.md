---
name: systems-design
description: 'Distributed systems, API design, resilience, observability, and architecture patterns. Triggers on "architecture", "system design", "distributed", "scaling", "API design", "ADR".'
---

# Systems Design Skill

## Architecture Decision Records (ADRs)

### Template
```markdown
# ADR-NNN: Title

## Status
Proposed | Accepted | Deprecated | Superseded by ADR-XXX

## Context
What is the issue we're facing? What constraints exist?

## Decision
What we decided and why.

## Consequences
What becomes easier or harder because of this decision.
```

Use ADRs for: database choices, communication patterns, auth strategy, API style, infrastructure decisions.

## API Design

### REST Conventions
```
GET    /api/v1/resources          # list (paginated)
GET    /api/v1/resources/{id}     # get one
POST   /api/v1/resources          # create
PUT    /api/v1/resources/{id}     # full replace
PATCH  /api/v1/resources/{id}     # partial update
DELETE /api/v1/resources/{id}     # delete
```

### Pagination
```json
{
  "items": [...],
  "next_cursor": "eyJpZCI6MTAwfQ==",
  "has_more": true
}
```
Prefer **cursor-based** (stable, scalable) over offset-based (skips items on mutation).

### Versioning
| Strategy | When |
|----------|------|
| URL path (`/v1/`) | Public APIs, clear breaking changes |
| Header (`Accept: application/vnd.api.v2+json`) | Internal APIs |
| No versioning | Use additive changes only, never break |

### Error Responses
```json
{
  "error": {
    "code": "VALIDATION_FAILED",
    "message": "Human-readable message",
    "details": [
      {"field": "email", "issue": "invalid format"}
    ]
  }
}
```
Use consistent error codes. Machine-readable `code` + human-readable `message`.

### Idempotency
```
POST /api/v1/payments
Idempotency-Key: uuid-here
```
All mutating operations should be idempotent in distributed systems. Use client-provided idempotency keys for POST operations.

## Distributed Systems Patterns

### Communication Patterns

| Pattern | Use When | Trade-off |
|---------|----------|-----------|
| Synchronous (HTTP/gRPC) | Need immediate response | Tight coupling, cascading failures |
| Async messaging (queue) | Fire-and-forget, decoupling | Eventual consistency, complexity |
| Event streaming (Kafka) | Event sourcing, real-time | Infrastructure overhead |
| Pub/Sub (SNS/SQS) | Fan-out notifications | Message ordering not guaranteed |

### Event-Driven Architecture
```
Producer → Event Bus (Kafka/SNS) → Consumer(s)

Events are facts: OrderPlaced, UserCreated, PaymentProcessed
Commands are requests: PlaceOrder, CreateUser, ProcessPayment
```

Rules:
- Events are past tense (immutable facts)
- Commands are imperative (may fail)
- Consumers must be idempotent
- Include event schema version

### Saga Pattern (Distributed Transactions)
```
Order Service → Payment Service → Inventory Service
     ↓ fail          ↓ fail
  Compensate      Refund          Restock
```

Use sagas instead of distributed transactions (2PC). Each step has a compensating action for rollback.

### CQRS (Command Query Responsibility Segregation)
```
Writes → Command Model → Event Store
Reads  → Query Model  → Read-optimized DB (materialized view)
```
Use when read and write patterns differ significantly. Don't use for simple CRUD.

## Resilience Patterns

### Circuit Breaker
```
CLOSED → (failures exceed threshold) → OPEN
OPEN → (timeout expires) → HALF-OPEN
HALF-OPEN → (probe succeeds) → CLOSED
HALF-OPEN → (probe fails) → OPEN
```
Prevents cascading failures. Fail fast instead of waiting for timeout.

### Retry with Backoff
```python
import random

def retry_with_backoff(fn, max_retries=3, base_delay=1.0):
    for attempt in range(max_retries):
        try:
            return fn()
        except TransientError:
            if attempt == max_retries - 1:
                raise
            delay = base_delay * (2 ** attempt) + random.uniform(0, 1)
            time.sleep(delay)
```
Always add **jitter** to prevent thundering herd. Only retry on transient errors.

### Bulkhead
Isolate resources so one failing component doesn't exhaust all resources:
- Separate thread/connection pools per downstream service
- Separate Kubernetes deployments for critical paths
- Rate limit per tenant/client

### Timeout Strategy
```
Client timeout > Gateway timeout > Service timeout > DB timeout
     30s             15s               10s              5s
```
Every network call MUST have a timeout. Cascading timeouts should decrease inward.

### Graceful Degradation
- Cache stale data when upstream is down
- Return partial results instead of failing entirely
- Feature flags to disable non-critical features under load

## Data Patterns

### Database Selection
| Type | Use Case | Examples |
|------|----------|---------|
| Relational (SQL) | Structured data, ACID, complex queries | PostgreSQL, MySQL |
| Document | Flexible schema, hierarchical data | MongoDB, DynamoDB |
| Key-Value | Caching, sessions, high-throughput lookup | Redis, DynamoDB |
| Time-series | Metrics, IoT, event logs | TimescaleDB, InfluxDB |
| Graph | Relationships, social networks | Neo4j |
| Search | Full-text search, analytics | Elasticsearch, OpenSearch |

### Caching Strategy
```
Request → L1 Cache (in-process) → L2 Cache (Redis) → Database
```

| Strategy | Description | Use When |
|----------|-------------|----------|
| Cache-aside | App reads cache, fills on miss | General purpose, read-heavy |
| Write-through | Write to cache + DB together | Consistency required |
| Write-behind | Write to cache, async to DB | Write-heavy, eventual consistency OK |
| TTL-based | Auto-expire after time | Tolerable staleness |

### Consistency Models
| Model | Guarantee | Speed |
|-------|-----------|-------|
| Strong | Latest write always visible | Slowest |
| Eventual | Will converge eventually | Fast |
| Causal | Related writes in order | Medium |
| Read-your-writes | See your own writes | Medium |

Choose based on domain requirements: financial = strong, social feed = eventual.

## Scaling Patterns

### Horizontal vs Vertical
| | Horizontal | Vertical |
|-|-----------|----------|
| How | Add more instances | Bigger instance |
| Limit | Near-infinite | Hardware ceiling |
| Complexity | High (state, coordination) | Low |
| Use | Stateless services | Databases, monoliths |

### Load Balancing
| Algorithm | When |
|-----------|------|
| Round Robin | Equal instances, stateless |
| Least Connections | Varying request duration |
| Consistent Hashing | Sticky sessions, caching |
| Weighted | Heterogeneous instances |

### Sharding
Partition data across multiple databases:
- **Hash-based**: `shard = hash(key) % num_shards`
- **Range-based**: `shard_A: users 1-1M, shard_B: users 1M-2M`
- **Geography-based**: `shard_us, shard_eu, shard_ap`

Hot partition = design failure. Monitor shard distribution.

## Observability (The Three Pillars)

### Metrics
```
# Key metrics for any service
request_rate         # requests/second
error_rate           # 4xx/5xx per second
latency_p50/p95/p99  # response time percentiles
saturation           # resource utilization (CPU, memory, connections)
```
USE method for infrastructure: **U**tilization, **S**aturation, **E**rrors
RED method for services: **R**ate, **E**rrors, **D**uration

### Logs
```json
{
  "timestamp": "2024-01-15T14:30:25Z",
  "level": "error",
  "service": "payment-api",
  "trace_id": "abc123",
  "message": "payment_failed",
  "user_id": "usr_456",
  "amount": 99.99,
  "error": "insufficient_funds"
}
```
Rules: structured JSON, include trace_id, log at boundaries, never log secrets.

### Traces
```
[Client] → [API Gateway] → [Auth Service] → [Order Service] → [Payment Service]
  span1      span2           span3            span4             span5
  |------------------------------------------------------------|
  total latency: 450ms
```
Propagate trace context (W3C Trace Context / OpenTelemetry). Every service boundary = new span.

### SLIs/SLOs/SLAs
| Term | Definition | Example |
|------|-----------|---------|
| SLI | Metric you measure | p99 latency, availability |
| SLO | Target for the SLI | p99 < 200ms, 99.9% uptime |
| SLA | Contract with consequences | 99.95% or credit |

Error budget = 100% - SLO target. Spend it on innovation; when depleted, focus on reliability.

## Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| Distributed monolith | Microservices with tight coupling | Define clear bounded contexts |
| Chatty services | Too many inter-service calls | Aggregate data, use batch APIs |
| Shared database | Multiple services writing same tables | Database per service |
| No timeouts | One slow service blocks everything | Timeout + circuit breaker |
| Synchronous chains | A→B→C→D all synchronous | Async where possible |
| Premature microservices | Splitting before understanding domain | Start monolith, extract later |
| Ignoring CAP theorem | Expecting strong consistency + availability + partition tolerance | Choose 2, design for trade-offs |
