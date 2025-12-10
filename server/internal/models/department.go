package models

// Fakülte
type DepartmentNode struct {
	ID       int              `json:"id"`
	Text     string           `json:"text"`
	ParentID int              `json:"ustbirimid"`
	GUID     string           `json:"guid"`
	Nodes    []DepartmentNode `json:"nodes"`
}
