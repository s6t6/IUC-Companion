package tasks

import (
	"companion_server/internal/scraper"
	"context"
	"database/sql"
	"log"
	"time"
)

// Belirli aralıklarla EBS'yi tarama işlemini başlatır
type Scheduler struct {
	db      *sql.DB
	scraper *scraper.Service
	ticker  *time.Ticker
	quit    chan struct{}
}

func NewScheduler(db *sql.DB, s *scraper.Service) *Scheduler {
	return &Scheduler{
		db:      db,
		scraper: s,
		quit:    make(chan struct{}),
	}
}

func (s *Scheduler) Start(interval time.Duration) {
	s.ticker = time.NewTicker(interval)

	log.Printf("Scheduler başlatıldı. Tarama şu aralıklarla yapılacak: %v ", interval)

	ctx, cancel := context.WithCancel(context.Background())

	// Başlatıldığında hemen çalış
	go func() {
		log.Println("İlk tarama gerçekleştiriliyor...")
		RunScraper(ctx, s.db, s.scraper)
	}()

	go func() {
		for {
			select {
			case <-s.ticker.C:
				log.Println("Zamanlanan tarama işlemi başlatılıyor...")
				RunScraper(ctx, s.db, s.scraper)
			case <-s.quit:
				s.ticker.Stop()
				cancel()
				return
			}
		}
	}()
}

func (s *Scheduler) Stop() {
	close(s.quit)
	log.Println("Scheduler çalışmayı durdurdu.")
}
