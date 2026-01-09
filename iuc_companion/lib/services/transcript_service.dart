import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class TranscriptService {

  // PDF'ten ders kodu ve harf notunu çeker
  Future<Map<String, String>> extractGrades(File pdfFile) async {
    try {
      final List<int> bytes = await pdfFile.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      String text = PdfTextExtractor(document).extractText();
      document.dispose();

      final regex = RegExp(
        r'([A-Z]{3,4}\d{3,4})[\s\S]*?\s(AA|BA|BB|CB|CC|DC|DD|FD|FF|G|M)(?=\s|\d|$)',
        multiLine: true,
      );

      Map<String, String> extractedGrades = {};

      for (final match in regex.allMatches(text)) {
        String code = match.group(1) ?? "";
        String grade = match.group(2) ?? "";

        if (code.isNotEmpty && grade.isNotEmpty) {
          extractedGrades[code] = grade;
          print("DERS BULUNDU: $code -> $grade");
        }
      }

      print("TOPLAM ÇEKİLEN DERS SAYISI: ${extractedGrades.length}");
      return extractedGrades;

    } catch (e) {
      print("Transkript okuma hatası: $e");
      return {};
    }
  }
}