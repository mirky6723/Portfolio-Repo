from supabase import create_client
import pandas as pd

# 🔑 Supabase credentials
url = "https://hfaosealdyzmgbkpohnh.supabase.co"
anon_key = "sb_publishable_PR1-nkU7_ux4kQ7TlEFm3Q_gAFIvM6B"  # Use anon key for authentication demo

# Connect to Supabase
supabase = create_client(url, anon_key)

# 🔹 Authenticate demo user
auth_response = supabase.auth.sign_in_with_password({
    "email": "demo@portfolio.com",
    "password": "DemoPassword123!"
})

if auth_response.user:
    print("✅ Authenticated successfully!\n")
else:
    print("❌ Authentication failed")

# List of tables
tables = ["students", "attendance", "assessments", "schools"]

# Dictionary to store DataFrames
dfs = {}

# Pull each table
for table in tables:
    response = supabase.table(table).select("*").execute()
    dfs[table] = pd.DataFrame(response.data)
    print(f"\n--- {table.upper()} ---")
    print(dfs[table].head())
    print(f"Rows: {len(dfs[table])}, Columns: {len(dfs[table].columns)}")

# 🔹 Export DataFrames for other scripts
students_df = dfs["students"]
attendance_df = dfs["attendance"]
assessments_df = dfs["assessments"]
schools_df = dfs["schools"]