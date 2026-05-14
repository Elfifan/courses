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
    // 1. Пытаемся сохранить лог модерации (не блокируем обновление статуса, если лог не создался)
    try {
      await SupabaseService.safeDbCall(() => 
        SupabaseService.client.from('course_moderation_logs').insert({
          'id_courses': courseId,
          'id_admin': adminId,
          'status_assigned': newStatus,
          'comment': comment,
        })
      );
    } catch (e) {
      debugPrint('Предупреждение: Не удалось сохранить лог модерации: $e');
    }

    // 2. Пытаемся обновить статус самого курса (основное действие)
    try {
      await SupabaseService.safeDbCall(() =>
        SupabaseService.client
            .from('courses')
            .update({'status': newStatus})
            .eq('id', courseId)
      );
    } catch (e) {
      debugPrint('Критическая ошибка обновления статуса курса: $e');
      throw Exception('Не удалось обновить статус курса: $e');
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