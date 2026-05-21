import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'dart:convert';
import '../../core/theme/app_components.dart';
import '../../services/theory_service.dart';
import '../../models/database_models.dart';




class LessonViewerScreen extends StatefulWidget {
  final int submoduleId;
  final String courseName;
  final String courseIcon;



  const LessonViewerScreen({
    super.key,
    required this.submoduleId,
    required this.courseName,
    required this.courseIcon,
  });



  @override
  State<LessonViewerScreen> createState() => _LessonViewerScreenState();
}



class _LessonViewerScreenState extends State<LessonViewerScreen>
    with AutomaticKeepAliveClientMixin {
  String? theoryHtml;
  Submodule? submodule;
  bool isLoading = true;
  String? errorMessage;
  
  bool isVideo = false;
  String? videoUrl;
  String? videoDescription;
  List<String> videoTheses = [];



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
        debugPrint('Невозможно открыть $url');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Не удалось открыть ссылку')),
          );
        }
      }
    } catch (e) {
      debugPrint('Ошибка при открытии ссылки: $e');
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

      debugPrint('Начинаем загрузку подмодуля ${widget.submoduleId}');

      final submoduleData = await TheoryService.getSubmodule(widget.submoduleId)
          .timeout(
            Duration(seconds: 15),
            onTimeout: () {
              debugPrint('Timeout при загрузке подмодуля');
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

      bool isVideoLesson = false;
      String? parsedVideoUrl;
      String? parsedVideoDesc;
      List<String> parsedTheses = [];

      String? htmlContent;
      if (loadedSubmodule.content != null &&
          loadedSubmodule.content!.isNotEmpty) {
        final contentStr = loadedSubmodule.content!;
        if (contentStr.trim().startsWith('{')) {
          try {
            final json = jsonDecode(contentStr);
            if (json['type'] == 'video') {
              isVideoLesson = true;
              parsedVideoUrl = json['video_url'];
              parsedVideoDesc = json['description'];
              parsedTheses = List<String>.from(json['theses'] ?? []);
            }
          } catch (e) {
            debugPrint('Ошибка парсинга JSON контента подмодуля: $e');
          }
        }

        if (!isVideoLesson && _isValidUrl(contentStr)) {
          debugPrint('Загружаем контент с URL: $contentStr');

          htmlContent = await TheoryService.loadMarkdownFromStorage(contentStr)
              .timeout(
                Duration(seconds: 30),
                onTimeout: () {
                  debugPrint('Timeout при загрузке контента');
                  return '<p>Ошибка: время ожидания</p>';
                },
              );

          if (htmlContent != null && !_isValidHtml(htmlContent)) {
            debugPrint('Получен некорректный контент');
            htmlContent = '<p>Контент поврежден</p>';
          }
        }
      }

      if (!mounted) return;

      setState(() {
        submodule = loadedSubmodule;
        theoryHtml = htmlContent;
        isVideo = isVideoLesson;
        videoUrl = parsedVideoUrl;
        videoDescription = parsedVideoDesc;
        videoTheses = parsedTheses;
        isLoading = false;
      });

      debugPrint('Загрузка завершена');
    } catch (e) {
      debugPrint('Ошибка загрузки теории: $e');
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
        title: Text(submodule?.name ?? widget.courseName),
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
      child: Row(
        children: [
          // ✅ Левый отступ 15%
          Expanded(flex: 15, child: const SizedBox.shrink()),
          
          // ✅ Основной контент 70%
          Expanded(
            flex: 70,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isVideo && videoUrl != null) ...[
                    // Premium Video Player
                    PremiumVideoPlayer(videoUrl: videoUrl!),
                    const SizedBox(height: 24),
                    
                    // Lesson Description Header
                    Text(
                      'Описание урока',
                      style: AppStyles.h1.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      videoDescription ?? '',
                      style: AppStyles.body.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    
                    // Theses Card Container
                    if (videoTheses.isNotEmpty) ...[
                      KodixComponents.cardContainer(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline_rounded,
                                  color: AppColors.primaryPurple,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Тезисы урока',
                                  style: AppStyles.h1.copyWith(
                                    fontSize: 18,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ...videoTheses.map((thesis) => Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.primaryPurple,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      thesis,
                                      style: AppStyles.body.copyWith(
                                        fontSize: 15,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                          ],
                        ),
                      ),
                    ],
                  ] else if (theoryHtml != null && theoryHtml!.isNotEmpty)
                    _buildContentWithImages(theoryHtml!),
                ],
              ),
            ),
          ),
          
          // ✅ Правый отступ 15%
          Expanded(flex: 15, child: const SizedBox.shrink()),
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
        debugPrint('✓ Отображаем изображение: $imageUrl (размер: $sizeStr)');
        
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
                    color: Colors.black.withValues(alpha: 0.1),
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
                    debugPrint('❌ Ошибка загрузки изображения: $error');
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
        color: Theme.of(context).colorScheme.onSurface,
      ),
      'h1': Style(
        fontSize: FontSize(24),
        fontWeight: FontWeight.bold,
        margin: Margins.only(top: 20, bottom: 12),
        padding: HtmlPaddings.zero,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      'h2': Style(
        fontSize: FontSize(20),
        fontWeight: FontWeight.bold,
        margin: Margins.only(top: 20, bottom: 12),
        padding: HtmlPaddings.zero,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      'h3': Style(
        fontSize: FontSize(18),
        fontWeight: FontWeight.bold,
        margin: Margins.only(top: 20, bottom: 12),
        padding: HtmlPaddings.zero,
        color: Theme.of(context).colorScheme.onSurface,
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
        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
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

class PremiumVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const PremiumVideoPlayer({
    super.key,
    required this.videoUrl,
  });

  @override
  State<PremiumVideoPlayer> createState() => _PremiumVideoPlayerState();
}

class _PremiumVideoPlayerState extends State<PremiumVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _showControls = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final uri = Uri.parse(widget.videoUrl);
      _controller = VideoPlayerController.networkUrl(uri);
      await _controller.initialize();
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _controller.setVolume(_controller.value.volume == 0 ? 1.0 : 0.0);
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                SizedBox(height: 12),
                Text(
                  'Не удалось загрузить видео',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_initialized) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primaryPurple),
                SizedBox(height: 16),
                Text(
                  'Инициализация видео...',
                  style: TextStyle(color: AppColors.textGrey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _showControls = !_showControls;
                });
              },
              child: VideoPlayer(_controller),
            ),
            
            // Premium Gradient Overlay when controls are visible
            if (_showControls)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showControls = false;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Play/Pause Big Button in Center
            if (_showControls)
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    iconSize: 56,
                    icon: Icon(
                      _controller.value.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                    ),
                    onPressed: _togglePlay,
                  ),
                ),
              ),

            // Bottom Controls Bar
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Video Progress Bar
                      VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: AppColors.primaryPurple,
                          bufferedColor: Colors.white30,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Play/Pause, Mute & Time
                          Row(
                            children: [
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  _controller.value.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                onPressed: _togglePlay,
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  _controller.value.volume == 0
                                      ? Icons.volume_off_rounded
                                      : Icons.volume_up_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: _toggleMute,
                              ),
                              const SizedBox(width: 16),
                              ValueListenableBuilder(
                                valueListenable: _controller,
                                builder: (context, VideoPlayerValue value, child) {
                                  return Text(
                                    '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}