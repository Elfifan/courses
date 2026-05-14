import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/supabase_service.dart';

class QualityReportService {
  static Future<void> generate({
    required int courseId,
    required String courseName,
    required double averageRating,
  }) async {
    // Загрузка последних отзывов с ответами сотрудников
    final feedbackRes = await SupabaseService.client
        .from('feedback')
        .select('''
          id,
          estimation,
          description,
          users(name),
          response_feedback(answer)
        ''')
        .eq('id_courses', courseId)
        .order('id', ascending: false)
        .limit(15);

    final feedbacks = List<Map<String, dynamic>>.from(feedbackRes as List);

    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontItalic = await PdfGoogleFonts.robotoItalic();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Text(
              'АНАЛИЗ КАЧЕСТВА ОБУЧЕНИЯ',
              style: pw.TextStyle(font: fontBold, fontSize: 24, color: PdfColor.fromHex('#EF4444')),
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Курс: $courseName', style: pw.TextStyle(font: fontRegular, fontSize: 14)),
                pw.Row(
                  children: [
                    pw.Text('Средний балл: ', style: pw.TextStyle(font: fontBold, fontSize: 14)),
                    pw.Text('★ ${averageRating.toStringAsFixed(1)}', style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.orange)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 32),
            pw.Text('Последние отзывы пользователей:', style: pw.TextStyle(font: fontBold, fontSize: 16, decoration: pw.TextDecoration.underline)),
            pw.SizedBox(height: 16),

            ...feedbacks.map((f) {
              final userName = (f['users'] as Map?)?['name'] ?? 'Аноним';
              final rating = f['estimation']?.toString() ?? '—';
              final comment = f['description'] ?? 'Без комментария';
              final response = (f['response_feedback'] as List?)?.isNotEmpty == true 
                  ? (f['response_feedback'][0] as Map)['answer'] 
                  : null;

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 20),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Пользователь: $userName', style: pw.TextStyle(font: fontBold, fontSize: 12)),
                        pw.Text('Оценка: $rating', style: pw.TextStyle(font: fontBold, fontSize: 12)),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(comment, style: pw.TextStyle(font: fontRegular, fontSize: 11)),
                    if (response != null) ...[
                      pw.SizedBox(height: 8),
                      pw.Divider(color: PdfColors.grey100, thickness: 0.5),
                      pw.Text('Ответ сотрудника:', style: pw.TextStyle(font: fontItalic, fontSize: 10, color: PdfColors.grey)),
                      pw.Text(response, style: pw.TextStyle(font: fontItalic, fontSize: 10, color: PdfColors.grey600)),
                    ],
                  ],
                ),
              );
            }).toList(),

            if (feedbacks.isEmpty)
              pw.Text('Отзывов пока нет', style: pw.TextStyle(font: fontRegular, color: PdfColors.grey)),
          ];
        },
      ),
    );

    await _savePdf(pdf, 'Quality_$courseName');
  }

  static Future<void> _savePdf(pw.Document pdf, String fileName) async {
    final bytes = await pdf.save();
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Сохранить отчет',
      fileName: '$fileName.pdf',
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (outputFile != null) {
      if (!outputFile.toLowerCase().endsWith('.pdf')) outputFile += '.pdf';
      final file = File(outputFile);
      await file.writeAsBytes(bytes);
    }
  }
}
