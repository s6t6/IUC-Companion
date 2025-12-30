package models

// Ders
type Course struct {
	Code        string  `json:"code" db:"course_code"`
	Name        string  `json:"name" db:"course_name"`
	Credit      float64 `json:"credit" db:"credit"`
	ECTS        float64 `json:"ects" db:"ects"`
	IsMandatory bool    `json:"is_mandatory" db:"is_mandatory"`
	Theory      int     `json:"theory" db:"theory_hours"`
	Practice    int     `json:"practice" db:"practice_hours"`
	Lab         int     `json:"lab" db:"lab_hours"`
	Semester    string  `json:"semester" db:"semester"`
	LinkID      string  `json:"link_id" db:"link_id"`
	UnitID      string  `json:"unit_id" db:"unit_id"`
}

// Ders Detayları
type CourseDetail struct {
	BaseInfo   Course   `json:"base_info"  `
	Instructor string   `json:"instructor" db:"instructor"`
	Language   string   `json:"language" db:"language"`
	Aim        string   `json:"aim" db:"aim"`
	Content    string   `json:"content" db:"content"`
	Resources  string   `json:"resources" db:"resources"`
	Outcomes   []string `json:"outcomes" db:"outcomes"`
}
