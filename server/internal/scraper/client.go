package scraper

import (
	"strings"
)

func CleanText(s string) string {
	return strings.TrimSpace(strings.ReplaceAll(s, "\n", " "))
}
