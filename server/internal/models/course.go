package models

// Ders
type Course struct {
	Code        string  `json:"code"`
	Name        string  `json:"name"`
	Credit      float64 `json:"credit"`
	ECTS        float64 `json:"ects"`
	IsMandatory bool    `json:"is_mandatory"`
	Theory      int     `json:"theory"`
	Practice    int     `json:"practice"`
	Lab         int     `json:"lab"`
	Semester    string  `json:"semester"`
	LinkID      string  `json:"link_id"`
	UnitID      string  `json:"unit_id"`
}

// Ders Detayları
type CourseDetail struct {
	BaseInfo   Course   `json:"base_info"`
	Instructor string   `json:"instructor"`
	Language   string   `json:"language"`
	Aim        string   `json:"aim"`
	Content    string   `json:"content"`
	Resources  string   `json:"resources"`
	Outcomes   []string `json:"outcomes"`
}
