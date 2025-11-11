-- Employee Leave Management: schema + sample data + procedures
-- Run on MySQL 5.7+ / 8.0+

DROP DATABASE IF EXISTS emp_leave;
CREATE DATABASE emp_leave;
USE emp_leave;

-- Departments
CREATE TABLE departments (
  dept_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Employees
CREATE TABLE employees (
  emp_id INT AUTO_INCREMENT PRIMARY KEY,
  emp_code VARCHAR(20) NOT NULL UNIQUE,
  first_name VARCHAR(50),
  last_name VARCHAR(50),
  email VARCHAR(100) UNIQUE,
  dept_id INT,
  manager_id INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (dept_id) REFERENCES departments(dept_id),
  FOREIGN KEY (manager_id) REFERENCES employees(emp_id)
);

-- Leave types (e.g., Paid Leave, Sick Leave)
CREATE TABLE leave_types (
  leave_type_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL,
  annual_entitlement DECIMAL(5,2) NOT NULL, -- days per year
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Leave balances (per employee per leave type)
CREATE TABLE leave_balances (
  emp_id INT,
  leave_type_id INT,
  year INT,
  balance DECIMAL(6,2) DEFAULT 0,
  PRIMARY KEY (emp_id, leave_type_id, year),
  FOREIGN KEY (emp_id) REFERENCES employees(emp_id),
  FOREIGN KEY (leave_type_id) REFERENCES leave_types(leave_type_id)
);

-- Leave requests
CREATE TABLE leave_requests (
  request_id INT AUTO_INCREMENT PRIMARY KEY,
  emp_id INT NOT NULL,
  leave_type_id INT NOT NULL,
  start_date DATE,
  end_date DATE,
  days DECIMAL(5,2),
  reason VARCHAR(500),
  status ENUM('Applied','Approved','Rejected','Cancelled') DEFAULT 'Applied',
  approver_id INT,
  applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL,
  FOREIGN KEY (emp_id) REFERENCES employees(emp_id),
  FOREIGN KEY (leave_type_id) REFERENCES leave_types(leave_type_id),
  FOREIGN KEY (approver_id) REFERENCES employees(emp_id)
);

-- Audit (simple)
CREATE TABLE leave_audit (
  audit_id INT AUTO_INCREMENT PRIMARY KEY,
  request_id INT,
  action VARCHAR(50),
  action_by INT,
  action_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  comments VARCHAR(500),
  FOREIGN KEY (request_id) REFERENCES leave_requests(request_id),
  FOREIGN KEY (action_by) REFERENCES employees(emp_id)
);

-- Indexes for frequent queries
CREATE INDEX idx_leave_status ON leave_requests(status);
CREATE INDEX idx_emp_dept ON employees(dept_id);

-- Sample data
INSERT INTO departments (name) VALUES ('Engineering'), ('HR'), ('Sales');

INSERT INTO employees (emp_code, first_name, last_name, email, dept_id, manager_id)
VALUES
('E1001','Amit','Kumar','amit.kumar@example.com',1,NULL),
('E1002','Neha','Roy','neha.roy@example.com',1,1),
('E1003','Ravi','Sharma','ravi.sharma@example.com',2,NULL),
('E1004','Sana','Patel','sana.patel@example.com',1,1);

INSERT INTO leave_types (name, annual_entitlement)
VALUES ('Paid Leave', 18), ('Sick Leave', 10), ('Casual Leave', 8);

-- Initialize balances for year 2025
INSERT INTO leave_balances (emp_id, leave_type_id, year, balance)
SELECT e.emp_id, lt.leave_type_id, 2025, lt.annual_entitlement
FROM employees e CROSS JOIN leave_types lt;

-- Sample leave requests
INSERT INTO leave_requests (emp_id, leave_type_id, start_date, end_date, days, reason, status, approver_id)
VALUES
(2, 1, '2025-03-10', '2025-03-12', 3, 'Family function', 'Applied', 1),
(4, 2, '2025-04-05', '2025-04-05', 1, 'Medical visit', 'Approved', 1);

-- Procedures: apply for leave (validates balance)
DELIMITER //
CREATE PROCEDURE apply_leave(
  IN p_emp_id INT,
  IN p_leave_type_id INT,
  IN p_start DATE,
  IN p_end DATE,
  IN p_reason VARCHAR(500),
  IN p_approver INT
)
BEGIN
  DECLARE v_days DECIMAL(6,2);
  DECLARE v_balance DECIMAL(6,2);
  DECLARE v_year INT;
  SET v_year = YEAR(p_start);
  SET v_days = DATEDIFF(p_end, p_start) + 1;
  SELECT balance INTO v_balance FROM leave_balances WHERE emp_id=p_emp_id AND leave_type_id=p_leave_type_id AND year=v_year;
  IF v_balance IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No balance record found for this year';
  ELSEIF v_balance < v_days THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient leave balance';
  ELSE
    INSERT INTO leave_requests (emp_id, leave_type_id, start_date, end_date, days, reason, status, approver_id)
    VALUES (p_emp_id, p_leave_type_id, p_start, p_end, v_days, p_reason, 'Applied', p_approver);
    INSERT INTO leave_audit (request_id, action, action_by, comments)
    VALUES (LAST_INSERT_ID(), 'Applied', p_emp_id, 'Auto-recorded');
  END IF;
END;
//
DELIMITER ;

-- Procedure: approve leave (deducts balance)
DELIMITER //
CREATE PROCEDURE approve_leave(IN p_request_id INT, IN p_approver INT)
BEGIN
  DECLARE v_emp INT;
  DECLARE v_type INT;
  DECLARE v_days DECIMAL(6,2);
  DECLARE v_year INT;
  SELECT emp_id, leave_type_id, days, start_date INTO v_emp, v_type, v_days, @sdate FROM leave_requests WHERE request_id=p_request_id;
  SET v_year = YEAR(@sdate);
  -- Deduct balance
  UPDATE leave_balances SET balance = balance - v_days WHERE emp_id=v_emp AND leave_type_id=v_type AND year=v_year;
  -- Update request
  UPDATE leave_requests SET status='Approved', updated_at=NOW(), approver_id=p_approver WHERE request_id=p_request_id;
  -- Audit
  INSERT INTO leave_audit (request_id, action, action_by, comments) VALUES (p_request_id, 'Approved', p_approver, NULL);
END;
//
DELIMITER ;

-- Example report: pending approvals
-- SELECT lr.request_id, e.emp_code, CONCAT(e.first_name,' ',e.last_name) AS employee, lt.name AS leave_type, lr.start_date, lr.end_date, lr.days
-- FROM leave_requests lr
-- JOIN employees e ON lr.emp_id=e.emp_id
-- JOIN leave_types lt ON lr.leave_type_id=lt.leave_type_id
-- WHERE lr.status='Applied';
