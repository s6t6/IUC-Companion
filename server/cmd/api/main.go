package main

import (
	"companion_server/internal/api"
	"companion_server/internal/scraper"
	"fmt"
	"log"
	"net/http"
)

func main() {

	ebsService := scraper.NewService()

	handler := api.NewHandler(ebsService)

	router := api.SetupRoutes(handler)

	port := ":8080"
	fmt.Printf("Sunucu %s portunda çalışıyor...\n", port)

	if err := http.ListenAndServe(port, router); err != nil {
		log.Fatal(err)
	}
}
