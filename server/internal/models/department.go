package models

// Fakülte
type Faculty struct {
	ID     int    `json:"id" db:"faculty_id"`
	GUID   string `json:"guid" db:"faculty_guid"`
	Name   string `json:"text" db:"faculty_name"`
	NameEn string `json:"textEn" db:"faculty_name_en"`
}

// Bölüm
type Department struct {
	ID        int    `json:"id" db:"department_id"`
	FacultyID int    `json:"ustbirimid" db:"faculty_id"`
	GUID      string `json:"guid" db:"department_guid"`
	Name      string `json:"text" db:"department_name"`
	NameEn    string `json:"textEn" db:"department_name_en"`
}
