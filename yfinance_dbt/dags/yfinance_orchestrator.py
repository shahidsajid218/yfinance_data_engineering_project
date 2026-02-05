from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta
import os

# --- PATH CONFIGURATION ---
# Path to the dbt project on your Windows mount
DBT_PROJECT_DIR = "/mnt/c/personal/Finance Data Engineering Project/yfinance_dbt"

# Path to your dbt-specific virtual environment's bin folder
# Assuming you created a venv named 'dbt_venv' in your project folder
DBT_VENV_EXECUTABLE = "/mnt/c/personal/Finance Data Engineering Project/.venv_dbt/bin/dbt"

# Location of your profiles.yml (usually in Linux home)
DBT_PROFILES_DIR = "/mnt/c/personal/Finance Data Engineering Project/yfinance_dbt"

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2026, 1, 1),
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    'yfinance_dbt_transformation',
    default_args=default_args,
    description='NYSE Hours dbt transformation',
    # Runs at the top of every hour from 14:00 to 21:00 (2:30pm-9pm range), Mon-Fri
    schedule_interval='0 14-21 * * 1-5', 
    catchup=False,
    tags=['yfinance', 'dbt', 'production'],
) as dag:

    # 1. Run Silver Layer (Cleansing & Hive Partitioning logic)
    run_silver = BashOperator(
    task_id='dbt_run_silver',
    bash_command=(
        f'"{DBT_VENV_EXECUTABLE}" run --select silver_layer '  # Double quotes around the path
        f'--project-dir "{DBT_PROJECT_DIR}" '                 # Double quotes around the project dir
        f'--profiles-dir "{DBT_PROFILES_DIR}"'                # Double quotes around the profiles dir
    ),
)

    # 2. Run Gold Layer (Final Analytics Tables)
    # 2. Run Gold Layer (Final Analytics Tables)
    run_gold = BashOperator(
        task_id='dbt_run_gold',
        bash_command=(
            f'"{DBT_VENV_EXECUTABLE}" run --select gold_layer '
            f'--project-dir "{DBT_PROJECT_DIR}" '
            f'--profiles-dir "{DBT_PROFILES_DIR}"'
        ),
    )

    run_silver >> run_gold