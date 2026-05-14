import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/supabase_service.dart';

class StatisticsReportService {
  static Future<void> generate({
    required int courseId,
    required String courseName,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final startStr = startDate.toIso8601String();
    final endStr = endDate.add(const Duration(days: 1)).toIso8601String();

    // Загрузка данных
    final enrolledRes = await SupabaseService.client
        .from('user_courses')
        .select('id')
        .eq('id_courses', courseId)
        .gte('purchase_date', startStr)
        .lte('purchase_date', endStr)
        .timeout(const Duration(seconds: 15));

    final completedRes = await SupabaseService.client
        .from('certificates')
        .select('id')
        .eq('id_courses', courseId)
        .gte('issue_date', startStr)
        .lte('issue_date', endStr)
        .timeout(const Duration(seconds: 15));

    final int totalInPeriod = (enrolledRes as List).length;
    final int completedInPeriod = (completedRes as List).length;
    final int inProcessInPeriod = totalInPeriod > completedInPeriod 
        ? totalInPeriod - completedInPeriod 
        : 0;

    final double completionRate = totalInPeriod > 0 
        ? (completedInPeriod / totalInPeriod) * 100 
        : 0;

    // Цвета темы Kodix
    final primaryPurple = PdfColor.fromHex('#A58EFF');
    final textDark = PdfColor.fromHex('#1E1E2E');
    final textGrey = PdfColor.fromHex('#9094A6');
    final bgLight = PdfColor.fromHex('#F8F9FB');

    // Генерация PDF
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final defaultStyle = pw.TextStyle(font: fontRegular, color: textDark);


    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'ОТЧЕТ: СТАТИСТИКА ПРОХОЖДЕНИЯ',
                  style: pw.TextStyle(font: fontBold, fontSize: 24, color: primaryPurple),
                ),
                pw.SizedBox(height: 12),
                pw.Text('Дата отчета: ${DateFormat('dd.MM.yyyy').format(DateTime.now())}', style: defaultStyle),
                pw.Text('Курс: $courseName', style: defaultStyle),
                pw.Text('Период: ${DateFormat('dd.MM.yyyy').format(startDate)} - ${DateFormat('dd.MM.yyyy').format(endDate)}', style: defaultStyle),
                pw.SizedBox(height: 40),

                pw.Table(
                  border: pw.TableBorder(
                    bottom: pw.BorderSide(color: bgLight, width: 2),
                    horizontalInside: pw.BorderSide(color: bgLight, width: 1),
                  ),
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: bgLight),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(12),
                          child: pw.Text('Название курса', style: pw.TextStyle(font: fontBold, fontSize: 14, color: textDark)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(12),
                          child: pw.Text('В процессе', style: pw.TextStyle(font: fontBold, fontSize: 14, color: textDark), textAlign: pw.TextAlign.right),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(12),
                          child: pw.Text('Завершили', style: pw.TextStyle(font: fontBold, fontSize: 14, color: textDark), textAlign: pw.TextAlign.right),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(12),
                          child: pw.Text(courseName, style: pw.TextStyle(font: fontRegular, fontSize: 13, color: textDark)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(12),
                          child: pw.Text(inProcessInPeriod.toString(), style: pw.TextStyle(font: fontRegular, fontSize: 13, color: textDark), textAlign: pw.TextAlign.right),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(12),
                          child: pw.Text(completedInPeriod.toString(), style: pw.TextStyle(font: fontRegular, fontSize: 13, color: textDark), textAlign: pw.TextAlign.right),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 40),
                pw.Row(
                  children: [
                    pw.Text('Общий процент завершения: ', style: pw.TextStyle(font: fontBold, fontSize: 16, color: textDark)),
                    pw.Text('${completionRate.toStringAsFixed(1)}%', style: pw.TextStyle(font: fontBold, fontSize: 16, color: primaryPurple)),
                  ],
                ),
                pw.Spacer(),
                pw.Divider(color: bgLight),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text('Сформировано в системе Kodix LMS', style: pw.TextStyle(font: fontRegular, fontSize: 10, color: textGrey)),
                ),
              ],
            ),
          );
        },
      ),
    );

    await _savePdf(pdf, 'Statistics_$courseName');
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
