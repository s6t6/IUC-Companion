package models

// Fakülte
type DepartmentNode struct {
	ID       int              `json:"id" db:"department_id"`
	Text     string           `json:"text" db:"department_name"`
	ParentID int              `json:"ustbirimid" db:"parent_department_id"`
	GUID     string           `json:"guid" db:"department_guid"`
	Nodes    []DepartmentNode `json:"nodes"`
}
