# student_dashboard.py
from dash import Dash, html, dcc
import plotly.express as px
import plotly.graph_objects as go
import pandas as pd
import seaborn as sns

# Import data from main.py (keep main.py for data access)
from main import students_df, attendance_df, assessments_df, schools_df

# -----------------------------
# Data Preparation
# -----------------------------

# 1️⃣ Merge students with assessments for average score per student
student_scores = assessments_df.groupby("student_id")["score"].mean().reset_index()
student_scores = student_scores.merge(students_df, on="student_id")
student_scores = student_scores.merge(schools_df, on="school_id")

# 2️⃣ Attendance summary per student (stacked counts of Present, Absent, Tardy)
attendance_summary = attendance_df.pivot_table(
    index="student_id",
    columns="status",
    aggfunc="size",
    fill_value=0
).reset_index()
attendance_summary = attendance_summary.merge(students_df, on="student_id")

# 3️⃣ Attendance percentage by grade level
attendance_by_grade = attendance_summary.groupby("grade_level")[["Present", "Absent", "Tardy"]].sum()
attendance_by_grade["Total"] = attendance_by_grade.sum(axis=1)
attendance_by_grade["Present%"] = (attendance_by_grade["Present"] / attendance_by_grade["Total"] * 100).round(2)
attendance_by_grade.reset_index(inplace=True)

# 4️⃣ Correlation matrix of assessments
assessment_corr = assessments_df.pivot(index="student_id", columns="subject", values="score").corr()

# -----------------------------
# Dash App Setup
# -----------------------------
app = Dash(__name__)
app.title = "Student Data Dashboard"

app.layout = html.Div(style={"fontFamily": "Arial, sans-serif", "margin": "20px"}, children=[
    html.H1("📊 Student Data Dashboard", style={"textAlign": "center"}),

    # -----------------------------
    # Average Scores by School
    html.H2("Average Scores by School"),
    dcc.Graph(
        figure=px.bar(
            student_scores.groupby("school_name")["score"].mean().reset_index(),
            x="school_name",
            y="score",
            color="school_name",
            text_auto=True,
            labels={"score": "Average Score", "school_name": "School"}
        )
    ),

    # -----------------------------
    # Attendance Summary (Stacked by Status)
    html.H2("Attendance Summary per Student"),
    dcc.Graph(
        figure=px.bar(
            attendance_summary.melt(
                id_vars=["student_id", "first_name", "last_name"],
                value_vars=["Present", "Absent", "Tardy"],
                var_name="Status",
                value_name="Count"
            ),
            x="first_name",
            y="Count",
            color="Status",
            barmode="stack",
            hover_data=["last_name"]
        )
    ),

    # -----------------------------
    # Attendance Percentage by Grade
    html.H2("Attendance Percentage by Grade"),
    dcc.Graph(
        figure=px.bar(
            attendance_by_grade,
            x="grade_level",
            y="Present%",
            text="Present%",
            labels={"grade_level": "Grade Level", "Present%": "% Present"},
            title="Average Attendance Percentage per Grade"
        )
    ),

    # -----------------------------
    # ELL vs Average Score
    html.H2("ELL Status vs Average Score (Box Plot with Outliers)"),
    dcc.Graph(
        figure=px.box(
            student_scores,
            x="ell_status",
            y="score",
            color="ell_status",
            points="all",  # Show all points
            labels={"ell_status": "ELL Status", "score": "Average Score"},
            title="Distribution of Average Scores by ELL Status"
        )
    ),

    # -----------------------------
    # Special Ed vs Average Score
    html.H2("Special Education vs Average Score"),
    dcc.Graph(
        figure=px.box(
            student_scores,
            x="special_ed_flag",
            y="score",
            color="special_ed_flag",
            points="all",  # Show individual student scores
            labels={"special_ed_flag": "Special Ed", "score": "Average Score"},
            title="Distribution of Average Scores by Special Ed Status"
        )
    ),

    # -----------------------------
    # Correlation Heatmap of Assessment Scores
    html.H2("Correlation Matrix of Assessment Scores"),
    dcc.Graph(
        figure=px.imshow(
            assessment_corr,
            text_auto=True,
            color_continuous_scale="Viridis",
            labels={"x": "Subject", "y": "Subject", "color": "Correlation"},
            title="Correlation between Subjects"
        )
    ),
])

# -----------------------------
# Run Dash App & Export HTML
# -----------------------------
import webbrowser
import os

if __name__ == "__main__":
    # Export a self-contained HTML file (can open locally)
    export_path = os.path.join(os.path.dirname(__file__), "student_dashboard.html")
    app.write_html(export_path, include_plotlyjs='cdn', full_html=True)
    print(f"✅ Exported dashboard to {export_path}")

    # Open browser automatically
    webbrowser.open("http://127.0.0.1:8050/")
    app.run(debug=True)