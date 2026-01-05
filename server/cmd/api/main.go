package main

import (
	"companion_server/internal/api"
	"companion_server/internal/scraper"
	"companion_server/internal/storage" 
	"fmt"
	"log"
	"net/http"
)

func main() {


	db := storage.OpenDB() 
	defer db.Close()       

	if err := storage.CreateTables(db); err != nil { 
		log.Fatal("Veritabanı tabloları oluşturulamadı:", err) 
	}

	ebsService := scraper.NewService()

	handler := api.NewHandler(ebsService, db) 

	router := api.SetupRoutes(handler)

	port := ":8080"
	fmt.Printf("Sunucu %s portunda çalışıyor...\n", port)

	if err := http.ListenAndServe(port, router); err != nil {
		log.Fatal(err)
	}
}
