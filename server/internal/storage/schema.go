package storage

import "database/sql"

func CreateTables(db *sql.DB) error {

	facultyTable := `
	CREATE TABLE IF NOT EXISTS faculties (
		faculty_id INTEGER PRIMARY KEY,
		faculty_guid TEXT,
		faculty_name TEXT NOT NULL,
		faculty_name_en TEXT
	);`

	departmentTable := `
	CREATE TABLE IF NOT EXISTS departments (
		department_id INTEGER PRIMARY KEY,
		faculty_id INTEGER,
		department_guid TEXT,
		department_name TEXT NOT NULL,
		department_name_en TEXT,
		FOREIGN KEY(faculty_id) REFERENCES faculties(faculty_id)
	);`

	courseTable := `
	CREATE TABLE IF NOT EXISTS courses (
		course_code TEXT,
		department_id INTEGER,
		course_name TEXT NOT NULL,
		credit REAL,
		ects REAL,
		is_mandatory BOOLEAN,
		theory_hours INTEGER,
		practice_hours INTEGER,
		lab_hours INTEGER,
		semester TEXT,
		link_id TEXT,
		unit_id TEXT,
		year INTEGER,
		is_removed BOOLEAN DEFAULT 0,
		PRIMARY KEY (course_code, department_id),
		FOREIGN KEY(department_id) REFERENCES departments(department_id)
	);`

	courseDetailTable := `
	CREATE TABLE IF NOT EXISTS course_details (
		course_code TEXT PRIMARY KEY,
		instructor TEXT,
		language TEXT,
		aim TEXT,
		content TEXT,
		resources TEXT,
		outcomes TEXT
	);`

	if _, err := db.Exec(facultyTable); err != nil {
		return err
	}
	if _, err := db.Exec(departmentTable); err != nil {
		return err
	}
	if _, err := db.Exec(courseTable); err != nil {
		return err
	}
	if _, err := db.Exec(courseDetailTable); err != nil {
		return err
	}

	return nil
}
