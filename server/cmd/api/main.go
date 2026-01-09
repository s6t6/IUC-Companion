package main

import (
	"companion_server/internal/api"
	"companion_server/internal/storage"
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {

	// 1. DB Kurulumu
	db := storage.OpenDB()
	if err := storage.CreateTables(db); err != nil {
		log.Fatal("Tablo oluşturma hatası:", err)
	}

	// 2. Scraper & Scheduler Kurulumu (Her başlatmada uzun bi tarama yaptığı için çıkardım şimdilik. Veri DB'de mevcut.)
	//ebsService := scraper.NewService()
	//scheduler := tasks.NewScheduler(db, ebsService)
	//scheduler.Start(24 * time.Hour) // Scraper çalışma sıklığı

	// 3. API Handler Kurulumu
	handler := api.NewHandler(db)
	router := api.SetupRoutes(handler)

	port := os.Getenv("PORT")

	if port == "" {
		port = "8080"
	}

	addr := ":" + port

	fmt.Printf("Sunucu %s portunda çalışıyor...\n", addr)

	if err := http.ListenAndServe(addr, router); err != nil {
		log.Fatal(err)
	}
}
