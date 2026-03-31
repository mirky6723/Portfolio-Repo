# excel_export.py

import pandas as pd

# Import your existing pipeline
from main import students_df, attendance_df, assessments_df, schools_df

print("🚀 Starting Excel Export...")

# ─────────────────────────────────────────────
# 🔹 DATA PREP (BUSINESS-FRIENDLY STRUCTURE)
# ─────────────────────────────────────────────

# Merge assessments with students + schools
assessment_merged = assessments_df.merge(
    students_df, on='student_id', how='left'
).merge(
    schools_df, on='school_id', how='left'
)

# Merge attendance with students
attendance_merged = attendance_df.merge(
    students_df, on='student_id', how='left'
)

# Create useful flags
assessment_merged['EL_flag'] = assessment_merged['ell_status']
assessment_merged['SPED_flag'] = assessment_merged['special_ed_flag']

# Attendance flags
attendance_merged['absent_flag'] = attendance_merged['status'].str.lower().eq('absent').astype(int)
attendance_merged['tardy_flag'] = attendance_merged['status'].str.lower().eq('tardy').astype(int)

# ─────────────────────────────────────────────
# 🔹 SUMMARY TABLES (FOR EXCEL DASHBOARD USE)
# ─────────────────────────────────────────────

# 1. Student Summary
student_summary = students_df.groupby('grade_level').agg(
    total_students=('student_id', 'count')
).reset_index()

# 2. Assessment Summary
assessment_summary = assessment_merged.groupby(
    ['grade_level', 'subject']
)['score'].mean().reset_index()

# 3. School Summary
school_summary = assessment_merged.groupby(
    ['school_name', 'grade_level', 'subject']
)['score'].mean().reset_index()

# 4. Attendance Summary
attendance_summary = attendance_merged.groupby(
    'grade_level'
).agg(
    total_absent=('absent_flag', 'sum'),
    total_tardy=('tardy_flag', 'sum'),
    total_days=('status', 'count')
).reset_index()

# ─────────────────────────────────────────────
# 📁 EXPORT TO EXCEL (MULTI-SHEET)
# ─────────────────────────────────────────────

output_file = "student_data_analysis.xlsx"

with pd.ExcelWriter(output_file, engine='openpyxl') as writer:
    
    # RAW DATA (important for flexibility)
    students_df.to_excel(writer, sheet_name='Students', index=False)
    attendance_df.to_excel(writer, sheet_name='Attendance', index=False)
    assessments_df.to_excel(writer, sheet_name='Assessments', index=False)
    schools_df.to_excel(writer, sheet_name='Schools', index=False)
    
    # CLEANED / MERGED DATA
    assessment_merged.to_excel(writer, sheet_name='Assessment_Merged', index=False)
    attendance_merged.to_excel(writer, sheet_name='Attendance_Merged', index=False)
    
    # SUMMARY TABLES (for pivot tables)
    student_summary.to_excel(writer, sheet_name='Student_Summary', index=False)
    assessment_summary.to_excel(writer, sheet_name='Assessment_Summary', index=False)
    school_summary.to_excel(writer, sheet_name='School_Summary', index=False)
    attendance_summary.to_excel(writer, sheet_name='Attendance_Summary', index=False)

print(f"✅ Excel file created: {output_file}")