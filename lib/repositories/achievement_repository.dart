import 'dart:io';
import 'package:uuid/uuid.dart';
import '../models/database_models.dart';
import '../services/supabase_service.dart';

class AchievementRepository {
  // Кэш для хранения загруженных данных
  static List<Achievement>? _cachedActive;
  static List<Achievement>? _cachedArchived;
  static DateTime? _lastFetchTime;
  
  // Время жизни кэша (5 секунд)
  static const Duration _cacheDuration = Duration(seconds: 5);

  // =========================================================================
  // ПОЛУЧЕНИЕ ПУБЛИЧНОГО URL ИЗ STORAGE ПО ПУТИ
  // =========================================================================
  
  static String? getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;

    try {
      final url = SupabaseService.client.storage
          .from('achievements')
          .getPublicUrl(imagePath);
      return url;
    } catch (e) {
      print('Error getting image URL: $e');
      return null;
    }
  }

  // =========================================================================
  // ОЧИСТКА КЭША
  // =========================================================================
  static void clearCache() {
    _cachedActive = null;
    _cachedArchived = null;
    _lastFetchTime = null;
  }

  // =========================================================================
  // ПОЛУЧЕНИЕ ВСЕХ АКТИВНЫХ ДОСТИЖЕНИЙ (с кэшированием)
  // =========================================================================
  static Future<List<Achievement>> getAllAchievements({bool forceRefresh = false}) async {
    try {
      // Используем кэш, если он свежий и не требуется принудительное обновление
      if (!forceRefresh && 
          _cachedActive != null && 
          _lastFetchTime != null &&
          DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
        return _cachedActive!;
      }

      final data = await SupabaseService.client
          .from('achievement')
          .select()
          .eq('status', true)
          .order('created_at', ascending: false);

      _cachedActive = (data as List)
          .map((item) => Achievement.fromJson(item as Map<String, dynamic>))
          .toList();
      
      _lastFetchTime = DateTime.now();
      return _cachedActive!;
    } catch (e) {
      print('Error loading achievements: $e');
      // Возвращаем кэшированные данные в случае ошибки
      if (_cachedActive != null) return _cachedActive!;
      throw Exception('Ошибка загрузки достижений: $e');
    }
  }

  // =========================================================================
  // ПОЛУЧЕНИЕ АРХИВНЫХ ДОСТИЖЕНИЙ (с кэшированием)
  // =========================================================================
  static Future<List<Achievement>> getArchivedAchievements({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && 
          _cachedArchived != null && 
          _lastFetchTime != null &&
          DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
        return _cachedArchived!;
      }

      final data = await SupabaseService.client
          .from('achievement')
          .select()
          .eq('status', false)
          .order('created_at', ascending: false);

      _cachedArchived = (data as List)
          .map((item) => Achievement.fromJson(item as Map<String, dynamic>))
          .toList();
      
      _lastFetchTime = DateTime.now();
      return _cachedArchived!;
    } catch (e) {
      print('Error loading archived achievements: $e');
      if (_cachedArchived != null) return _cachedArchived!;
      throw Exception('Ошибка загрузки архивированных достижений: $e');
    }
  }

  // =========================================================================
  // ЗАГРУЗКА ФАЙЛА В STORAGE
  // =========================================================================
  
  static Future<String?> _uploadImageToStorage(File imageFile) async {
    try {
      final fileExtension = imageFile.path.split('.').last;
      final fileName = '${const Uuid().v4()}.$fileExtension';
      final filePath = 'achievements/$fileName';

      await SupabaseService.client.storage
          .from('achievements')
          .upload(filePath, imageFile);

      return filePath;
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Ошибка загрузки изображения: $e');
    }
  }

  // =========================================================================
  // СОЗДАНИЕ ДОСТИЖЕНИЯ (с обновлением кэша)
  // =========================================================================
  static Future<Achievement> createAchievement({
    required String name,
    String? description,
    File? imageFile,
  }) async {
    try {
      String? imagePath;
      
      if (imageFile != null) {
        imagePath = await _uploadImageToStorage(imageFile);
      }

      final insertData = <String, dynamic>{
        'name': name,
        'description': description,
        'status': true,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      if (imagePath != null) {
        insertData['image'] = imagePath;
      }

      final data = await SupabaseService.client
          .from('achievement')
          .insert(insertData)
          .select()
          .single();

      final achievement = Achievement.fromJson(data as Map<String, dynamic>);
      
      // Добавляем в кэш активных достижений
      if (_cachedActive != null) {
        _cachedActive!.insert(0, achievement);
      }
      
      return achievement;
    } catch (e) {
      print('Error creating achievement: $e');
      throw Exception('Ошибка создания достижения: $e');
    }
  }

  // =========================================================================
  // ОБНОВЛЕНИЕ ДОСТИЖЕНИЯ (с обновлением кэша)
  // =========================================================================
  static Future<Achievement> updateAchievement(
    int id, {
    required String name,
    String? description,
    File? imageFile,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'name': name,
        'description': description,
      };

      if (imageFile != null) {
        final newImagePath = await _uploadImageToStorage(imageFile);
        updateData['image'] = newImagePath;
      }

      final data = await SupabaseService.client
          .from('achievement')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      final updatedAchievement = Achievement.fromJson(data as Map<String, dynamic>);
      
      // Обновляем в кэше
      _updateAchievementInCache(updatedAchievement);
      
      return updatedAchievement;
    } catch (e) {
      print('Error updating achievement: $e');
      throw Exception('Ошибка обновления достижения: $e');
    }
  }

  // =========================================================================
  // ВСПОМОГАТЕЛЬНЫЙ МЕТОД ДЛЯ ОБНОВЛЕНИЯ КЭША
  // =========================================================================
  static void _updateAchievementInCache(Achievement updated) {
    // Обновляем в активном кэше
    if (_cachedActive != null) {
      final index = _cachedActive!.indexWhere((a) => a.id == updated.id);
      if (index != -1) {
        if (updated.status) {
          _cachedActive![index] = updated;
        } else {
          _cachedActive!.removeAt(index);
          // Добавляем в архивный кэш
          _cachedArchived?.insert(0, updated);
        }
      } else if (updated.status) {
        _cachedActive!.insert(0, updated);
      }
    }
    
    // Обновляем в архивном кэше
    if (_cachedArchived != null) {
      final index = _cachedArchived!.indexWhere((a) => a.id == updated.id);
      if (index != -1) {
        if (!updated.status) {
          _cachedArchived![index] = updated;
        } else {
          _cachedArchived!.removeAt(index);
          // Добавляем в активный кэш
          _cachedActive?.insert(0, updated);
        }
      } else if (!updated.status) {
        _cachedArchived!.insert(0, updated);
      }
    }
  }

  // =========================================================================
  // АРХИВИРОВАНИЕ (с обновлением кэша)
  // =========================================================================
  static Future<void> archiveAchievement(int id) async {
    try {
      await SupabaseService.client
          .from('achievement')
          .update({'status': false})
          .eq('id', id);
      
      // Перемещаем из активного в архивный кэш
      if (_cachedActive != null) {
        final achievement = _cachedActive!.firstWhere((a) => a.id == id);
        _cachedActive!.remove(achievement);
        final archived = Achievement(
          id: achievement.id,
          createdAt: achievement.createdAt,
          name: achievement.name,
          description: achievement.description,
          status: false,
          imageUrl: achievement.imageUrl,
        );
        _cachedArchived?.insert(0, archived);
      }
    } catch (e) {
      print('Error archiving achievement: $e');
      throw Exception('Ошибка архивирования достижения: $e');
    }
  }

  // =========================================================================
  // ВОССТАНОВЛЕНИЕ (с обновлением кэша)
  // =========================================================================
  static Future<void> restoreAchievement(int id) async {
    try {
      await SupabaseService.client
          .from('achievement')
          .update({'status': true})
          .eq('id', id);
      
      // Перемещаем из архивного в активный кэш
      if (_cachedArchived != null) {
        final achievement = _cachedArchived!.firstWhere((a) => a.id == id);
        _cachedArchived!.remove(achievement);
        final restored = Achievement(
          id: achievement.id,
          createdAt: achievement.createdAt,
          name: achievement.name,
          description: achievement.description,
          status: true,
          imageUrl: achievement.imageUrl,
        );
        _cachedActive?.insert(0, restored);
      }
    } catch (e) {
      print('Error restoring achievement: $e');
      throw Exception('Ошибка восстановления достижения: $e');
    }
  }

  // =========================================================================
  // УДАЛЕНИЕ (с обновлением кэша)
  // =========================================================================
  static Future<void> deleteAchievement(int id) async {
    try {
      await SupabaseService.client
          .from('achievement')
          .delete()
          .eq('id', id);
      
      // Удаляем из кэша
      _cachedActive?.removeWhere((a) => a.id == id);
      _cachedArchived?.removeWhere((a) => a.id == id);
    } catch (e) {
      print('Error deleting achievement: $e');
      throw Exception('Ошибка удаления достижения: $e');
    }
  }
}