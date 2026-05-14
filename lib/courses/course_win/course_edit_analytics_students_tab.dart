import 'package:flutter/material.dart';
import '../../core/theme/app_components.dart';
import '../../services/supabase_service.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CourseEditAnalyticsStudentsTab extends StatefulWidget {
  final int courseId;
  final double coursePrice;

  const CourseEditAnalyticsStudentsTab({
    super.key,
    required this.courseId,
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
