import os
from sqlalchemy import create_engine
import pandas as pd
from dotenv import load_dotenv

load_dotenv(".env.sample")

SQL_ENDPOINT = "postgresql+psycopg2://{}:{}@{}/{}"


def create_nycdb_engine():
    sql_path = SQL_ENDPOINT.format(
        *[
            os.getenv(t) for t in [
                'NYCDB_USER',
                'NYCDB_PASSWORD',
                'NYCDB_HOST',
                'NYCDB_DBNAME'
            ]
        ]
    )
    engine = create_engine(sql_path)
    return engine

def load_all_bbls():
    engine = create_nycdb_engine()
    with open('all_bbls.sql', 'r') as file:
        all_bbls_sql = file.read()
    all_bbls = pd.read_sql_query(all_bbls_sql, engine)
    return all_bbls