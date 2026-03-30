--DATA VALIDATION
-- Missing required fields
SELECT *
FROM students
WHERE grade_level IS NULL
   OR enrollment_status IS NULL;

--ATTENDANCE ANALYSIS
SELECT 
    s.school_id,
    COUNT(CASE WHEN a.status = 'Present' THEN 1 END) * 1.0 / COUNT(*) AS attendance_rate
FROM students s
JOIN attendance a ON s.student_id = a.student_id
GROUP BY s.school_id;

-- AT-RISK STUDENTS
SELECT 
    s.student_id,
    s.first_name,
    s.last_name,
    AVG(a.score) AS avg_score
FROM students s
JOIN assessments a ON s.student_id = a.student_id
GROUP BY s.student_id, s.first_name, s.last_name
HAVING AVG(a.score) < 70;

-- ELL PERFORMANCE ANALYSIS
SELECT 
    s.ell_status,
    AVG(a.score) AS avg_score
FROM students s
JOIN assessments a ON s.student_id = a.student_id
GROUP BY s.ell_status;

-- JOIN
SELECT 
    s.first_name,
    s.last_name,
    sc.school_name,
    AVG(a.score) AS avg_score
FROM students s
JOIN schools sc ON s.school_id = sc.school_id
JOIN assessments a ON s.student_id = a.student_id
GROUP BY s.first_name, s.last_name, sc.school_name;

-- VALIDATION QUERIES
-- Missing Students in Attendance
SELECT *
FROM attendance
WHERE student_id NOT IN (
    SELECT student_id FROM students
);

-- Duplicate Attendance Records
SELECT student_id, date, COUNT(*)
FROM attendance
GROUP BY student_id, date
HAVING COUNT(*) > 1;

-- Invalid Scores
SELECT *
FROM assessments
WHERE score < 0 OR score > 100;

-- Enrollment Integrity Check
SELECT *
FROM students
WHERE enrollment_status NOT IN ('Active', 'Inactive');

-- NEW VIEW (Student Summary)
CREATE VIEW student_summary AS
SELECT 
    s.student_id,
    s.first_name,
    s.last_name,
    sc.school_name,
    AVG(a.score) AS avg_score
FROM students s
JOIN schools sc ON s.school_id = sc.school_id
JOIN assessments a ON s.student_id = a.student_id
GROUP BY s.student_id, s.first_name, s.last_name, sc.school_name;