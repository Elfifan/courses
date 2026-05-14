import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/supabase_service.dart';

class GraduatesReportService {
  static Future<void> generate({
    required int courseId,
    required String courseName,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final startStr = startDate.toIso8601String();
    final endStr = endDate.add(const Duration(days: 1)).toIso8601String();

    // Загрузка данных: сертификаты с именами пользователей
    final graduatesRes = await SupabaseService.client
        .from('certificates')
        .select('issue_date, users(name)')
        .eq('id_courses', courseId)
        .gte('issue_date', startStr)
        .lte('issue_date', endStr)
        .order('issue_date', ascending: true);

    final graduates = List<Map<String, dynamic>>.from(graduatesRes as List);

    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Text(
              'ВЕДОМОСТЬ ВЫПУСКНИКОВ КУРСА',
              style: pw.TextStyle(font: fontBold, fontSize: 24),
            ),
            pw.SizedBox(height: 12),
            pw.Text('Курс: $courseName', style: pw.TextStyle(font: fontRegular, fontSize: 14)),
            pw.Text('Период: ${DateFormat('dd.MM.yyyy').format(startDate)} - ${DateFormat('dd.MM.yyyy').format(endDate)}', style: pw.TextStyle(font: fontRegular)),
            pw.SizedBox(height: 24),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(40),
                1: const pw.FlexColumnWidth(),
                2: const pw.FixedColumnWidth(120),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('№', style: pw.TextStyle(font: fontBold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('ФИО Студента', style: pw.TextStyle(font: fontBold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Дата окончания', style: pw.TextStyle(font: fontBold), textAlign: pw.TextAlign.center),
                    ),
                  ],
                ),
                ...List.generate(graduates.length, (index) {
                  final grad = graduates[index];
                  final userName = (grad['users'] as Map?)?['name'] ?? 'Неизвестный';
                  final date = grad['issue_date'] != null 
                      ? DateFormat('dd.MM.yyyy').format(DateTime.parse(grad['issue_date']))
                      : '—';

                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('${index + 1}', style: pw.TextStyle(font: fontRegular)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(userName, style: pw.TextStyle(font: fontRegular)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(date, style: pw.TextStyle(font: fontRegular), textAlign: pw.TextAlign.center),
                      ),
                    ],
                  );
                }),
              ],
            ),

            if (graduates.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 20),
                child: pw.Text('За выбранный период выпускников не найдено', style: pw.TextStyle(font: fontRegular, color: PdfColors.grey)),
              ),

            pw.SizedBox(height: 40),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('Всего выпускников: ${graduates.length}', style: pw.TextStyle(font: fontBold, fontSize: 14)),
            ),
          ];
        },
      ),
    );

    await _savePdf(pdf, 'Graduates_$courseName');
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
