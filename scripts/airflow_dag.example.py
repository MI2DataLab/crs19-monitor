from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.dummy import DummyOperator
from airflow.utils.dates import days_ago
import os

args = {
    'owner': '<airflow_user>',
    'retries': 0,
    'retry_delay': timedelta(minutes=30)
}

repo_path = '<path to project repo>'

def generate_dag(dag_id, schedule):
    dag = DAG(
        dag_id=dag_id,
        default_args=args,
        max_active_runs=1,
        start_date=datetime(2021, 3, 25),
        catchup=False,
        schedule_interval=schedule
    )
    
    task_fasta_to_pango = BashOperator(
        task_id='fasta_to_pango',
        bash_command='python ' + repo_path + '/scripts/task_fasta_to_pango.py',
        dag=dag,
    )
    
    task_fasta_to_clades = BashOperator(
        task_id='fasta_to_clades',
        bash_command='python ' + repo_path + '/scripts/task_fasta_to_clades.py',
        dag=dag,
    )
    
    # Not used anymore
    #task_fasta_to_mutation = BashOperator(
    #    task_id='fasta_to_mutation',
    #    bash_command='python ' + repo_path + '/scripts/task_fasta_to_mutation.py',
    #    dag=dag,
    #)

    task_scrapper = BashOperator(
        task_id='scrapper',
        retries=2,
        bash_command='SKIP_VARIANTS=1 SKIP_PANGO=1 python ' + repo_path + '/scripts/task_scrapper.py',
        execution_timeout = timedelta(minutes=360),
        dag=dag
    )
    
    task_generate_site = BashOperator(
        task_id='generate_site',
        bash_command='python ' + repo_path + '/scripts/task_generate_site.py',
        dag=dag,
    )

    task_backup = BashOperator(
        task_id='backup',
        bash_command='python ' + repo_path + '/scripts/task_backup.py',
        dag=dag,
    )

    task_clear_old_sites = BashOperator(
        task_id='clear_old_sites',
        bash_command='python ' + repo_path + '/scripts/task_clear_old_sites.py',
        dag=dag,
    )
    
    task_clean_database = BashOperator(
        task_id='clean_database',
        bash_command='python ' + repo_path + '/scripts/task_clean_database.py',
        dag=dag,
    )
    
    task_scrapper >> [task_fasta_to_pango, task_fasta_to_clades] >> task_clean_database >> task_generate_site >> task_clear_old_sites >> task_backup
    return dag

dag1 = generate_dag('europe', '0 */12 * * *')
