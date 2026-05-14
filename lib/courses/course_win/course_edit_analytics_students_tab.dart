import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_components.dart';
import '../../services/supabase_service.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CourseEditAnalyticsStudentsTab extends StatefulWidget {
  final int courseId;
  final String courseName;
  final double coursePrice;

  const CourseEditAnalyticsStudentsTab({
    super.key,
    required this.courseId,
    required this.courseName,
    required this.coursePrice,
  });

  @override
  State<CourseEditAnalyticsStudentsTab> createState() =>
      _CourseEditAnalyticsStudentsTabState();
}

class _CourseEditAnalyticsStudentsTabState
    extends State<CourseEditAnalyticsStudentsTab>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  int _totalEnrolled = 0;
  double _totalRevenue = 0.0;
  double _averageRating = 0.0;
  List<Map<String, dynamic>> _recentStudents = [];
  String? _errorMessage;

  // Поля для отчёта
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isGeneratingReport = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('--- [Аналитика] Финальная попытка оптимизации для ID: ${widget.courseId} ---');

      // 1. Получаем список ID (простой вариант, работает везде)
      final countFuture = SupabaseService.client
          .from('user_courses')
          .select('id')
          .eq('id_courses', widget.courseId)
          .timeout(const Duration(seconds: 10));

      // 2. Получаем рейтинг
      final feedbackFuture = SupabaseService.client
          .from('feedback')
          .select('estimation')
          .eq('id_courses', widget.courseId)
          .eq('status', true)
          .timeout(const Duration(seconds: 10));

      // 3. Получаем последние записи (с упрощенным JOIN)
      final recentFuture = SupabaseService.client
          .from('user_courses')
          .select('''
            id,
            purchase_date,
            users (
              name,
              email
            )
          ''')
          .eq('id_courses', widget.courseId)
          .order('purchase_date', ascending: false)
          .limit(10)
          .timeout(const Duration(seconds: 12));

      // 4. Получаем цены для выручки
      final revenueFuture = SupabaseService.client
          .from('user_courses')
          .select('purchase_price')
          .eq('id_courses', widget.courseId)
          .timeout(const Duration(seconds: 15));

      debugPrint('--- [Аналитика] Все запросы отправлены... ---');

      final results = await Future.wait([
        countFuture,
        feedbackFuture,
        recentFuture,
        revenueFuture,
      ]);

      debugPrint('--- [Аналитика] Все запросы завершены! ---');

      final countData = results[0] as List<dynamic>;
      final feedbackData = results[1] as List<dynamic>;
      final recentData = results[2] as List<dynamic>;
      final revenueData = results[3] as List<dynamic>;

      // Считаем выручку
      double totalRev = 0;
      for (var row in revenueData) {
        final price = row['purchase_price'];
        if (price != null) {
          totalRev += (price is num) ? price.toDouble() : 0.0;
        }
      }

      // Считаем рейтинг
      double avg = 0.0;
      if (feedbackData.isNotEmpty) {
        double sum = 0;
        int count = 0;
        for (var f in feedbackData) {
          final est = f['estimation'];
          if (est != null) {
            sum += (est as num).toDouble();
            count++;
          }
        }
        if (count > 0) avg = sum / count;
      }

      if (mounted) {
        setState(() {
          _totalEnrolled = countData.length;
          _totalRevenue = totalRev;
          _averageRating = avg;
          _recentStudents = List<Map<String, dynamic>>.from(recentData);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('--- [Аналитика] КРИТИЧЕСКАЯ ОШИБКА: $e ---');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Не удалось загрузить аналитику: $e';
        });
      }
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryPurple,
              onPrimary: Colors.white,
              onSurface: AppColors.textGrey,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _generatePdfReport() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, выберите диапазон дат')),
      );
      return;
    }

    setState(() => _isGeneratingReport = true);

    try {
      // 1. Получаем данные за период
      final startStr = _startDate!.toIso8601String();
      final endStr = _endDate!.add(const Duration(days: 1)).toIso8601String();

      // Сколько купили в этот период
      final enrolledRes = await SupabaseService.client
          .from('user_courses')
          .select('id')
          .eq('id_courses', widget.courseId)
          .gte('purchase_date', startStr)
          .lte('purchase_date', endStr);

      // Сколько получили сертификат в этот период
      final completedRes = await SupabaseService.client
          .from('certificates')
          .select('id')
          .eq('id_courses', widget.courseId)
          .gte('issue_date', startStr)
          .lte('issue_date', endStr);

      final int totalInPeriod = (enrolledRes as List).length;
      final int completedInPeriod = (completedRes as List).length;
      final int inProcessInPeriod = totalInPeriod > completedInPeriod 
          ? totalInPeriod - completedInPeriod 
          : 0;

      final double completionRate = totalInPeriod > 0 
          ? (completedInPeriod / totalInPeriod) * 100 
          : 0;

      // 2. Создаем PDF
      final pdf = pw.Document();
      final fontRegular = await PdfGoogleFonts.robotoRegular();
      final fontBold = await PdfGoogleFonts.robotoBold();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(32),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Заголовок
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.start,
                    children: [
                      pw.Text(
                        'ОТЧЕТ: СТАТИСТИКА ПРОХОЖДЕНИЯ',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 24,
                          color: PdfColor.fromHex('#22C55E'),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'Дата отчета: ${DateFormat('dd.MM.yyyy').format(DateTime.now())}',
                    style: pw.TextStyle(font: fontRegular, fontSize: 12),
                  ),
                  pw.Text(
                    'Период: ${DateFormat('dd.MM.yyyy').format(_startDate!)} - ${DateFormat('dd.MM.yyyy').format(_endDate!)}',
                    style: pw.TextStyle(font: fontRegular, fontSize: 12),
                  ),
                  pw.SizedBox(height: 40),

                  // Таблица
                  pw.Table(
                    border: const pw.TableBorder(
                      bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                    ),
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 8),
                            child: pw.Text('Название курса', style: pw.TextStyle(font: fontBold, fontSize: 14)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 8),
                            child: pw.Text('В процессе', style: pw.TextStyle(font: fontBold, fontSize: 14), textAlign: pw.TextAlign.right),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 8),
                            child: pw.Text('Завершили', style: pw.TextStyle(font: fontBold, fontSize: 14), textAlign: pw.TextAlign.right),
                          ),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 12),
                            child: pw.Text(widget.courseName, style: pw.TextStyle(font: fontRegular, fontSize: 13)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 12),
                            child: pw.Text(inProcessInPeriod.toString(), style: pw.TextStyle(font: fontRegular, fontSize: 13), textAlign: pw.TextAlign.right),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 12),
                            child: pw.Text(completedInPeriod.toString(), style: pw.TextStyle(font: fontRegular, fontSize: 13), textAlign: pw.TextAlign.right),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 40),

                  // Итого
                  pw.Row(
                    children: [
                      pw.Text(
                        'Общий процент завершения: ',
                        style: pw.TextStyle(font: fontBold, fontSize: 16),
                      ),
                      pw.Text(
                        '${completionRate.toStringAsFixed(1)}%',
                        style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColor.fromHex('#3B82F6')),
                      ),
                    ],
                  ),

                  pw.Spacer(),
                  pw.Divider(color: PdfColors.grey),
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      'Сформировано в системе Kodix LMS',
                      style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.grey),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      // 3. Сохраняем через диалог выбора файла
      final bytes = await pdf.save();
      
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Выберите место для сохранения отчета',
        fileName: 'Report_${widget.courseName}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (outputFile != null) {
        // Добавляем расширение, если его нет
        if (!outputFile.toLowerCase().endsWith('.pdf')) {
          outputFile += '.pdf';
        }
        
        final file = File(outputFile);
        await file.writeAsBytes(bytes);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Отчет успешно сохранен: $outputFile'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

    } catch (e) {
      debugPrint('Ошибка генерации отчета: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка генерации PDF: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingReport = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text('Ошибка загрузки аналитики', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_errorMessage!, style: AppStyles.label, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            const Text('Повтор через 3 секунды...', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryPurple),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Карточки статистики
          Row(
            children: [
              _buildStatCard(
                'Студентов',
                _totalEnrolled.toString(),
                Icons.people_alt_rounded,
                AppColors.primaryPurple,
              ),
              const SizedBox(width: 20),
              _buildStatCard(
                'Доход',
                '${_totalRevenue.toInt()} ₽',
                Icons.payments_rounded,
                Colors.green,
              ),
              const SizedBox(width: 20),
              _buildStatCard(
                'Рейтинг',
                _averageRating.toStringAsFixed(1),
                Icons.star_rounded,
                Colors.orange,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Секция генерации отчёта
          _buildReportSection(),

          const SizedBox(height: 40),

          Text('Последние записи', style: AppStyles.h1),
          const SizedBox(height: 16),

          if (_recentStudents.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: AppStyles.cardRadius,
                border: Border.all(color: AppColors.bgLight),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.person_off_rounded,
                      size: 48,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text('Студентов пока нет', style: AppStyles.label),
                  ],
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: AppStyles.cardRadius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentStudents.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, color: AppColors.bgLight),
                itemBuilder: (context, index) {
                  final student = _recentStudents[index];
                  final user = student['users'] as Map<String, dynamic>?;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryPurple.withValues(
                        alpha: 0.1,
                      ),
                      child: Text(
                        (user?['name']?.toString().isNotEmpty == true
                                ? user!['name'][0]
                                : '?')
                            .toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primaryPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      user?['name'] ?? 'Неизвестный студент',
                      style: AppStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      user?['email'] ?? 'Email не указан',
                      style: AppStyles.label,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          student['purchase_date'] != null
                              ? DateFormat('dd.MM.yyyy').format(
                                  DateTime.parse(student['purchase_date']),
                                )
                              : 'Дата неизвестна',
                          style: AppStyles.label,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.coursePrice.toInt()} ₽',
                          style: AppStyles.body.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReportSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppStyles.cardRadius,
        border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.1)),
        gradient: LinearGradient(
          colors: [
            AppColors.white,
            AppColors.primaryPurple.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, color: AppColors.primaryPurple),
              const SizedBox(width: 12),
              Text('Генерация отчёта', style: AppStyles.h1.copyWith(fontSize: 18)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите период, чтобы выгрузить статистику прохождения курса в формате PDF',
            style: AppStyles.label,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.bgLight),
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.bgLight.withValues(alpha: 0.3),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primaryPurple),
                        const SizedBox(width: 12),
                        Text(
                          _startDate == null 
                              ? 'Выберите период' 
                              : '${DateFormat('dd.MM.yyyy').format(_startDate!)} - ${DateFormat('dd.MM.yyyy').format(_endDate!)}',
                          style: AppStyles.body.copyWith(
                            color: _startDate == null ? AppColors.textGrey : AppColors.primaryPurple,
                            fontWeight: _startDate == null ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              KodixComponents.primaryButton(
                onPressed: _isGeneratingReport ? null : _generatePdfReport,
                child: _isGeneratingReport
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                      )
                    : Row(
                        children: const [
                          Icon(Icons.picture_as_pdf_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('Выгрузить PDF'),
                        ],
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppStyles.cardRadius,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 16),
            Text(value, style: AppStyles.h1.copyWith(color: color)),
            const SizedBox(height: 4),
            Text(title, style: AppStyles.label),
          ],
        ),
      ),
    );
  }
}
