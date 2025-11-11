-- Pending approvals
SELECT lr.request_id, e.emp_code, CONCAT(e.first_name,' ',e.last_name) AS employee, d.name AS department,
       lt.name AS leave_type, lr.start_date, lr.end_date, lr.days, lr.applied_at
FROM leave_requests lr
JOIN employees e ON lr.emp_id=e.emp_id
JOIN leave_types lt ON lr.leave_type_id=lt.leave_type_id
LEFT JOIN departments d ON e.dept_id=d.dept_id
WHERE lr.status='Applied'
ORDER BY lr.applied_at;

-- Monthly summary (for March 2025)
SELECT lt.name AS leave_type, SUM(lr.days) AS total_days, COUNT(*) AS requests
FROM leave_requests lr
JOIN leave_types lt ON lr.leave_type_id=lt.leave_type_id
WHERE MONTH(lr.start_date)=3 AND YEAR(lr.start_date)=2025 AND lr.status='Approved'
GROUP BY lt.leave_type_id;

-- Employee yearly summary
SELECT e.emp_code, CONCAT(e.first_name,' ',e.last_name) AS employee, lt.name AS leave_type, SUM(lr.days) AS days_taken
FROM leave_requests lr
JOIN employees e ON lr.emp_id=e.emp_id
JOIN leave_types lt ON lr.leave_type_id=lt.leave_type_id
WHERE YEAR(lr.start_date)=2025 AND lr.status='Approved'
GROUP BY e.emp_id, lt.leave_type_id
ORDER BY days_taken DESC;
