import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdfx/pdfx.dart';
import 'package:http/http.dart' as http;
import '../../models/database_models.dart';

class LessonViewerScreen extends StatefulWidget {
  final int courseId;
  final String courseName;
  final String courseIcon;

  const LessonViewerScreen({
    Key? key,
    required this.courseId,
    required this.courseName,
    required this.courseIcon,
  }) : super(key: key);

  @override
  State<LessonViewerScreen> createState() => _LessonViewerScreenState();
}

class _LessonViewerScreenState extends State<LessonViewerScreen> {
  Submodule? submodule;
  PdfDocument? pdfDocument;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubmodule();
  }

  Future<void> _loadSubmodule() async {
    try {
      if (!mounted) return;
      setState(() => isLoading = true);

      final response = await Supabase.instance.client
          .from('submodule')
          .select()
          .eq('id', 1)
          .single();

      if (!mounted) return;

      final sub = Submodule.fromJson(response);
      setState(() {
        submodule = sub;
      });

      if (sub.content != null) {
        await _loadPdf(sub.content!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки: $e')),
      );
      print('Ошибка: $e');
    }
  }

  Future<void> _loadPdf(String pdfUrl) async {
    try {
      // Скачиваем PDF файл
      final response = await http.get(Uri.parse(pdfUrl));

      if (response.statusCode == 200) {
        // Конвертируем в Uint8List
        final bytes = response.bodyBytes;
        
        // Открываем PDF из байтов
        final document = await PdfDocument.openData(bytes);
        
        if (!mounted) return;
        
        setState(() {
          pdfDocument = document;
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Ошибка загрузки PDF: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseName),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : submodule == null
              ? Center(child: Text('Подмодуль не найден'))
              : pdfDocument == null
                  ? Center(child: Text('PDF не загружен'))
                  : _buildLessonContent(),
    );
  }

  Widget _buildLessonContent() {
    return Column(
      children: [
        // Заголовок
        Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          child: Row(
            children: [
              Text(
                widget.courseIcon,
                style: TextStyle(fontSize: 32),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      submodule?.name ?? 'Урок',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (submodule?.description != null)
                      Text(
                        submodule!.description!,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // PDF Viewer
        Expanded(
          child: PdfViewer(document: pdfDocument!),
        ),
      ],
    );
  }

  @override
  void dispose() {
    pdfDocument?.close();
    super.dispose();
  }
}

// PDF Viewer Widget
class PdfViewer extends StatefulWidget {
  final PdfDocument document;

  const PdfViewer({required this.document});

  @override
  State<PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<PdfViewer> {
  int currentPage = 1;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (page) {
              setState(() => currentPage = page + 1);
            },
            itemCount: widget.document.pagesCount,
            itemBuilder: (context, pageIndex) {
              return PdfPageViewer(
                document: widget.document,
                pageNumber: pageIndex + 1,
              );
            },
          ),
        ),
        // Навигация
        Container(
          padding: EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: currentPage > 1
                    ? () {
                        _pageController.previousPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
                icon: Icon(Icons.arrow_back),
                label: Text('Назад'),
              ),
              Text(
                'Страница $currentPage / ${widget.document.pagesCount}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              ElevatedButton.icon(
                onPressed: currentPage < widget.document.pagesCount
                    ? () {
                        _pageController.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
                icon: Icon(Icons.arrow_forward),
                label: Text('Далее'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

// Viewer для одной страницы
class PdfPageViewer extends StatefulWidget {
  final PdfDocument document;
  final int pageNumber;

  const PdfPageViewer({
    required this.document,
    required this.pageNumber,
  });

  @override
  State<PdfPageViewer> createState() => _PdfPageViewerState();
}

class _PdfPageViewerState extends State<PdfPageViewer> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PdfPage?>(
      future: widget.document.getPage(widget.pageNumber),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Center(child: Text('Ошибка загрузки страницы'));
        }

        final page = snapshot.data!;

return FutureBuilder<PdfPageImage?>(
  future: page.render(
    width: MediaQuery.of(context).size.width * 3,
    height: MediaQuery.of(context).size.height * 3,
  ),
  builder: (context, imageSnapshot) {
    if (imageSnapshot.connectionState == ConnectionState.waiting) {
      return Center(child: CircularProgressIndicator());
    }
    if (imageSnapshot.hasError || imageSnapshot.data == null) {
      return Center(child: Text('Ошибка рендеринга страницы'));
    }

    final image = imageSnapshot.data!;

    return InteractiveViewer(
      panEnabled: true,
      scaleEnabled: true,
      minScale: 1.0,
      maxScale: 4.0,
      child: Image.memory(
        image.bytes,
        fit: BoxFit.contain,
      ),
    );
  },
);

      },
    );
  }
}
