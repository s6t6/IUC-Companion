package api

import (
	"companion_server/internal/scraper"
	"encoding/json"
	"net/http"
	"strconv"
	"time"
)

type Handler struct {
	Scraper *scraper.Service
}

func NewHandler(s *scraper.Service) *Handler {
	return &Handler{Scraper: s}
}

// Ortak JSON Responder
func respondJSON(w http.ResponseWriter, data interface{}) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(data)
}

func (h *Handler) GetDepartments(w http.ResponseWriter, r *http.Request) {
	data, err := h.Scraper.GetDepartments()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	respondJSON(w, data)
}

func (h *Handler) GetCourses(w http.ResponseWriter, r *http.Request) {
	deptID := r.URL.Query().Get("id")
	yearStr := r.URL.Query().Get("year")

	year, _ := strconv.Atoi(yearStr)
	if year == 0 {
		year = time.Now().Year()
	}

	if deptID == "" {
		http.Error(w, "id parametresi zorunludur", http.StatusBadRequest)
		return
	}

	data, err := h.Scraper.GetCourses(deptID, year)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	respondJSON(w, data)
}

func (h *Handler) GetCourseDetail(w http.ResponseWriter, r *http.Request) {
	id := r.URL.Query().Get("id")
	bid := r.URL.Query().Get("bid")

	if id == "" || bid == "" {
		http.Error(w, "id ve bid parametreleri zorunludur", http.StatusBadRequest)
		return
	}

	data, err := h.Scraper.GetCourseDetail(id, bid)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	respondJSON(w, data)
}
