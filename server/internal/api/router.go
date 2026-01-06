package api

import "net/http"

func SetupRoutes(h *Handler) *http.ServeMux {
	mux := http.NewServeMux()

	mux.HandleFunc("/api/faculties", h.GetFaculties)
	mux.HandleFunc("/api/departments", h.GetDepartments)
	mux.HandleFunc("/api/courses", h.GetCourses)
	mux.HandleFunc("/api/course-detail", h.GetCourseDetail)

	return mux
}
