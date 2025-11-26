import '../models/database_models.dart';
import '../services/supabase_service.dart';
import 'dart:io';
import 'dart:convert';

class AchievementRepository {
  // Преобразовать файл в List<int>
  static Future<List<int>> fileToBytes(File imageFile) async {
    try {
      return await imageFile.readAsBytes();
    } catch (e) {
      print('Error reading file: $e');
      throw Exception('Ошибка чтения файла: $e');
    }
  }

  // Получить все активные достижения
  static Future<List<Achievement>> getAllAchievements() async {
    try {
      final data = await SupabaseService.client
          .from('achievement')
          .select()
          .eq('status', true)  // ← Только активные
          .order('created_at', ascending: false);
      
      return (data as List)
          .map((item) => Achievement.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading achievements: $e');
      throw Exception('Ошибка загрузки достижений: $e');
    }
  }

  // Получить архивированные достижения
  static Future<List<Achievement>> getArchivedAchievements() async {
    try {
      final data = await SupabaseService.client
          .from('achievement')
          .select()
          .eq('status', false)  // ← Только архивированные
          .order('created_at', ascending: false);
      
      return (data as List)
          .map((item) => Achievement.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading archived achievements: $e');
      throw Exception('Ошибка загрузки архивированных достижений: $e');
    }
  }

  // Создать достижение
  static Future<Achievement> createAchievement({
    required String name,
    String? description,
    List<int>? imageData,
  }) async {
    try {
      final insertData = <String, dynamic>{
        'name': name,
        'description': description,
        'status': true,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      if (imageData != null) {
        insertData['image'] = base64Encode(imageData);
      }
      
      final data = await SupabaseService.client
          .from('achievement')
          .insert(insertData)
          .select()
          .single();
      
      return Achievement.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      print('Error creating achievement: $e');
      throw Exception('Ошибка создания достижения: $e');
    }
  }

  // Обновить достижение
  static Future<Achievement> updateAchievement(
    int id, {
    required String name,
    String? description,
    List<int>? imageData,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'name': name,
        'description': description,
      };
      
      if (imageData != null) {
        updateData['image'] = base64Encode(imageData);
      }
      
      final data = await SupabaseService.client
          .from('achievement')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();
      
      return Achievement.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      print('Error updating achievement: $e');
      throw Exception('Ошибка обновления достижения: $e');
    }
  }

  // Архивировать достижение (изменить status на false)
  static Future<void> archiveAchievement(int id) async {
    try {
      await SupabaseService.client
          .from('achievement')
          .update({'status': false})
          .eq('id', id);
    } catch (e) {
      print('Error archiving achievement: $e');
      throw Exception('Ошибка архивирования достижения: $e');
    }
  }

  // Восстановить достижение из архива (изменить status на true)
  static Future<void> restoreAchievement(int id) async {
    try {
      await SupabaseService.client
          .from('achievement')
          .update({'status': true})
          .eq('id', id);
    } catch (e) {
      print('Error restoring achievement: $e');
      throw Exception('Ошибка восстановления достижения: $e');
    }
  }

  // Удалить достижение полностью
  static Future<void> deleteAchievement(int id) async {
    try {
      await SupabaseService.client
          .from('achievement')
          .delete()
          .eq('id', id);
    } catch (e) {
      print('Error deleting achievement: $e');
      throw Exception('Ошибка удаления достижения: $e');
    }
  }
}
