package api

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"strconv"

	"companion_server/internal/storage"
)

type Handler struct {
	DB *sql.DB
}

func NewHandler(db *sql.DB) *Handler {
	return &Handler{DB: db}
}

func respondJSON(w http.ResponseWriter, data interface{}) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(data)
}

// Tüm fakülteleri döner
func (h *Handler) GetFaculties(w http.ResponseWriter, r *http.Request) {
	faculties, err := storage.GetAllFaculties(h.DB)
	if err != nil {
		http.Error(w, "Failed to fetch faculties", http.StatusInternalServerError)
		return
	}
	respondJSON(w, faculties)
}

// Bütün bölümleri veya fakülte belirtilmişse fakülte bölümlerini döner
func (h *Handler) GetDepartments(w http.ResponseWriter, r *http.Request) {
	facultyIDStr := r.URL.Query().Get("faculty_id")

	if facultyIDStr != "" {
		facultyID, err := strconv.Atoi(facultyIDStr)
		if err != nil {
			http.Error(w, "Geçersiz faculty_id parametresi", http.StatusBadRequest)
			return
		}

		departments, err := storage.GetDepartmentsByFacultyID(h.DB, facultyID)
		if err != nil {
			http.Error(w, "Bölümler alınırken bir sıkıntı yaşandı", http.StatusInternalServerError)
			return
		}
		respondJSON(w, departments)
	} else {
		departments, err := storage.GetAllDepartments(h.DB)
		if err != nil {
			http.Error(w, "Bölümler alınırken bir sıkıntı yaşandı", http.StatusInternalServerError)
			return
		}
		respondJSON(w, departments)
	}
}

// Dersleri döner, bölüm guid ile çalışır.
func (h *Handler) GetCourses(w http.ResponseWriter, r *http.Request) {

	deptGUID := r.URL.Query().Get("id")

	if deptGUID == "" {
		http.Error(w, "id (department guid) parametresi zorunludur", http.StatusBadRequest)
		return
	}

	dept, err := storage.GetDepartmentByGUID(h.DB, deptGUID)
	if err != nil {
		http.Error(w, "Bölüm bulunamadı", http.StatusNotFound)
		return
	}

	data, err := storage.GetCoursesByDepartmentID(h.DB, dept.ID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	respondJSON(w, data)
}

// Ders detaylarını döner, ders kodu (BIMU..) ile çalışır
func (h *Handler) GetCourseDetail(w http.ResponseWriter, r *http.Request) {
	code := r.URL.Query().Get("code")

	if code == "" {
		http.Error(w, "code parametresi zorunludur", http.StatusBadRequest)
		return
	}

	data, err := storage.GetCourseDetail(h.DB, code)
	if err != nil {
		http.Error(w, "Ders detayı bulunamadı", http.StatusNotFound)
		return
	}
	respondJSON(w, data)
}
