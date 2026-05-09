import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

class TheoryService {
  static final _supabase = Supabase.instance.client;

  static Future<Map<String, dynamic>?> getSubmodule(int submoduleId) async {
    try {
      final response = await _supabase
          .from('submodule')
          .select('id, id_module, name, description, content, lead_time, status')
          .eq('id', submoduleId)
          .single();

      return response;
    } catch (e) {
      debugPrint('Ошибка при загрузке подмодуля: $e');
      return null;
    }
  }

  static Future<String?> loadMarkdownFromStorage(String storageUrl) async {
    try {
      if (storageUrl.isEmpty) {
        debugPrint('URL пустой');
        return null;
      }

      debugPrint('=== НАЧАЛО ЗАГРУЗКИ MARKDOWN ===');
      debugPrint('URL: $storageUrl');

      final response = await http
          .get(Uri.parse(storageUrl))
          .timeout(
            Duration(seconds: 30),
            onTimeout: () {
              debugPrint('❌ Timeout при загрузке контента');
              throw Exception('Timeout при загрузке контента');
            },
          );

      if (response.statusCode == 200) {
        debugPrint('✓ Ответ получен: ${response.statusCode}');

        String content = convert.utf8.decode(response.bodyBytes);
        debugPrint('✓ Markdown декодирован, размер: ${content.length} символов');

        if (_isValidContent(content)) {
          debugPrint('✓ Контент валиден');
          final htmlContent = _markdownToHtml(content);
          debugPrint('=== ЗАГРУЗКА УСПЕШНА ===');
          return htmlContent;
        } else {
          debugPrint('❌ Контент невалиден');
          return '<p>Контент поврежден</p>';
        }
      } else {
        debugPrint('❌ Ошибка загрузки: ${response.statusCode}');
        return '<p>Ошибка загрузки контента</p>';
      }
    } catch (e) {
      debugPrint('❌ Исключение: $e');
      return '<p>Ошибка при загрузке: $e</p>';
    }
  }

  /// ✅ Преобразовать Markdown в HTML
  static String _markdownToHtml(String markdown) {
    List<String> lines = markdown.split('\n');
    StringBuffer result = StringBuffer();
    bool inList = false;

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      
      // ✅ УДАЛЯЕМ ВСЕ ПРОБЕЛЫ И ТАБУЛЯЦИИ В НАЧАЛЕ
      String trimmed = line.replaceFirst(RegExp(r'^[\s\t]*'), '').trim();

      // Пропускаем полностью пустые строки
      if (trimmed.isEmpty) {
        if (inList) {
          result.write('</ul>\n');
          inList = false;
        }
        continue; // ✅ НЕ добавляем пустые строки в результат
      }

      // ✅ ИЗОБРАЖЕНИЯ [IMG:url|size]
      if (trimmed.startsWith('[IMG:') && trimmed.endsWith(']')) {
        if (inList) {
          result.write('</ul>\n');
          inList = false;
        }

        String imgContent = trimmed.substring(5, trimmed.length - 1);
        int lastPipeIndex = imgContent.lastIndexOf('|');

        String imageUrl = '';
        String size = 'medium';

        if (lastPipeIndex > 0) {
          imageUrl = imgContent.substring(0, lastPipeIndex).trim();
          size = imgContent.substring(lastPipeIndex + 1).trim();
        } else {
          imageUrl = imgContent.trim();
        }

        if (imageUrl.isNotEmpty) {
          debugPrint('✓ Найдено изображение: $imageUrl (размер: $size)');
          result.write(
            '<img-container src="$imageUrl" size="$size"></img-container>\n',
          );
        }
        continue;
      }

      // ✅ Заголовки
      if (trimmed.startsWith('# ')) {
        if (inList) {
          result.write('</ul>\n');
          inList = false;
        }
        result.write('<h1>${trimmed.replaceFirst('# ', '')}</h1>\n');
      } else if (trimmed.startsWith('## ')) {
        if (inList) {
          result.write('</ul>\n');
          inList = false;
        }
        result.write('<h2>${trimmed.replaceFirst('## ', '')}</h2>\n');
      } else if (trimmed.startsWith('### ')) {
        if (inList) {
          result.write('</ul>\n');
          inList = false;
        }
        result.write('<h3>${trimmed.replaceFirst('### ', '')}</h3>\n');
      } else if (trimmed.startsWith('#### ')) {
        if (inList) {
          result.write('</ul>\n');
          inList = false;
        }
        result.write('<h4>${trimmed.replaceFirst('#### ', '')}</h4>\n');
      }
      // ✅ Маркированные списки
      else if (trimmed.startsWith('- ')) {
        if (!inList) {
          result.write('<ul>\n');
          inList = true;
        }
        result.write('<li>${trimmed.replaceFirst('- ', '')}</li>\n');
      }
      // ✅ Нумерованные списки
      else if (RegExp(r'^\d+\. ').hasMatch(trimmed)) {
        if (!inList) {
          result.write('<ol>\n');
          inList = true;
        }
        String item = trimmed.replaceAll(RegExp(r'^\d+\. '), '');
        result.write('<li>$item</li>\n');
      }
      // ✅ HTML теги
      else if (trimmed.startsWith('<')) {
        if (inList) {
          result.write('</ul>\n');
          inList = false;
        }
        result.write('$trimmed\n');
      }
      // ✅ Обычный текст
      else {
        if (inList) {
          result.write('</ul>\n');
          inList = false;
        }
        String formatted = _formatLineText(trimmed);
        result.write('<p>$formatted</p>\n');
      }
    }

    if (inList) {
      result.write('</ul>\n');
    }

    return result.toString();
  }

  static String _formatLineText(String text) {
    text = text.replaceAll(
      RegExp(r'\[([^\]]+)\]\(([^\)]+)\)'),
      '<a href="\$2">\$1</a>',
    );

    text = text.replaceAll(RegExp(r'\*\*(.+?)\*\*'), '<strong>\$1</strong>');
    text = text.replaceAll(RegExp(r'__(.+?)__'), '<strong>\$1</strong>');

    text = text.replaceAll(RegExp(r'\*(.+?)\*'), '<em>\$1</em>');
    text = text.replaceAll(RegExp(r'_(.+?)_'), '<em>\$1</em>');

    text = text.replaceAll(RegExp(r'`(.+?)`'), '<code>\$1</code>');

    return text;
  }

  static bool _isValidContent(String content) {
    return content.trim().isNotEmpty && content.length > 10;
  }

  static Future<bool> updateSubmoduleContent(
    int submoduleId,
    String contentUrl,
  ) async {
    try {
      await _supabase
          .from('submodule')
          .update({'content': contentUrl})
          .eq('id', submoduleId);

      debugPrint('✓ Контент обновлен');
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка: $e');
      return false;
    }
  }

  static Future<bool> deleteSubmoduleContent(int submoduleId) async {
    try {
      await _supabase
          .from('submodule')
          .update({'content': null})
          .eq('id', submoduleId);

      debugPrint('✓ Контент удален');
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка: $e');
      return false;
    }
  }
}
