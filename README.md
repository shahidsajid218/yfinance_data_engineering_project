# yfinance-DE-Project

A comprehensive, event-driven data engineering pipeline for collecting, transforming, and analyzing financial market data using Yahoo Finance, AWS, Snowflake, and dbt, orchestrated by Apache Airflow.

## 📋 Overview

This project orchestrates a complete ETL/ELT pipeline that:
- **Extracts** stock data via **AWS Lambda** (Python) triggered by **AWS EventBridge**.
- **Streams** data through **AWS S3** using **Hive-style partitioning** for optimized storage.
- **Loads** data into **Snowflake** via **Snowpipe** with automated **SNS** error alerting.
- **Transforms** data through a Medallion Architecture (**Bronze → Silver → Gold**) using **dbt**.
- **Visualizes** technical indicators like RSI and Moving Averages in a dynamic **Power BI** dashboard.

The pipeline is synchronized with NYSE trading hours (14:30 - 21:00 GMT, Monday-Friday) to capture intraday market movements while minimizing cloud compute costs.


## 🚀 Key Engineering Features

### **1. Serverless Ingestion & Event-Driven Scheduling**
* **AWS EventBridge Scheduler:** Triggers the Python Lambda extractor on a precise Cron schedule (`14:30 – 21:00 GMT`) to align with NYSE trading hours, ensuring cost-efficient data collection without idle server overhead.
* **S3 Hive-Style Partitioning:** The Lambda script dynamically organizes data in S3 using a `ticker=SYMBOL/year=YYYY/month=MM/day=DD/` key structure. This physical partitioning enables high-performance data pruning during the ingestion and transformation phases.
* **Automated Snowpipe Loading:** Leverages **Snowpipe** integrated with **Amazon SQS** for real-time ingestion. Data moves from S3 into Snowflake Bronze tables within seconds of the file landing.
* **Cloud-Native Monitoring:** Centralized logging via **Amazon CloudWatch** tracks Lambda execution health, while **AWS SNS** provides automated error notifications if Snowpipe ingestion fails.

### **2. Advanced Airflow Orchestration**
* **Workload Coordination:** Airflow serves as the primary orchestrator, managing the dependencies between dbt transformations and data availability.
* **Custom Market-Hour Scheduling:** DAGs are configured to respect market downtime, preventing unnecessary warehouse activations during weekends or non-trading hours.
* **Failure Recovery:** Implemented robust retry logic and alert sensors within Airflow to ensure the pipeline recovers gracefully from API timeouts or intermittent network issues.
* **Environment Parity:** Developed and tested within **WSL2** (Ubuntu) to ensure seamless local orchestration that mimics production Linux environments.

### **3. dbt Transformation & Data Governance**
* **Incremental Materialization:** The Silver layer uses dbt’s `incremental` strategy with a `merge` predicate. This ensures only new records are processed, drastically reducing Snowflake credit consumption.
* **Principle of Least Privilege (PoLP):** Enforced via custom Snowflake RBAC. Distinct roles (`LOADER`, `TRANSFORMER`, `READER`) restrict access based on function, securing the data from ingestion to visualization.
* **Data Quality Testing:** A comprehensive suite of dbt tests ensures schema integrity (Unique/Not-Null) and validates business logic (e.g., RSI oscillators staying within the 0-100 range).

### **4. Business Intelligence (Power BI)**
* **Dynamic UX:** Developed **DAX-driven contextual titles** that update automatically based on the selected Ticker and timeframe slicers.
* **Analytics-Ready Gold Layer:** The dashboard connects directly to the Gold layer, providing high-performance visualization of technical indicators (RSI, Moving Averages) without requiring complex in-report transformations.
<img width="1260" height="356" alt="image" src="https://github.com/user-attachments/assets/43cb294d-b7c1-4ad9-bd9a-5fb18ba767c7" />


## 🏗️ Architecture

[yfinance API] 
      │
      ▼
[AWS Lambda] ───► [AWS CloudWatch Logs]                                            
      │
      ▼
[AWS S3 (Landing)] ───► [AWS SNS/SQS] ───► [Snowpipe]
                                              │
                                              ▼
[Airflow] ───► [dbt Core] ───► [Snowflake (Medallion)]
                                              │
                                              ▼
                                        [Power BI Dashboard]





                                        


<img width="1536" height="1024" alt="project archiectecture" src="https://github.com/user-attachments/assets/97a4e806-3d24-4a61-bc7f-bfd8f69e3aeb" />





### Data Layers (Medallion Architecture)
- **Bronze (Landing):** Raw JSON/CSV extracts stored in S3 and mirrored in Snowflake.
- **Silver (Cleansing):** Data cast to correct types, duplicates removed, and organized via **Hive-style Partitioning** (Year/Month/Day).
- **Gold (Analytics):** Aggregated metrics including **RSI (Relative Strength Index)** and **Hourly Moving Averages** for BI consumption.

### Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Orchestration** | Apache Airflow | DAG scheduling & NYSE-aligned workflow management |
| **Transformation** | dbt (Data Build Tool) | Modular SQL modeling and Medallion layer logic |
| **Cloud Storage** | AWS S3 | Scalable landing zone for raw financial extracts |
| **Ingestion** | Snowpipe + SQS | Serverless, real-time data loading into Snowflake |
| **Messaging** | Amazon SNS | Automated outbound alerting for ingestion failures |
| **Data Warehouse**| Snowflake | High-performance cloud compute and storage |
| **Visualization** | Power BI | Dynamic reporting with DAX-driven time intelligence |




## 📁 Project Structure

```

├── README.md                          # This file
├── dbt_project.yml                    # dbt project configuration
├── pyproject.toml                     # Python project metadata
│
├── airflow_home/                      # Apache Airflow configuration
│   ├── airflow.cfg                    # Airflow configuration settings
│   ├── webserver_config.py            # Airflow webserver settings
│   ├── dags/
│   │   └── yfinance_orchestrator.py   # Main ETL DAG
│   └── logs/                          # Airflow execution logs
│
├── yfinance_dbt/                      # dbt project root
│   ├── dbt_project.yml                # dbt configuration
│   ├── profiles.yml                   # Snowflake connection profile
│   ├── models/                        # dbt transformation models
│   │   └── example/                   # Sample models
│   ├── macros/                        # dbt macros (e.g., get_custom_schema.sql)
│   ├── tests/                         # dbt data tests
│   ├── seeds/                         # Static data files
│   ├── analyses/                      # Ad-hoc analysis queries
│   └── target/                        # dbt compiled artifacts
│
├── scripts/                           # Python utility scripts and helpers
│   ├── get_stock_data.py              # Stock data extraction (AWS Lambda compatible)
│   ├── requirements.txt               # Python dependencies
│   ├── python/                        # Vendored Python packages
│   │   ├── yfinance/                  # Yahoo Finance library
│   │   ├── pandas/                    # Data manipulation
│   │   ├── numpy/                     # Numerical computing
│   │   └── [other dependencies]
│   └── snowflake_scripts/             # Snowflake initialization SQL scripts (execute in Snowflake Worksheets or via SnowSQL)
│       ├── snowflake_airflow_init.sql # Airflow integration setup (SQL to run in Snowflake)
│       ├── Snowflake_db_init.sql      # Database & schema creation (run in Snowflake)
│       └── snowflake_dbt_init.sql     # dbt user & role setup (run in Snowflake)
│
└── [other top-level folders]
```

## 🚀 Quick Start





### Prerequisites

- **Python** >= 3.9
- **Apache Airflow** (configured in `airflow_home/`)
- **dbt** with Snowflake adapter
- **Snowflake** account with appropriate permissions
- **Yahoo Finance API** access (free tier)

### WSL2 Development Setup (Airflow and dbt in separate venvs)

The project is developed and tested on WSL2 (Ubuntu). Airflow and dbt each run in their own virtual environments: `.venv_airflow` and `.venv_dbt` respectively. Airflow will invoke the `dbt` executable directly from the dbt venv.

Follow these copy-paste steps inside WSL (adjust paths and usernames):

1. Clone or copy the repository into WSL for best I/O performance:

```bash
mkdir -p ~/projects
cp -r /mnt/c/Personal/Finance\ Data\ Engineering\ Project ~/projects/finance-data-engineering
cd ~/projects/finance-data-engineering
```

2. Install system packages:

```bash
sudo apt update
sudo apt install -y python3 python3-venv python3-pip git build-essential
```

3. Create separate virtualenvs for Airflow and dbt:

```bash
python3 -m venv .venv_airflow
python3 -m venv .venv_dbt
```

4. Install and initialize Airflow (in `.venv_airflow`):

```bash
source .venv_airflow/bin/activate
pip install --upgrade pip setuptools wheel
# Use a matching Airflow version and constraints from the official docs
AIRFLOW_VERSION=2.6.3
PYTHON_VERSION=3.11
CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt"
pip install "apache-airflow==${AIRFLOW_VERSION}" --constraint "${CONSTRAINT_URL}"

export AIRFLOW_HOME="$PWD/airflow_home"
airflow db init
airflow users create --username admin --password admin --firstname Admin --lastname User --role Admin --email admin@example.com

# Start services (in separate terminals)
source .venv_airflow/bin/activate
airflow webserver -p 8080

source .venv_airflow/bin/activate
airflow scheduler
```

5. Install dbt and Snowflake adapter (in `.venv_dbt`):

```bash
source .venv_dbt/bin/activate
pip install --upgrade pip setuptools wheel
pip install dbt-snowflake
which dbt
# Example output: /home/you/projects/finance-data-engineering/.venv_dbt/bin/dbt
```

6. Configure dbt profiles and environment variables:

```bash
# Point DBT_PROFILES_DIR to the yfinance_dbt directory
export DBT_PROFILES_DIR="$PWD/yfinance_dbt"
echo 'export DBT_PROFILES_DIR="$PWD/yfinance_dbt"' >> ~/.bashrc
```

7. Update the DAG to use the dbt executable path (example variables in `airflow_home/dags/yfinance_orchestrator.py`):

```python
DBT_PROJECT_DIR = "/home/you/projects/finance-data-engineering/yfinance_dbt"
DBT_VENV_EXECUTABLE = "/home/you/projects/finance-data-engineering/.venv_dbt/bin/dbt"
DBT_PROFILES_DIR = "/home/you/projects/finance-data-engineering/yfinance_dbt"
```

The DAG invokes dbt by calling the full `DBT_VENV_EXECUTABLE` path, so Airflow will run the dbt binary directly (no `source` needed inside the DAG).

8. Test the dbt command used by the DAG (run from any shell):

```bash
"/home/you/projects/finance-data-engineering/.venv_dbt/bin/dbt" run --select silver_layer \
  --project-dir "/home/you/projects/finance-data-engineering/yfinance_dbt" \
  --profiles-dir "/home/you/projects/finance-data-engineering/yfinance_dbt"
```

9. Add venvs and build artifacts to `.gitignore`:

```bash
echo ".venv*/" >> .gitignore
echo "airflow_home/logs/" >> .gitignore
echo "target/" >> .gitignore
echo "dbt_packages/" >> .gitignore
git add .gitignore && git commit -m "Add venv and build artifacts to .gitignore"
```

Notes:
- Keep Snowflake secrets out of `profiles.yml` in source control; use env vars or a secrets manager where possible.
- For local development `airflow standalone` is a convenient shortcut, but running `webserver` and `scheduler` separately gives more control and keeps venv activation explicit.
- If you want, I can update `airflow_home/dags/yfinance_orchestrator.py` to read the three DBT variables from environment variables and fall back to defaults.

### Installation

1. **Clone/navigate to the project**
   ```bash
   cd "c:\Personal\Finance Data Engineering Project"
   ```

2. **Set up Python environment**
   ```bash
   python -m venv venv
   venv\Scripts\activate
   pip install -r scripts/requirements.txt
   ```

3. **Configure Snowflake connection**
    - Update `yfinance_dbt/profiles.yml` with your Snowflake credentials
    - Run initialization scripts **inside Snowflake**. These are SQL files meant to be executed in the Snowflake environment (use Snowflake Web UI Worksheets or the `snowsql` CLI). They are not runnable directly in VS Code.
       - Example: open a new Worksheet in the Snowflake web UI, paste the SQL from `scripts/snowflake_scripts/Snowflake_db_init.sql`, and execute.
       - Or use SnowSQL:
          ```bash
          snowsql -a <account> -u <user> -f scripts/snowflake_scripts/Snowflake_db_init.sql
          snowsql -a <account> -u <user> -f scripts/snowflake_scripts/snowflake_dbt_init.sql
          snowsql -a <account> -u <user> -f scripts/snowflake_scripts/snowflake_airflow_init.sql
          ```

4. **Initialize Airflow**
   ```bash
   set AIRFLOW_HOME=airflow_home
   airflow standalone
   ```
   - Access webUI at `http://localhost:8080`
   - Login with credentials from `airflow_home/standalone_admin_password.txt`

5. **Deploy dbt models**
   ```bash
   cd yfinance_dbt
   dbt debug
   dbt run
   ```

## 📊 Data Flow

### Airflow DAG: `yfinance_dbt_transformation`

**Schedule**: Every hour from 2:00 PM - 9:00 PM ET, Monday-Friday

**Tasks**:
1. `dbt_run_silver` - Cleansing & Hive-style partitioning
2. `dbt_run_gold` - Analytics aggregation & enrichment
3. (Optional) Data quality tests

### Data Extraction

The `scripts/get_stock_data.py` script:
- Fetches 1-minute interval data via yfinance
- Processes and enriches stock tickers
- Uploads to S3 or Snowflake staging area
- Compatible with AWS Lambda for serverless execution

## 🔧 Configuration

### Airflow DAG Configuration

Edit `airflow_home/dags/yfinance_orchestrator.py`:
- **DBT_PROJECT_DIR** - Path to dbt project
- **DBT_VENV_EXECUTABLE** - Path to dbt executable
- **schedule_interval** - Cron expression for execution timing
- **default_args.start_date** - Pipeline start date

### dbt Configuration

Edit `yfinance_dbt/dbt_project.yml`:
- **name** - Project identifier
- **version** - Project version
- **profile** - Snowflake connection profile
- **model-paths** - Location of transformation models

### Snowflake Connection

Update `yfinance_dbt/profiles.yml`:
```yaml
yfinance_dbt:
  outputs:
    dev:
      type: snowflake
      account: [your-account-id]
      user: [your-username]
      password: [your-password]
      role: [role-name]
      database: [database-name]
      schema: [schema-name]
      threads: 4
      client_session_keep_alive: false
  target: dev
```

## 📈 Models & Transformations

### Silver Layer Models
- Data cleansing and validation
- Hive-style partitioning by date/ticker
- Removal of duplicates and null handling

### Gold Layer Models
- Time-series aggregations (hourly, daily, etc.)
- Technical indicators (moving averages, volatility)
- Analytics-ready fact and dimension tables

## 🧪 Testing

Run dbt data tests:
```bash
cd yfinance_dbt
dbt test
```

Test includes:
- NOT NULL constraints
- Unique key validation
- Referential integrity
- Custom data quality checks

## 📝 Development Workflow

### Adding a New Model

1. Create SQL file in `yfinance_dbt/models/[layer]/`
2. Define source/ref relationships
3. Add documentation in `schema.yml`
4. Run `dbt run --select [model_name]`
5. Run `dbt test --select [model_name]`

### Debugging

**Check Airflow logs**:
```bash
echo %AIRFLOW_HOME%\logs\dag_id=yfinance_dbt_transformation\
```

**Check dbt artifacts**:
```bash
cd yfinance_dbt
dbt docs generate
dbt docs serve  # View at http://localhost:8000
```

## 🔐 Security & Best Practices

- Store Snowflake credentials in environment variables, not in `profiles.yml`
- Use Airflow connections/secrets management for sensitive data
- Implement IAM roles in Snowflake (separate read/write permissions)
- Version control dbt models but exclude `profiles.yml`

## 📚 Resources

- [dbt Documentation](https://docs.getdbt.com/)
- [Apache Airflow Docs](https://airflow.apache.org/)
- [Snowflake Documentation](https://docs.snowflake.com/)
- [yfinance Documentation](https://github.com/ranaroussi/yfinance)

## 📞 Support & Contribution

For issues or improvements, refer to the specific component documentation or check logs in:
- `airflow_home/logs/` - Airflow execution logs
- `yfinance_dbt/target/` - dbt run artifacts

## 📄 License



---

**Last Updated**: February 5, 2026
