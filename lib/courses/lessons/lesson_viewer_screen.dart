import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/theory_service.dart';
import '../../models/database_models.dart';


class LessonViewerScreen extends StatefulWidget {
  final int submoduleId;
  final String courseName;
  final String courseIcon;


  const LessonViewerScreen({
    Key? key,
    required this.submoduleId,
    required this.courseName,
    required this.courseIcon,
  }) : super(key: key);


  @override
  State<LessonViewerScreen> createState() => _LessonViewerScreenState();
}


class _LessonViewerScreenState extends State<LessonViewerScreen>
    with AutomaticKeepAliveClientMixin {
  String? theoryHtml;
  Submodule? submodule;
  bool isLoading = true;
  String? errorMessage;


  @override
  bool get wantKeepAlive => true;


  @override
  void initState() {
    super.initState();
    _loadTheory();
  }


  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute;
    } catch (e) {
      return false;
    }
  }


  bool _isValidHtml(String html) {
    return html.trim().isNotEmpty && html.length > 10;
  }


  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        print('Невозможно открыть $url');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Не удалось открыть ссылку')),
          );
        }
      }
    } catch (e) {
      print('Ошибка при открытии ссылки: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при открытии ссылки')),
        );
      }
    }
  }


  Future<void> _loadTheory() async {
    try {
      if (!mounted) return;
      setState(() {
        isLoading = true;
        errorMessage = null;
      });


      print('Начинаем загрузку подмодуля ${widget.submoduleId}');


      final submoduleData = await TheoryService.getSubmodule(widget.submoduleId)
          .timeout(
            Duration(seconds: 15),
            onTimeout: () {
              print('Timeout при загрузке подмодуля');
              return null;
            },
          );


      if (submoduleData == null) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          errorMessage = 'Подмодуль не найден';
        });
        return;
      }


      final loadedSubmodule = Submodule.fromJson(submoduleData);


      String? htmlContent;
      if (loadedSubmodule.content != null &&
          loadedSubmodule.content!.isNotEmpty) {
        final contentUrl = loadedSubmodule.content!;
        if (_isValidUrl(contentUrl)) {
          print('Загружаем контент с URL: $contentUrl');


          htmlContent = await TheoryService.loadMarkdownFromStorage(contentUrl)
              .timeout(
                Duration(seconds: 30),
                onTimeout: () {
                  print('Timeout при загрузке контента');
                  return '<p>Ошибка: время ожидания</p>';
                },
              );


          if (htmlContent != null && !_isValidHtml(htmlContent)) {
            print('Получен некорректный контент');
            htmlContent = '<p>Контент поврежден</p>';
          }
        }
      }


      if (!mounted) return;


      setState(() {
        submodule = loadedSubmodule;
        theoryHtml = htmlContent;
        isLoading = false;
      });


      print('Загрузка завершена');
    } catch (e) {
      print('Ошибка загрузки теории: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Ошибка загрузки: $e';
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseName),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Загрузка теории...'),
                ],
              ),
            )
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64),
                      SizedBox(height: 16),
                      Text('Ошибка: $errorMessage'),
                    ],
                  ),
                )
              : _buildTheoryContent(),
    );
  }


  Widget _buildTheoryContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.courseIcon,
                      style: TextStyle(fontSize: 40),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        submodule?.name ?? 'Урок',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (submodule?.description != null &&
                    submodule!.description!.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      submodule!.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (theoryHtml != null && theoryHtml!.isNotEmpty)
            Container(
              padding: EdgeInsets.all(16),
              child: _buildContentWithImages(theoryHtml!),
            ),
        ],
      ),
    );
  }


  /// ✅ Строит контент с поддержкой изображений и кликабельных ссылок
  Widget _buildContentWithImages(String htmlContent) {
    List<Widget> widgets = [];


    // ✅ Регулярное выражение для поиска [IMG:...]
    final imgRegex = RegExp(
      r'\[IMG:([^\|]+)\|([^\]]+)\]',
    );


    int lastIndex = 0;
    imgRegex.allMatches(htmlContent).forEach((match) {
      // Добавляем текст до изображения
      final beforeText = htmlContent.substring(lastIndex, match.start);
      if (beforeText.trim().isNotEmpty) {
        widgets.add(
          _buildHtmlWidget(beforeText),
        );
      }


      // Добавляем изображение
      final imageUrl = match.group(1) ?? '';
      final sizeStr = match.group(2) ?? 'medium';


      if (imageUrl.isNotEmpty) {
        print('✓ Отображаем изображение: $imageUrl (размер: $sizeStr)');
        
        double imageHeight = _getImageHeight(sizeStr);


        widgets.add(
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Container(
              height: imageHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print('❌ Ошибка загрузки изображения: $error');
                    return Container(
                      color: Colors.grey[300],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported, size: 48),
                            SizedBox(height: 8),
                            Text('Изображение не загрузилось'),
                          ],
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      }


      lastIndex = match.end;
    });


    // Добавляем оставшийся текст
    final remainingText = htmlContent.substring(lastIndex);
    if (remainingText.trim().isNotEmpty) {
      widgets.add(_buildHtmlWidget(remainingText));
    }


    if (widgets.isEmpty) {
      return _buildHtmlWidget(htmlContent);
    }


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }


  /// Вспомогательный метод для построения HTML с обработкой ссылок
  Widget _buildHtmlWidget(String htmlContent) {
    return Html(
      data: htmlContent,
      shrinkWrap: true,
      style: _getHtmlStyles(),
      onLinkTap: (url, attributes, element) {
        if (url != null && url.isNotEmpty) {
          _launchUrl(url);
        }
      },
    );
  }


  /// Определяет высоту изображения по размеру
  double _getImageHeight(String size) {
    switch (size.toLowerCase()) {
      case 'small':
        return 100;
      case 'medium':
        return 250;
      case 'large':
        return 400;
      default:
        try {
          if (size.contains('%')) {
            final percent = double.parse(size.replaceAll('%', ''));
            return 250 * (percent / 100);
          }
          return double.parse(size);
        } catch (e) {
          return 250;
        }
    }
  }


  /// Стили для HTML
  Map<String, Style> _getHtmlStyles() {
    return {
      'p': Style(
        fontSize: FontSize(15),
        lineHeight: LineHeight(1.5),
        margin: Margins.symmetric(vertical: 12),
        color: Theme.of(context).colorScheme.onBackground,
      ),
      'h1': Style(
        fontSize: FontSize(24),
        fontWeight: FontWeight.bold,
        margin: Margins.only(top: 20, bottom: 12),
        padding: HtmlPaddings.zero,
        color: Theme.of(context).colorScheme.onBackground,
      ),
      'h2': Style(
        fontSize: FontSize(20),
        fontWeight: FontWeight.bold,
        margin: Margins.only(top: 20, bottom: 12),
        padding: HtmlPaddings.zero,
        color: Theme.of(context).colorScheme.onBackground,
      ),
      'h3': Style(
        fontSize: FontSize(18),
        fontWeight: FontWeight.bold,
        margin: Margins.only(top: 20, bottom: 12),
        padding: HtmlPaddings.zero,
        color: Theme.of(context).colorScheme.onBackground,
      ),
      'ul': Style(
        margin: Margins.symmetric(vertical: 12),
        padding: HtmlPaddings.only(left: 20),
      ),
      'ol': Style(
        margin: Margins.symmetric(vertical: 12),
        padding: HtmlPaddings.only(left: 20),
      ),
      'li': Style(
        fontSize: FontSize(15),
        margin: Margins.symmetric(vertical: 6),
      ),
      'mark': Style(
        backgroundColor: Color(0xFFFFCCCC),
        padding: HtmlPaddings.symmetric(horizontal: 4, vertical: 2),
      ),
      'strong': Style(fontWeight: FontWeight.bold),
      'b': Style(fontWeight: FontWeight.bold),
      'em': Style(fontStyle: FontStyle.italic),
      'code': Style(
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        fontFamily: 'Courier New',
        fontSize: FontSize(13),
        padding: HtmlPaddings.symmetric(horizontal: 4, vertical: 2),
      ),
      'a': Style(
        color: Color(0xFF0080FF),
        textDecoration: TextDecoration.underline,
        textDecorationColor: Color(0xFF0080FF),
      ),
    };
  }


  @override
  void dispose() {
    super.dispose();
  }
}