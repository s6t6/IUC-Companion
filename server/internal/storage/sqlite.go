package storage

import (
	"database/sql"
	"log"

	_ "github.com/mattn/go-sqlite3"
)

func OpenDB() *sql.DB {
	db, err := sql.Open("sqlite3", "./data.db")
	if err != nil {
		log.Fatal("SQLite açılırken hata:", err)
	}

	if err := db.Ping(); err != nil {
		log.Fatal("SQLite bağlantı hatası:", err)
	}

	return db
}
