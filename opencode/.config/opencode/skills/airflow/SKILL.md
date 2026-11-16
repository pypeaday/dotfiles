---
name: airflow
description: 'Airflow DAG patterns, KubernetesPodOperator, and debugging. Triggers on "dag", "airflow", "task", "operator", "KPO", "scheduler", "XCom".'
---

# Airflow Skill

Minimal, production-grade Airflow patterns for Airflow 2 and 3.

## Version Detection (Must Run First)

Before proposing any changes, confirm the Airflow version:

**Detection order (use first available):**
1. Project dependency pins (`requirements.txt`, `constraints.txt`, `pyproject.toml`)
2. Deployed image/app version (Helm values, image tags)
3. Runtime confirmation: `airflow version` inside scheduler/webserver pod

**Hard rules:**
- Do not mix constructs between Airflow major/minor versions
- Always validate guidance against the project's *current* Airflow version pin
- If you cannot determine the version, stop and ask one focused question

**Docs rule:**
- Prefer `https://airflow.apache.org/docs/apache-airflow/<major>.<minor>.*`
- Avoid `/stable/` docs unless explicitly on current stable release

## Version Support

This skill supports both Airflow 2.x and Airflow 3.x. Key differences:

### Airflow 3.x Changes
- **New import namespace**: Use `from airflow.sdk import DAG, task` instead of `airflow.models`
- **Assets replace Datasets**: `Dataset` -> `Asset`, `DatasetEvent` -> `AssetEvent`
- **No metadata DB access in tasks**: Use Airflow REST API or context instead
- **`schedule_interval` removed**: Use unified `schedule` parameter
- **`catchup=False` by default**: Explicit opt-in for backfills
- **`logical_date=None` for manual/asset triggers**: No data interval for ad-hoc runs
- **Standard operators moved**: `PythonOperator`, `BashOperator` now in `apache-airflow-providers-standard`
- **Removed**: SubDAGs, SLAs, pickling, `execution_date` context variable

### When Writing DAGs
- **Airflow 2**: Use legacy imports (`airflow.models`, `airflow.decorators`)
- **Airflow 3**: Use `airflow.sdk` imports for forward compatibility
- Check version with `from airflow import __version__`

## When to Use

- Writing new DAGs
- Debugging task failures
- Optimizing scheduler performance
- Configuring KubernetesPodOperator
- Managing connections and variables

## Python's Zen Applied to DAGs

```
Simple is better than complex.        -> Use TaskFlow over classic operators
Explicit is better than implicit.     -> Name tasks clearly, document dependencies
Flat is better than nested.           -> Avoid deep task groups unless necessary
Sparse is better than dense.          -> One DAG per file, focused responsibility
Errors should never pass silently.    -> Always set on_failure_callback
```

## DAG Skeleton

### Airflow 3.x (Recommended)
```python
"""One-line description of what this DAG does."""
from datetime import datetime
from airflow.sdk import DAG, task

with DAG(
    dag_id="my_dag",
    start_date=datetime(2024, 1, 1),
    schedule="@daily",
    catchup=False,  # Default in 3.x but explicit is better
    tags=["team-name"],
    default_args={"owner": "team", "retries": 1},
) as dag:

    @task
    def my_task() -> dict:
        return {"status": "done"}

    my_task()
```

### Airflow 2.x (Legacy)
```python
"""One-line description of what this DAG does."""
from datetime import datetime
from airflow import DAG
from airflow.decorators import task

with DAG(
    dag_id="my_dag",
    start_date=datetime(2024, 1, 1),
    schedule_interval="@daily",  # 2.x uses schedule_interval
    catchup=False,  # Must set explicitly in 2.x
    tags=["team-name"],
    default_args={"owner": "team", "retries": 1},
) as dag:

    @task
    def my_task() -> dict:
        return {"status": "done"}

    my_task()
```

## KubernetesPodOperator

### Airflow 3.x
```python
from airflow.providers.cncf.kubernetes.operators.pod import KubernetesPodOperator

KubernetesPodOperator(
    task_id="job",
    image="myimage:v1.0.0",
    cmds=["python", "run.py"],
    namespace="airflow",
    get_logs=True,
    is_delete_operator_pod=True,
)
```

### Airflow 2.x
Same as Airflow 3.x - no breaking changes to KubernetesPodOperator parameters.

### With Resources & IRSA (Both Versions)
```python
from kubernetes.client import V1ResourceRequirements

KubernetesPodOperator(
    task_id="job",
    image="myimage:v1.0.0",
    namespace="airflow",
    service_account_name="my-irsa-sa",
    container_resources=V1ResourceRequirements(
        requests={"memory": "256Mi", "cpu": "100m"},
        limits={"memory": "512Mi", "cpu": "200m"},
    ),
    get_logs=True,
    is_delete_operator_pod=True,
)
```

## Common Operators

| Need | Airflow 3.x | Airflow 2.x |
|------|-------------|-------------|
| Run Python | `@task` decorator (airflow.sdk) | `@task` decorator (airflow.decorators) |
| Run container | `KubernetesPodOperator` | `KubernetesPodOperator` |
| Run bash | `BashOperator` (providers-standard) | `BashOperator` (airflow.operators.bash) |
| Wait for S3 | `S3KeySensor` | `S3KeySensor` |
| Wait for external | `ExternalTaskSensor` | `ExternalTaskSensor` |
| Run SQL | `PostgresOperator`, `SnowflakeOperator` | `PostgresOperator`, `SnowflakeOperator` |
| Call API | `SimpleHttpOperator` (providers-standard) | `SimpleHttpOperator` (airflow.operators.http) |
| Branching | `@task.branch` | `@task.branch` |

**Note**: Airflow 3.x moved standard operators (`PythonOperator`, `BashOperator`, `EmailOperator`, `SimpleHttpOperator`) to `apache-airflow-providers-standard` package.

## XCom Patterns

```python
# Return references, not data
@task
def extract() -> str:
    s3.upload(data, "s3://bucket/output.parquet")
    return "s3://bucket/output.parquet"

@task
def transform(path: str) -> str:
    data = s3.download(path)
    # ...
    return "s3://bucket/transformed.parquet"

transform(extract())
```

**Version Notes**:
- **Airflow 3.x**: `xcom_pull(key="key")` requires `task_ids` parameter (no more implicit pulls)
- **Airflow 2.x**: `xcom_pull()` without `task_ids` allowed but ambiguous (avoid)

## Asset-Based Scheduling (Airflow 3.x)

Airflow 3.x renames Datasets to Assets and enhances event-driven scheduling.

```python
from airflow.sdk import DAG, task, Asset

# Define assets
raw_data = Asset("s3://bucket/raw/data.parquet")
clean_data = Asset("s3://bucket/clean/data.parquet")

# Producer DAG
with DAG(dag_id="producer", schedule="@daily") as producer_dag:
    @task(outlets=[raw_data])
    def extract():
        # Produces raw_data asset
        return {"status": "done"}
    
    extract()

# Consumer DAG (triggered by asset)
with DAG(dag_id="consumer", schedule=[raw_data]) as consumer_dag:
    @task(inlets=[raw_data], outlets=[clean_data])
    def transform():
        # Consumes raw_data, produces clean_data
        return {"status": "done"}
    
    transform()
```

**Airflow 2.x equivalent**: Use `Dataset` instead of `Asset` (same pattern).

**Key differences**:
- **3.x**: `from airflow.sdk import Asset`
- **2.x**: `from airflow.datasets import Dataset`
- Context variable: `triggering_asset_events` (3.x) vs `triggering_dataset_events` (2.x)

## Anti-Patterns (What to Hunt)

### Critical (Both Versions)
```python
# Top-level code (runs on every scheduler heartbeat)
import pandas as pd
df = pd.read_csv("data.csv")  # RUNS AT PARSE TIME

# Move into task
@task
def process():
    import pandas as pd
    df = pd.read_csv("data.csv")
```

```python
# Large XCom payloads
@task
def get_data():
    return huge_dataframe.to_dict()  # Stored in metadata DB!

# Use external storage
@task
def get_data():
    s3.upload(data, "s3://bucket/data.parquet")
    return "s3://bucket/data.parquet"  # Return reference only
```

```python
# Hardcoded connections
conn = psycopg2.connect(host="prod-db.example.com", password="secret")

# Use Airflow Connections
from airflow.hooks.postgres_hook import PostgresHook
hook = PostgresHook(postgres_conn_id="my_postgres")
```

```python
# Dynamic unbounded tasks
for i in range(get_count_from_db()):  # Unknown at parse time!
    task(i)

# Use expand() for dynamic mapping with bounds
@task
def get_items():
    return [1, 2, 3]  # Bounded list

@task
def process(item):
    pass

process.expand(item=get_items())
```

### Version-Specific Anti-Patterns

**Airflow 3.x**:
```python
# DON'T: Access metadata DB in tasks
from airflow.models import DagRun
dag_runs = DagRun.query.all()  # FAILS - no DB access

# DO: Use Airflow REST API or context
from airflow import __version__
# Use requests to call Airflow API
```

```python
# DON'T: Use execution_date (removed)
def my_task(**context):
    date = context["execution_date"]  # KeyError in 3.x

# DO: Use logical_date (or handle None for manual triggers)
def my_task(**context):
    date = context["dag_run"].logical_date  # May be None
```

```python
# DON'T: Use schedule_interval (removed)
DAG(dag_id="my_dag", schedule_interval="@daily")  # Fails in 3.x

# DO: Use schedule
DAG(dag_id="my_dag", schedule="@daily")
```

**Airflow 2.x**:
```python
# DON'T: Use deprecated imports (still work but warn)
from airflow.operators.python import PythonOperator  # Deprecated

# DO: Start using provider imports for 3.x readiness
from airflow.providers.standard.operators.python import PythonOperator
```

### Performance (Both Versions)
```python
# Heavy imports at top
import tensorflow as tf  # Slow import, every heartbeat

# Import inside task
@task
def train():
    import tensorflow as tf
```

## Debugging Flow

**Version note**: CLI commands same in 2.x and 3.x, but 3.x has `airflow api-server` instead of `airflow webserver`.

### 1. DAG Not Appearing
```bash
# Check for import errors
airflow dags list-import-errors

# Validate DAG parsing/import via Airflow
airflow dags list

# Optional syntax/import sanity check (not execution)
python dags/my_dag.py

# Check scheduler logs
kubectl logs -l component=scheduler -n airflow --tail=100
```

### 2. Task Failing
```bash
# Get task logs
airflow tasks logs <dag_id> <task_id> <execution_date>

# Test task locally
airflow tasks test <dag_id> <task_id> <execution_date>

# For KPO: check pod logs
kubectl logs <pod-name> -n airflow
```

### 3. Task Stuck
```bash
# Check task state
airflow tasks state <dag_id> <task_id> <execution_date>

# Check for zombie tasks
airflow tasks clear <dag_id> -t <task_id> -s <start> -e <end>

# Check executor capacity
kubectl get pods -n airflow -l component=worker
```

### 4. Scheduler Slow
```bash
# Check parse times
airflow dags report

# Find slow DAGs (> 1s parse time is bad)
# Optimize: remove top-level imports, reduce file count
```

## Quick Commands

```bash
# Validate DAG
airflow dags test <dag_id> <execution_date>

# Trigger DAG
airflow dags trigger <dag_id>

# Backfill
airflow dags backfill <dag_id> -s <start> -e <end>

# Clear tasks for re-run
airflow tasks clear <dag_id> -s <start> -e <end>

# List DAGs
airflow dags list

# Show DAG structure
airflow dags show <dag_id>
```

## Response Format

When creating/modifying DAGs:
```
DAG: <dag_id>
Schedule: <schedule>
Tasks: <task1> -> <task2> -> <task3>
Dependencies: <new providers needed>
```

When debugging:
```
Symptom: <what's happening>
Root cause: <why>
Fix: <action>
```

## Minimalism Checklist

Before adding DAG code:
- [ ] Can this be a sensor waiting for data instead of polling?
- [ ] Can this use existing operators instead of PythonOperator?
- [ ] Can this use `@task` decorator instead of classic operator?
- [ ] Is XCom payload a reference (path/URI) not data?
- [ ] Are all imports inside tasks (not top-level)?
- [ ] Is `catchup=False` if backfill not needed?

## Connections & Variables

**Airflow 3.x**:
```python
# Get connection (Task SDK)
from airflow.sdk import Connection
conn = Connection.get("my_conn")

# Get variable (Task SDK)
from airflow.sdk import Variable
val = Variable.get("my_var")

# Get secret (if Secrets Backend configured)
val = Variable.get("my_secret")  # Fetches from Secrets Manager
```

**Airflow 2.x**:
```python
# Get connection
from airflow.hooks.base import BaseHook
conn = BaseHook.get_connection("my_conn")

# Get variable
from airflow.models import Variable
val = Variable.get("my_var")

# Get secret (if Secrets Backend configured)
val = Variable.get("my_secret")  # Fetches from Secrets Manager
```

## Task Dependencies

```python
# Chain
task1 >> task2 >> task3

# Fan out
task1 >> [task2, task3]

# Fan in
[task1, task2] >> task3

# TaskFlow (implicit)
result = task2(task1())
```

**Version notes**: Dependency syntax identical across versions.

## Migration Guide (2.x -> 3.x)

### High Priority
1. **Update imports**: `airflow.sdk` instead of `airflow.models`, `airflow.decorators`
2. **Replace `schedule_interval`** with `schedule`
3. **Replace `execution_date`** with `dag_run.logical_date` (handle `None` for manual triggers)
4. **Update Dataset -> Asset** references
5. **Remove DB access** from task code (use Airflow API instead)
6. **Fix `xcom_pull()`**: Always specify `task_ids` parameter

### Medium Priority
1. **Update operator imports**: Move to `apache-airflow-providers-standard` package
2. **Set `catchup=False`** explicitly (if you rely on current behavior)
3. **Remove SubDAGs**: Replace with TaskGroups
4. **Remove SLA callbacks**: Implement custom alerting

### Low Priority
1. Review deprecated config options with `airflow config lint`
2. Use `ruff check --select AIR30 --preview` to find migration issues
3. Test in Airflow 2.10+ before upgrading to 3.x

### Quick Version Check
```python
from airflow import __version__

if __version__.startswith("3"):
    from airflow.sdk import DAG, task
else:
    from airflow import DAG
    from airflow.decorators import task
```
