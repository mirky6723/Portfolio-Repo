# ─────────────────────────────────────────────
# 📦 LOAD LIBRARIES
# ─────────────────────────────────────────────
library(reticulate)
library(tidyverse)
library(ggplot2)

# ─────────────────────────────────────────────
# 🔗 CONNECT TO PYTHON DATA
# ─────────────────────────────────────────────
source_python("student-data-pipeline-portfolio/python-r/main.py")

students <- py$students_df
attendance <- py$attendance_df
assessments <- py$assessments_df
schools <- py$schools_df

# ─────────────────────────────────────────────
# 🔧 DATA PREP
# ─────────────────────────────────────────────
data <- assessments %>%
  left_join(students, by = "student_id") %>%
  left_join(schools, by = "school_id") %>%
  mutate(
    EL_flag = ifelse(tolower(ell_status) == "yes", "EL", "Non-EL"),
    SPED_flag = ifelse(tolower(special_ed_flag) == "yes", "SPED", "Non-SPED"),
    grade_level = factor(grade_level),
    school_name = factor(school_name)
  )

attendance_data <- attendance %>%
  left_join(students, by = "student_id") %>%
  left_join(schools, by = "school_id") %>%
  mutate(
    EL_flag = ifelse(tolower(ell_status) == "yes", "EL", "Non-EL"),
    SPED_flag = ifelse(tolower(special_ed_flag) == "yes", "SPED", "Non-SPED"),
    absent_flag = ifelse(tolower(status) == "absent", 1, 0),
    tardy_flag = ifelse(tolower(status) == "tardy", 1, 0)
  )

# ─────────────────────────────────────────────
# ✅ FUNCTION: CLEAN SUMMARY TABLE (FOR CSV)
# ─────────────────────────────────────────────
create_summary_table <- function(df, group_var) {
  df %>%
    group_by({{group_var}}, subject) %>%
    summarise(
      n = n(),
      mean = round(mean(score),2),
      median = round(median(score),2),
      q1 = round(quantile(score, 0.25),2),
      q3 = round(quantile(score, 0.75),2),
      min = round(min(score),2),
      max = round(max(score),2),
      .groups = "drop"
    )
}

# ─────────────────────────────────────────────
# 🎨 FUNCTION: ADD STAT POINTS (FOR PLOT ONLY)
# ─────────────────────────────────────────────
add_stat_points <- function(df, group_var) {
  df %>%
    group_by({{group_var}}, subject) %>%
    summarise(
      q1 = quantile(score, 0.25),
      median = median(score),
      q3 = quantile(score, 0.75),
      min = min(score),
      max = max(score),
      mean = mean(score),
      .groups = "drop"
    ) %>%
    pivot_longer(cols = q1:max, names_to = "stat", values_to = "value")
}

# Shape mapping
shape_map <- c(
  q1 = 17,
  median = 16,
  q3 = 8,
  min = 95,
  max = 15,
  mean = 18
)

# ─────────────────────────────────────────────
# 🎨 GENERIC BOXPLOT FUNCTION
# ─────────────────────────────────────────────
create_boxplot <- function(df, group_var, title, filename, fill_colors) {
  
  stats_long <- add_stat_points(df, {{group_var}})
  
  p <- ggplot(df, aes(x = {{group_var}}, y = score, fill = {{group_var}})) +
    geom_boxplot(alpha = 0.6, outlier.shape = NA) +
    
    geom_jitter(aes(color = score), width = 0.2, size = 2) +
    scale_color_gradient2(low = "red", mid = "white", high = "green", midpoint = 75) +
    
    geom_point(
      data = stats_long,
      aes(x = {{group_var}}, y = value, shape = stat),
      size = 3,
      color = "black"
    ) +
    
    scale_shape_manual(values = shape_map) +
    scale_fill_manual(values = fill_colors) +
    
    facet_wrap(~subject) +
    
    labs(title = title, x = "", y = "Score") +
    theme_minimal() +
    theme(
      legend.position = "bottom",
      strip.text = element_text(face = "bold")
    )
  
  ggsave(filename, plot = p, width = 10, height = 6)
}

# ─────────────────────────────────────────────
# 📊 COLOR SCHEMES
# ─────────────────────────────────────────────
el_colors <- c("EL" = "lightgreen", "Non-EL" = "lightcoral")
sped_colors <- c("SPED" = "lightgreen", "Non-SPED" = "lightcoral")
grade_colors <- c("9" = "red", "10" = "blue", "11" = "green", "12" = "purple")
school_colors <- c(
  "Ventura High" = "red",
  "Oxnard High" = "blue",
  "Camarillo High" = "purple"
)

# ─────────────────────────────────────────────
# 📊 CREATE BOXPLOTS + SUMMARY TABLES
# ─────────────────────────────────────────────

create_boxplot(data, EL_flag, "EL vs Non-EL Scores", "el_vs_nonel.png", el_colors)
el_summary <- create_summary_table(data, EL_flag)

create_boxplot(data, SPED_flag, "SPED vs Non-SPED Scores", "sped_vs_nonsped.png", sped_colors)
sped_summary <- create_summary_table(data, SPED_flag)

create_boxplot(data, grade_level, "Scores by Grade", "grade_scores.png", grade_colors)
grade_summary <- create_summary_table(data, grade_level)

create_boxplot(data, school_name, "Scores by School", "school_scores.png", school_colors)
school_summary <- create_summary_table(data, school_name)

# ─────────────────────────────────────────────
# 📊 ATTENDANCE FUNCTION (UNCHANGED)
# ─────────────────────────────────────────────
create_attendance_chart <- function(df, group_var, title, filename) {
  
  summary <- df %>%
    group_by({{group_var}}) %>%
    summarise(
      avg_absent = mean(absent_flag),
      avg_tardy = mean(tardy_flag),
      .groups = "drop"
    ) %>%
    pivot_longer(cols = c(avg_absent, avg_tardy),
                 names_to = "type",
                 values_to = "value")
  
  p <- ggplot(summary, aes(x = {{group_var}}, y = value, fill = type)) +
    geom_col(position = "dodge") +
    geom_text(aes(label = round(value,2)),
              position = position_dodge(width = 0.9),
              vjust = -0.3) +
    scale_fill_manual(values = c("avg_absent" = "red", "avg_tardy" = "orange")) +
    theme_minimal() +
    labs(title = title, y = "Average per Student", x = "")
  
  ggsave(filename, plot = p, width = 10, height = 6)
  
  return(summary)
}

# Attendance
att_el <- create_attendance_chart(attendance_data, EL_flag, "Attendance: EL vs Non-EL", "att_el.png")
att_sped <- create_attendance_chart(attendance_data, SPED_flag, "Attendance: SPED vs Non-SPED", "att_sped.png")
att_grade <- create_attendance_chart(attendance_data, grade_level, "Attendance by Grade", "att_grade.png")
att_school <- create_attendance_chart(attendance_data, school_name, "Attendance by School", "att_school.png")

# ─────────────────────────────────────────────
# 💾 SAVE CLEAN CSVs
# ─────────────────────────────────────────────
write.csv(el_summary, "el_summary.csv", row.names = FALSE)
write.csv(sped_summary, "sped_summary.csv", row.names = FALSE)
write.csv(grade_summary, "grade_summary.csv", row.names = FALSE)
write.csv(school_summary, "school_summary.csv", row.names = FALSE)

write.csv(att_el, "att_el_summary.csv", row.names = FALSE)
write.csv(att_sped, "att_sped_summary.csv", row.names = FALSE)
write.csv(att_grade, "att_grade_summary.csv", row.names = FALSE)
write.csv(att_school, "att_school_summary.csv", row.names = FALSE)

cat("✅ Charts perfect + CSVs clean and structured!\n")