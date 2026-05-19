import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Пользовательский HTTP-клиент для Supabase с автоматической защитой от сбоев
/// сокетов (ошибки семафора) и таймаутами для всех запросов к БД.
class TimeoutAndRetryClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Определяем, является ли запрос обращением к REST API Базы Данных (/rest/v1/)
    final isDbQuery = request.url.path.contains('/rest/v1/');
    
    // Для запросов к БД ставим таймаут 2 секунды, для остальных (файлы, авторизация) — 60 секунд.
    final timeoutDuration = isDbQuery ? const Duration(seconds: 2) : const Duration(seconds: 60);
    
    // Повторяем только запросы к БД (до 3 попыток), для остальных — выполняем один раз.
    final maxAttempts = isDbQuery ? 3 : 1;
    
    int attempts = 0;
    while (true) {
      attempts++;
      
      // Клонируем запрос для поддержки повторных попыток (необходимо для http.BaseRequest)
      final clonedRequest = maxAttempts > 1 ? _cloneRequest(request) : request;
      
      try {
        final response = await _inner.send(clonedRequest).timeout(timeoutDuration);
        return response;
      } catch (e) {
        final isTimeoutOrNetwork = e is TimeoutException ||
            e.toString().toLowerCase().contains('timeout') ||
            e.toString().toLowerCase().contains('таймаут') ||
            e.toString().toLowerCase().contains('semaphore') ||
            e.toString().toLowerCase().contains('семафор') ||
            e.toString().toLowerCase().contains('clientexception') ||
            e.toString().toLowerCase().contains('socketexception') ||
            e.toString().toLowerCase().contains('handshake');
            
        // Если лимит попыток исчерпан или ошибка не относится к сетевым/таймаутам — пробрасываем ошибку дальше
        if (attempts >= maxAttempts || !isTimeoutOrNetwork) {
          debugPrint('Supabase HTTP request failed definitively (URL: ${request.url}): $e');
          rethrow;
        }
        
        debugPrint('Supabase DB query failed (attempt $attempts/$maxAttempts) (URL: ${request.url}): $e. Retrying in ${500 * attempts}ms...');
        await Future.delayed(Duration(milliseconds: 500 * attempts));
      }
    }
  }

  /// Метод клонирования запроса, так как http.BaseRequest нельзя отправлять повторно напрямую
  http.BaseRequest _cloneRequest(http.BaseRequest request) {
    if (request is http.Request) {
      final copy = http.Request(request.method, request.url)
        ..headers.addAll(request.headers)
        ..maxRedirects = request.maxRedirects
        ..followRedirects = request.followRedirects
        ..persistentConnection = request.persistentConnection
        ..bodyBytes = request.bodyBytes;
      return copy;
    } else if (request is http.MultipartRequest) {
      final copy = http.MultipartRequest(request.method, request.url)
        ..headers.addAll(request.headers)
        ..fields.addAll(request.fields)
        ..files.addAll(request.files);
      return copy;
    }
    return request;
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
