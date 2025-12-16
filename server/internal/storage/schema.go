package storage

import "database/sql"

func CreateTables(db *sql.DB) error {


	departmentTable := `
	CREATE TABLE IF NOT EXISTS departments (
		department_id INTEGER PRIMARY KEY,
		department_name TEXT NOT NULL,
		department_parent_id INTEGER,
		department_guid TEXT
	);`


	courseTable := `
	CREATE TABLE IF NOT EXISTS courses (
		course_code TEXT PRIMARY KEY,
		course_name TEXT NOT NULL,
		credit REAL,
		ects REAL,
		is_mandatory BOOLEAN,
		theory_hours INTEGER,
		practice_hours INTEGER,
		lab_hours INTEGER,
		semester TEXT,
		link_id TEXT,
		unit_id TEXT
	);`

	courseDetailTable := `
	CREATE TABLE IF NOT EXISTS course_details (
		course_code TEXT PRIMARY KEY,
		instructor TEXT,
		language TEXT,
		aim TEXT,
		content TEXT,
		resources TEXT,
		outcomes TEXT,
		FOREIGN KEY (course_code) REFERENCES courses(course_code)
	);`

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
