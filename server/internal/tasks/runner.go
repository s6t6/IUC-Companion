package tasks

import (
	"context"
	"database/sql"
	"log"
	"time"

	"companion_server/internal/scraper"
	"companion_server/internal/storage"
)

const (
	BackfillYears = 7
)

func RunScraper(ctx context.Context, db *sql.DB, s *scraper.Service) {
	log.Println("Tarama işlemi başlatılıyor...")

	faculties, departments, err := s.GetStructure()
	if err != nil {
		log.Printf("Hata: %v", err)
		return
	}

	log.Printf(" %d fakülte ve %d bölüm bulundu. Kaydediliyor...", len(faculties), len(departments))

	for _, f := range faculties {
		storage.InsertFaculty(db, f)
	}
	for _, d := range departments {
		storage.InsertDepartment(db, d)
	}

	now := time.Now()
	currentAcademicYear := now.Year()

	// Eylülden önceyse bir önceki yılı baz al (Akademik yıl için)
	if now.Month() < time.September {
		currentAcademicYear = currentAcademicYear - 1
	}

	endYear := currentAcademicYear - BackfillYears

	validDetailsMap, err := storage.GetCoursesWithValidDetails(db)
	if err != nil {
		validDetailsMap = make(map[string]bool)
	}

	log.Printf("%d'dan %d'e kadar olan EBS verisi taranıyor...", currentAcademicYear, endYear)

	for _, d := range departments {
		select {
		case <-ctx.Done():
			return
		default:
		}

		if d.GUID == "" {
			continue
		}

		// Bulunan dersleri tutacağımız map. Yeniden eskiye gittiğimiz için ilk bulunan en doğru.
		existingCoursesMap, _ := storage.GetExistingCourseCodes(db, d.ID)

		for year := currentAcademicYear; year >= endYear; year-- {
			select {
			case <-ctx.Done():
				return
			default:
			}

			time.Sleep(100 * time.Millisecond)

			courses, err := s.GetCourses(d.GUID, year)
			if err != nil {
				log.Printf("%s (%d) için taramada hata oluştu : %v", d.Name, year, err)
				continue
			}

			if len(courses) == 0 {
				continue
			}

			for _, c := range courses {
				c.DepartmentID = d.ID
				c.Year = year

				// Ders kodu güncel yılda yoksa ders kaldırılmıştır.
				if year < currentAcademicYear {
					c.IsRemoved = true
				} else {
					c.IsRemoved = false
				}

				if !existingCoursesMap[c.Code] {
					if err := storage.InsertCourse(db, c, d.ID); err != nil {
						log.Printf("%s dersi eklenirken hata: %v", c.Code, err)
					} else {
						existingCoursesMap[c.Code] = true
					}
				}

				// Güncelde detay yoksa bir önceki senelerden alınır
				if !validDetailsMap[c.Code] {
					if c.LinkID != "" && c.UnitID != "" {
						detail, err := s.GetCourseDetail(c.LinkID, c.UnitID)
						if err == nil {
							if detail.BaseInfo.Code == "" {
								detail.BaseInfo.Code = c.Code
							}

							if detail.HasContent() {
								if err := storage.InsertCourseDetail(db, *detail); err == nil {
									validDetailsMap[c.Code] = true
								}
							}
						}
						time.Sleep(50 * time.Millisecond)
					}
				}
			}
		}
	}

	log.Println("Tarama tamamlandı.")
}
