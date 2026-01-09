package storage

import (
	"database/sql"
	"encoding/json"
	"fmt"

	"companion_server/internal/models"
)

func GetExistingCourseCodes(db *sql.DB, departmentID int) (map[string]bool, error) {
	rows, err := db.Query("SELECT course_code FROM courses WHERE department_id = ?", departmentID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	exists := make(map[string]bool)
	for rows.Next() {
		var code string
		if err := rows.Scan(&code); err == nil {
			exists[code] = true
		}
	}
	return exists, nil
}

func GetCoursesWithValidDetails(db *sql.DB) (map[string]bool, error) {
	rows, err := db.Query("SELECT course_code FROM course_details WHERE length(aim) > 0 OR length(content) > 0")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	exists := make(map[string]bool)
	for rows.Next() {
		var code string
		if err := rows.Scan(&code); err == nil {
			exists[code] = true
		}
	}
	return exists, nil
}

func InsertFaculty(db *sql.DB, f models.Faculty) error {
	_, err := db.Exec(`
		INSERT OR REPLACE INTO faculties
		(faculty_id, faculty_guid, faculty_name, faculty_name_en)
		VALUES (?, ?, ?, ?)`,
		f.ID, f.GUID, f.Name, f.NameEn,
	)
	return err
}

func GetAllFaculties(db *sql.DB) ([]models.Faculty, error) {
	rows, err := db.Query(`SELECT faculty_id, faculty_guid, faculty_name, faculty_name_en FROM faculties`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var faculties []models.Faculty
	for rows.Next() {
		var f models.Faculty
		if err := rows.Scan(&f.ID, &f.GUID, &f.Name, &f.NameEn); err != nil {
			return nil, err
		}
		faculties = append(faculties, f)
	}
	return faculties, nil
}

func InsertDepartment(db *sql.DB, d models.Department) error {
	_, err := db.Exec(`
		INSERT OR REPLACE INTO departments
		(department_id, faculty_id, department_guid, department_name, department_name_en)
		VALUES (?, ?, ?, ?, ?)`,
		d.ID, d.FacultyID, d.GUID, d.Name, d.NameEn,
	)
	return err
}

func GetAllDepartments(db *sql.DB) ([]models.Department, error) {
	rows, err := db.Query(`SELECT department_id, faculty_id, department_guid, department_name, department_name_en FROM departments`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var departments []models.Department
	for rows.Next() {
		var d models.Department
		if err := rows.Scan(&d.ID, &d.FacultyID, &d.GUID, &d.Name, &d.NameEn); err != nil {
			return nil, err
		}
		departments = append(departments, d)
	}
	return departments, nil
}

func GetDepartmentsByFacultyID(db *sql.DB, facultyID int) ([]models.Department, error) {
	rows, err := db.Query(`
		SELECT department_id, faculty_id, department_guid, department_name, department_name_en 
		FROM departments 
		WHERE faculty_id = ?`, facultyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var departments []models.Department
	for rows.Next() {
		var d models.Department
		if err := rows.Scan(&d.ID, &d.FacultyID, &d.GUID, &d.Name, &d.NameEn); err != nil {
			return nil, err
		}
		departments = append(departments, d)
	}
	return departments, nil
}

func GetDepartmentByGUID(db *sql.DB, guid string) (*models.Department, error) {
	row := db.QueryRow(`
		SELECT department_id, faculty_id, department_guid, department_name, department_name_en 
		FROM departments 
		WHERE department_guid = ?`, guid)

	var d models.Department
	if err := row.Scan(&d.ID, &d.FacultyID, &d.GUID, &d.Name, &d.NameEn); err != nil {
		return nil, err
	}
	return &d, nil
}

func InsertCourse(db *sql.DB, c models.Course, departmentID int) error {
	_, err := db.Exec(`
		INSERT OR REPLACE INTO courses
		(course_code, department_id, course_name, credit, ects, is_mandatory,
		 theory_hours, practice_hours, lab_hours, semester, link_id, unit_id, year, is_removed)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		c.Code, departmentID, c.Name, c.Credit, c.ECTS, c.IsMandatory,
		c.Theory, c.Practice, c.Lab, c.Semester, c.LinkID, c.UnitID, c.Year, c.IsRemoved,
	)
	return err
}

func GetCoursesByDepartmentID(db *sql.DB, departmentID int) ([]models.Course, error) {
	rows, err := db.Query(`
		SELECT
			course_code, department_id, course_name, credit, ects, is_mandatory,
			theory_hours, practice_hours, lab_hours,
			semester, link_id, unit_id, year, is_removed
		FROM courses
		WHERE department_id = ?`, departmentID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var courses []models.Course
	for rows.Next() {
		var c models.Course
		if err := rows.Scan(
			&c.Code, &c.DepartmentID, &c.Name, &c.Credit, &c.ECTS, &c.IsMandatory,
			&c.Theory, &c.Practice, &c.Lab, &c.Semester, &c.LinkID, &c.UnitID,
			&c.Year, &c.IsRemoved,
		); err != nil {
			return nil, err
		}
		courses = append(courses, c)
	}
	return courses, nil
}

func InsertCourseDetail(db *sql.DB, d models.CourseDetail) error {
	outcomesJSON, err := json.Marshal(d.Outcomes)
	if err != nil {
		return err
	}

	_, err = db.Exec(`
		INSERT OR REPLACE INTO course_details
		(course_code, instructor, language, aim, content, resources, outcomes)
		VALUES (?, ?, ?, ?, ?, ?, ?)`,
		d.BaseInfo.Code, d.Instructor, d.Language, d.Aim, d.Content, d.Resources, string(outcomesJSON),
	)

	return err
}

func GetCourseDetail(db *sql.DB, courseCode string) (*models.CourseDetail, error) {
	row := db.QueryRow(`
		SELECT
			c.course_code, c.course_name, c.credit, c.ects, c.is_mandatory,
			c.theory_hours, c.practice_hours, c.lab_hours,
			c.semester, c.link_id, c.unit_id,
			c.department_id, c.year, c.is_removed,
			d.instructor, d.language, d.aim, d.content, d.resources, d.outcomes
		FROM courses c
		JOIN course_details d ON c.course_code = d.course_code
		WHERE c.course_code = ?
		ORDER BY c.year DESC, c.is_removed ASC
		LIMIT 1`,
		courseCode,
	)

	var detail models.CourseDetail
	var outcomesJSON string

	err := row.Scan(
		&detail.BaseInfo.Code,
		&detail.BaseInfo.Name,
		&detail.BaseInfo.Credit,
		&detail.BaseInfo.ECTS,
		&detail.BaseInfo.IsMandatory,
		&detail.BaseInfo.Theory,
		&detail.BaseInfo.Practice,
		&detail.BaseInfo.Lab,
		&detail.BaseInfo.Semester,
		&detail.BaseInfo.LinkID,
		&detail.BaseInfo.UnitID,
		&detail.BaseInfo.DepartmentID,
		&detail.BaseInfo.Year,
		&detail.BaseInfo.IsRemoved,
		&detail.Instructor,
		&detail.Language,
		&detail.Aim,
		&detail.Content,
		&detail.Resources,
		&outcomesJSON,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("ders bulunamadı ya da ders detayı mevcut değil")
		}
		return nil, err
	}

	_ = json.Unmarshal([]byte(outcomesJSON), &detail.Outcomes)

	return &detail, nil
}
