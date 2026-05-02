import 'package:flutter/foundation.dart';
import '../models/database_models.dart';
import '../services/supabase_service.dart';

class CourseModerationRepository {
  /// Получить все логи модерации для курса
  static Future<List<CourseModerationLog>> getCourseModerationsLogs(
      int courseId) async {
    try {
      final response = await SupabaseService.client
          .from('course_moderation_logs')
          .select()
          .eq('id_courses', courseId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      
      return data
          .map((item) => CourseModerationLog.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Ошибка загрузки логов модерации: $e');
      throw Exception('Ошибка загрузки логов модерации: $e');
    }
  }

  /// Сохранить лог модерации (изменить статус курса)
  static Future<void> setCourseModerationStatus({
    required int courseId,
    required int adminId,
    required String newStatus,
    String? comment,
  }) async {
    try {
      // Сохраняем лог модерации
      await SupabaseService.client.from('course_moderation_logs').insert({
        'id_courses': courseId,
        'id_admin': adminId,
        'status_assigned': newStatus,
        'comment': comment,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Обновляем статус курса
      await SupabaseService.client
          .from('courses')
          .update({'status': newStatus})
          .eq('id', courseId);
    } catch (e) {
      debugPrint('Ошибка сохранения логов модерации: $e');
      throw Exception('Ошибка сохранения логов модерации: $e');
    }
  }

  /// Получить последний лог модерации курса
  static Future<CourseModerationLog?> getLastModerationLog(int courseId) async {
    try {
      final response = await SupabaseService.client
          .from('course_moderation_logs')
          .select()
          .eq('id_courses', courseId)
          .order('created_at', ascending: false)
          .limit(1);

      final List<dynamic> data = response as List<dynamic>;

      if (data.isEmpty) return null;

      return CourseModerationLog.fromJson(data[0] as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Ошибка получения последнего лога модерации: $e');
      return null;
    }
  }
}