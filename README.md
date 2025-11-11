# Employee Leave Management System (SQL Backend)

**Author:** Pradipta Banerjee  
**Contact:** banerjeepradipta47@gmail.com | +91-7003385912

## Overview
Relational database implementation to manage employees, leave types, leave requests, approvals and leave balances.

## Components
- `schema_and_sample_data.sql` — create tables, indexes, sample data, and stored procedures.
- `reports_examples.sql` — pre-written reports (pending approvals, monthly summary, yearly summary).
- `ER_diagram.png` — (not included) database ER diagram (optional).
- `project_summary.pdf` — one-page executive summary (optional).

## Setup
1. Install MySQL (or MariaDB).
2. Create database: `CREATE DATABASE emp_leave;`
3. Run: `mysql -u <user> -p emp_leave < schema_and_sample_data.sql`
4. Run sample reports: `mysql -u <user> -p emp_leave < reports_examples.sql`

## Key Features
- Employee CRUD and department mapping.
- Leave application with validation against balances.
- Approval workflow (Manager approves/rejects).
- Automatic leave balance adjustments on approval.
- Reports: Pending Approvals, Monthly Summary, Employee Yearly Summary.
- Audit trail for requests (created_by, created_at, updated_by, updated_at).

## Assumptions
- Leave accrual happens yearly; leave types and accrual rules are simplified.
- Manager approvals are represented by `approver_id` on LeaveRequests.


