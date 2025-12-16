package storage

import (
	"database/sql"
	"encoding/json"

	"server/internal/models"
)

//
// ==============================
// DEPARTMENT REPOSITORY
// ==============================
//

// InsertDepartment tek bir department kaydı ekler / günceller
func InsertDepartment(db *sql.DB, d models.DepartmentNode) error {
	_, err := db.Exec(`
		INSERT OR REPLACE INTO departments
		(department_id, department_name, department_parent_id, department_guid)
		VALUES (?, ?, ?, ?)`,
		d.ID,
		d.Text,
		d.ParentID,
		d.GUID,
	)
	return err
}

// GetAllDepartments tüm department kayıtlarını flat liste olarak döner
func GetAllDepartments(db *sql.DB) ([]models.DepartmentNode, error) {
	rows, err := db.Query(`
		SELECT department_id, department_name, department_parent_id, department_guid
		FROM departments`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var departments []models.DepartmentNode

	for rows.Next() {
		var d models.DepartmentNode
		if err := rows.Scan(
			&d.ID,
			&d.Text,
			&d.ParentID,
			&d.GUID,
		); err != nil {
			return nil, err
		}
		departments = append(departments, d)
	}

	return departments, nil
}

//
// ==============================
// COURSE REPOSITORY
// ==============================
//

// InsertCourse course tablosuna kayıt ekler / günceller
func InsertCourse(db *sql.DB, c models.Course) error {
	_, err := db.Exec(`
		INSERT OR REPLACE INTO courses
		(course_code, course_name, credit, ects, is_mandatory,
		 theory_hours, practice_hours, lab_hours,
		 semester, link_id, unit_id)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		c.Code,
		c.Name,
		c.Credit,
		c.ECTS,
		c.IsMandatory,
		c.Theory,
		c.Practice,
		c.Lab,
		c.Semester,
		c.LinkID,
		c.UnitID,
	)
	return err
}

// GetCourse course_code ile tek bir course döner
func GetCourse(db *sql.DB, courseCode string) (*models.Course, error) {
	row := db.QueryRow(`
		SELECT
			course_code, course_name, credit, ects, is_mandatory,
			theory_hours, practice_hours, lab_hours,
			semester, link_id, unit_id
		FROM courses
		WHERE course_code = ?`,
		courseCode,
	)

	var c models.Course
	err := row.Scan(
		&c.Code,
		&c.Name,
		&c.Credit,
		&c.ECTS,
		&c.IsMandatory,
		&c.Theory,
		&c.Practice,
		&c.Lab,
		&c.Semester,
		&c.LinkID,
		&c.UnitID,
	)
	if err != nil {
		return nil, err
	}

	return &c, nil
}

// GetAllCourses tüm course kayıtlarını döner
func GetAllCourses(db *sql.DB) ([]models.Course, error) {
	rows, err := db.Query(`
		SELECT
			course_code, course_name, credit, ects, is_mandatory,
			theory_hours, practice_hours, lab_hours,
			semester, link_id, unit_id
		FROM courses`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var courses []models.Course

	for rows.Next() {
		var c models.Course
		if err := rows.Scan(
			&c.Code,
			&c.Name,
			&c.Credit,
			&c.ECTS,
			&c.IsMandatory,
			&c.Theory,
			&c.Practice,
			&c.Lab,
			&c.Semester,
			&c.LinkID,
			&c.UnitID,
		); err != nil {
			return nil, err
		}
		courses = append(courses, c)
	}

	return courses, nil
}

//
// ==============================
// COURSE DETAIL REPOSITORY
// ==============================
//

// InsertCourseDetail course_details tablosuna kayıt ekler / günceller
func InsertCourseDetail(db *sql.DB, d models.CourseDetail) error {

	outcomesJSON, err := json.Marshal(d.Outcomes)
	if err != nil {
		return err
	}

	_, err = db.Exec(`
		INSERT OR REPLACE INTO course_details
		(course_code, instructor, language, aim, content, resources, outcomes)
		VALUES (?, ?, ?, ?, ?, ?, ?)`,
		d.BaseInfo.Code,
		d.Instructor,
		d.Language,
		d.Aim,
		d.Content,
		d.Resources,
		string(outcomesJSON),
	)

	return err
}

// GetCourseDetail course + course_detail JOIN ederek döner
func GetCourseDetail(db *sql.DB, courseCode string) (*models.CourseDetail, error) {

	row := db.QueryRow(`
		SELECT
			c.course_code, c.course_name, c.credit, c.ects, c.is_mandatory,
			c.theory_hours, c.practice_hours, c.lab_hours,
			c.semester, c.link_id, c.unit_id,
			d.instructor, d.language, d.aim, d.content, d.resources, d.outcomes
		FROM courses c
		JOIN course_details d ON c.course_code = d.course_code
		WHERE c.course_code = ?`,
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
		&detail.Instructor,
		&detail.Language,
		&detail.Aim,
		&detail.Content,
		&detail.Resources,
		&outcomesJSON,
	)
	if err != nil {
		return nil, err
	}

	_ = json.Unmarshal([]byte(outcomesJSON), &detail.Outcomes)

	return &detail, nil
}
