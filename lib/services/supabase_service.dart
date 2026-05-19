import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../models/database_models.dart';

class SupabaseService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Getter для доступа к клиенту
  static SupabaseClient get client => _supabase;

  /// Выполняет запрос к БД с автоматическими повторами при сетевых ошибках
  static Future<T> safeDbCall<T>(Future<T> Function() call, {int retries = 3}) async {
    int attempts = 0;
    while (attempts < retries) {
      try {
        return await call();
      } catch (e) {
        attempts++;
        debugPrint('Supabase query failed (attempt $attempts/$retries): $e. Retrying in ${500 * attempts}ms...');
        if (attempts >= retries) rethrow;
        // Задержка перед повтором (экспоненциальная или фиксированная)
        await Future.delayed(Duration(milliseconds: 500 * attempts));
      }
    }
    throw Exception('Непредвиденная ошибка при выполнении запроса');
  }

  // ============ USERS ============

  static Future<List<User>> getUsers() async {
    try {
      final data = await _supabase.from('users').select();
      return data.map((item) => User.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Ошибка при получении пользователей: $e');
    }
  }

  static Future<User?> getUserById(int id) async {
    try {
      final data = await _supabase
          .from('users')
          .select()
          .eq('id', id)
          .maybeSingle();
      return data != null ? User.fromJson(data) : null;
    } catch (e) {
      throw Exception('Ошибка при получении пользователя: $e');
    }
  }

  static Future<User> createUser(User user) async {
    try {
      final data = await _supabase
          .from('users')
          .insert(user.toJson())
          .select()
          .single();
      return User.fromJson(data);
    } catch (e) {
      throw Exception('Ошибка при создании пользователя: $e');
    }
  }

  static Stream<void> watchUsers() {
    final controller = StreamController<void>.broadcast();
    final channel = _supabase
        .channel('public:users')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'users',
          callback: (payload) {
            if (!controller.isClosed) {
              controller.add(null);
            }
          },
        );

    channel.subscribe();

    controller.onCancel = () {
      channel.unsubscribe();
      controller.close();
    };

    return controller.stream;
  }

  // ============ COURSES ============

  static Future<List<Course>> getCourses() async {
    try {
      final data = await _supabase.from('courses').select();
      return data.map((item) => Course.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Ошибка при получении курсов: $e');
    }
  }

  static Future<Course?> getCourseById(int id) async {
    try {
      final data = await _supabase
          .from('courses')
          .select()
          .eq('id', id)
          .maybeSingle();
      return data != null ? Course.fromJson(data) : null;
    } catch (e) {
      throw Exception('Ошибка при получении курса: $e');
    }
  }

  static Future<Course> createCourse(Course course) async {
    try {
      final data = await _supabase
          .from('courses')
          .insert(course.toJson())
          .select()
          .single();
      return Course.fromJson(data);
    } catch (e) {
      throw Exception('Ошибка при создании курса: $e');
    }
  }

  // ============ MODULES ============

  static Future<List<Module>> getModulesByCourse(int courseId) async {
    try {
      final data = await _supabase
          .from('module')
          .select()
          .eq('id_courses', courseId)
          .order('order_module', ascending: true);
      return data.map((item) => Module.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Ошибка при получении модулей: $e');
    }
  }

  static Future<List<Submodule>> getSubmodulesByModule(int moduleId) async {
    try {
      final data = await _supabase
          .from('submodule')
          .select()
          .eq('id_module', moduleId)
          .order('id', ascending: true);
      return data.map((item) => Submodule.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Ошибка при получении подмодулей: $e');
    }
  }
}
