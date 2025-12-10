package scraper

import (
	"companion_server/internal/models"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strconv"
	"strings"

	"github.com/PuerkitoBio/goquery"
)

// Service: Scraping metodlarını barındırıyor.
type Service struct {
	BaseURL string
}

func NewService() *Service {
	return &Service{
		BaseURL: "https://ebs.iuc.edu.tr",
	}
}

func (s *Service) GetDepartments() ([]models.DepartmentNode, error) {
	apiURL := s.BaseURL + "/home/getdata/?id=OStuSxOSf%2f8%3d"
	resp, err := http.Get(apiURL)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var nodes []models.DepartmentNode
	if err := json.NewDecoder(resp.Body).Decode(&nodes); err != nil {
		return nil, err
	}
	return nodes, nil
}

func (s *Service) GetCourses(deptGUID string, year int) ([]models.Course, error) {
	targetURL := fmt.Sprintf("%s/home/dersprogram/?id=%s&yil=%d", s.BaseURL, url.QueryEscape(deptGUID), year)

	resp, err := http.Get(targetURL)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	doc, err := goquery.NewDocumentFromReader(resp.Body)
	if err != nil {
		return nil, err
	}

	var courses []models.Course
	var currentSemester string

	doc.Find(".panel-body").Children().Each(func(i int, s *goquery.Selection) {
		if s.Is("h4") {
			currentSemester = CleanText(s.Text())
		} else if s.Is("table") && currentSemester != "" {
			s.Find("tbody tr").Each(func(j int, tr *goquery.Selection) {
				c := models.Course{Semester: currentSemester}

				tr.Find("td").Each(func(k int, td *goquery.Selection) {
					txt := CleanText(td.Text())
					switch k {
					case 0:
						c.Code = txt
					case 1:
						c.Name = txt
						if href, exists := td.Find("a").Attr("href"); exists {
							u, _ := url.Parse(href)
							c.LinkID = u.Query().Get("id")
							c.UnitID = u.Query().Get("bid")
						}
					case 2:
						c.Credit, _ = strconv.ParseFloat(txt, 64)
					case 3:
						c.ECTS, _ = strconv.ParseFloat(txt, 64)
					case 4:
						c.IsMandatory = (txt == "Z" || txt == "Zorunlu")
					case 5:
						parts := strings.Split(txt, "/")
						if len(parts) == 3 {
							c.Theory, _ = strconv.Atoi(parts[0])
							c.Practice, _ = strconv.Atoi(parts[1])
							c.Lab, _ = strconv.Atoi(parts[2])
						}
					}
				})
				if c.Code != "" {
					courses = append(courses, c)
				}
			})
		}
	})
	return courses, nil
}

func (s *Service) GetCourseDetail(id, bid string) (*models.CourseDetail, error) {
	targetURL := fmt.Sprintf("%s/home/izlence/?id=%s&bid=%s", s.BaseURL, url.QueryEscape(id), url.QueryEscape(bid))

	resp, err := http.Get(targetURL)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	doc, err := goquery.NewDocumentFromReader(resp.Body)
	if err != nil {
		return nil, err
	}

	detail := &models.CourseDetail{}

	// 1. Üst Bilgi Tablosu
	doc.Find(".panel-heading:contains('İzlence Formu')").Parent().Find("table tr").Each(func(i int, tr *goquery.Selection) {
		tr.Find("td").Each(func(j int, td *goquery.Selection) {
			label := CleanText(td.Text())
			val := CleanText(td.Next().Text())

			if strings.Contains(label, "Ders Adı") {
				detail.BaseInfo.Name = val
			} else if strings.Contains(label, "Kod") {
				detail.BaseInfo.Code = val
			} else if strings.Contains(label, "Ders Dili") {
				detail.Language = val
			} else if strings.Contains(label, "Dersi Veren") {
				detail.Instructor = val
			}
		})
	})

	// 2. İçerik ve Diğerleri
	doc.Find(".panel-heading h4").Each(func(i int, s *goquery.Selection) {
		title := CleanText(s.Text())
		content := CleanText(s.ParentsFiltered(".panel-heading").Next().Text())

		switch title {
		case "Dersin Amacı":
			detail.Aim = content
		case "İçerik":
			detail.Content = content
		case "Kaynaklar":
			detail.Resources = content
		}
	})

	// 3. Çıktılar
	doc.Find(".panel-heading:contains('Dersin Öğrenme Çıktıları')").Parent().Find("table tbody tr").Each(func(i int, tr *goquery.Selection) {
		outcome := CleanText(tr.Find("td").Eq(1).Text())
		if outcome != "" {
			detail.Outcomes = append(detail.Outcomes, outcome)
		}
	})

	return detail, nil
}
