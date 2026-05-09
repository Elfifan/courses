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

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Имитация задержки 2 секунды как в модулях
      await Future.delayed(const Duration(seconds: 2));

      // 1. Считаем количество студентов (таблица user_courses)
      final enrolledCount = await SupabaseService.safeDbCall(
        () => SupabaseService.client
            .from('user_courses')
            .select('id')
            .eq('id_courses', widget.courseId)
            .count(CountOption.exact),
      );

      // 2. Считаем выручку (таблица user_courses)
      final revenueData = await SupabaseService.client
          .from('user_courses')
          .select('purchase_price')
          .eq('id_courses', widget.courseId);

      double totalRev = 0.0;
      if (revenueData != null) {
        for (var item in revenueData as List) {
          totalRev += (item['purchase_price'] ?? 0).toDouble();
        }
      }

      // 3. Считаем средний рейтинг (таблица feedback)
      final feedbackData = await SupabaseService.safeDbCall(
        () => SupabaseService.client
            .from('feedback')
            .select('estimation')
            .eq('id_courses', widget.courseId)
            .eq('status', true),
      );

      // 4. Получаем список последних студентов (user_courses + users)
      final studentsData = await SupabaseService.safeDbCall(
        () => SupabaseService.client
            .from('user_courses')
            .select('''
            id,
            purchase_date,
            users:id_user (
              id,
              name,
              email
            )
          ''')
            .eq('id_courses', widget.courseId)
            .order('purchase_date', ascending: false)
            .limit(10),
      );

      if (mounted) {
        double avg = 0.0;
        final feedbacks = feedbackData as List;
        if (feedbacks.isNotEmpty) {
          final sum = feedbacks.fold<double>(
            0,
            (prev, element) => prev + (element['estimation'] ?? 0).toDouble(),
          );
          avg = sum / feedbacks.length;
        }

        setState(() {
          _totalEnrolled = enrolledCount.count;
          _totalRevenue = totalRev;
          _averageRating = avg;
          _recentStudents = List<Map<String, dynamic>>.from(studentsData);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Ошибка аналитики: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

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
                              : '---',
                          style: AppStyles.label.copyWith(fontSize: 11),
                        ),
                        const Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.green,
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
