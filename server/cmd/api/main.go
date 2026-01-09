package main

import (
	"companion_server/internal/api"
	"companion_server/internal/storage"
	"fmt"
	"log"
	"net/http"
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

	port := ":8080"
	fmt.Printf("Sunucu %s portunda çalışıyor...\n", port)

	if err := http.ListenAndServe(port, router); err != nil {
		log.Fatal(err)
	}
}
