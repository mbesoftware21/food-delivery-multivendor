import os
import psycopg2
from psycopg2 import pool

# Database Configuration
DATABASE_URL = os.getenv("DATABASE_URL", "postgres://postgres:postgrespassword@localhost:5432/enatega")

def run_migration():
    print(f"Connecting to database...")
    try:
        conn = psycopg2.connect(DATABASE_URL)
        cur = conn.cursor()
        
        print("Reading SQL file...")
        with open("phase2_schema.sql", "r") as f:
            sql_content = f.read()
            
        print("Executing SQL...")
        cur.execute(sql_content)
        conn.commit()
        
        print("Migration completed successfully!")
        
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error during migration: {e}")

if __name__ == "__main__":
    run_migration()
