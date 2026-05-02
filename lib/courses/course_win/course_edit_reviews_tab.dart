import 'package:flutter/material.dart';
import '../../models/database_models.dart' as db_models;
import '../../services/supabase_service.dart';

class CourseEditReviewsTab extends StatefulWidget {
  final int courseId;
  final bool readOnly;

  const CourseEditReviewsTab({super.key, required this.courseId, this.readOnly = false});

  @override
  State<CourseEditReviewsTab> createState() => _CourseEditReviewsTabState();
}

class _CourseEditReviewsTabState extends State<CourseEditReviewsTab> {
  String _search = '';
  List<db_models.Feedback> _feedbacks = [];
  Map<int, db_models.ResponseFeedback?> _responses = {};
  Map<int, bool> _expandedReply = {}; // Отслеживаем открытое поле ввода
  Map<int, TextEditingController> _replyControllers = {}; // Контроллеры для каждого отзыва
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final feedbackData = await SupabaseService.client
          .from('feedback')
          .select('''
            id,
            estimation,
            description,
            status,
            id_user,
            users(name)
          ''')
          .eq('id_courses', widget.courseId)
          .eq('status', true)
          .order('id', ascending: false);

      Map<int, db_models.ResponseFeedback?> responses = {};
      
      for (var feedback in feedbackData) {
        final responseData = await SupabaseService.client
            .from('response_feedback')
            .select()
            .eq('id_feedback', feedback['id'])
            .maybeSingle();
        
        if (responseData != null) {
          responses[feedback['id']] = db_models.ResponseFeedback.fromJson(responseData);
        }

        // Инициализируем контроллеры и состояние
        _expandedReply[feedback['id']] = false;
        _replyControllers[feedback['id']] = TextEditingController();
      }

      if (mounted) {
        setState(() {
          _feedbacks = (feedbackData as List).map((item) {
            return db_models.Feedback(
              id: item['id'] as int,
              idUser: item['id_user'] as int?,
              idCourses: widget.courseId,
              estimation: (item['estimation'] as num?)?.toDouble(),
              description: item['description'] as String?,
              status: true,
            );
          }).toList();
          _responses = responses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки отзывов: $e')),
        );
      }
    }
  }

  void _deleteReview(db_models.Feedback feedback, {bool block = false}) async {
    try {
      await SupabaseService.client
          .from('feedback')
          .update({'status': false})
          .eq('id', feedback.id);

      if (mounted) {
        setState(() {
          _feedbacks.removeWhere((f) => f.id == feedback.id);
          _responses.remove(feedback.id);
          _expandedReply.remove(feedback.id);
          _replyControllers[feedback.id]?.dispose();
          _replyControllers.remove(feedback.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              block
                  ? 'Отзыв удалён и пользователь был заблокирован'
                  : 'Отзыв удалён',
            ),
            backgroundColor: block ? Colors.red : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления: $e')),
        );
      }
    }
  }

  Future<void> _submitReply(db_models.Feedback feedback) async {
    final text = _replyControllers[feedback.id]?.text.trim() ?? '';
    
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите текст ответа')),
      );
      return;
    }

    try {
      await SupabaseService.client
          .from('response_feedback')
          .insert({
            'id_feedback': feedback.id,
            'id_employee': 1,
            'answer': text,
          });

      if (mounted) {
        setState(() {
          _expandedReply[feedback.id] = false;
          _replyControllers[feedback.id]?.clear();
        });
        _loadReviews();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ответ добавлен')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  List<db_models.Feedback> _getFilteredFeedbacks() {
    if (_search.trim().isEmpty) return _feedbacks;
    final req = _search.trim().toLowerCase();
    return _feedbacks.where((f) {
      final description = f.description?.toLowerCase() ?? '';
      return description.contains(req);
    }).toList();
  }

  @override
  void dispose() {
    for (var controller in _replyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurface.withOpacity(0.7);
    final filtered = _getFilteredFeedbacks();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Отзывы о курсе',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Всего: ${_feedbacks.length}',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Поиск по тексту отзыва...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Text(
                          'Отзывов не найдено.',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final feedback = filtered[index];
                          return _buildReviewCard(
                            feedback,
                            theme,
                            textColor,
                            textSecondary,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(
    db_models.Feedback feedback,
    ThemeData theme,
    Color textColor,
    Color textSecondary,
  ) {
    final userName = 'Пользователь #${feedback.idUser}';
    final avatar = (userName.isNotEmpty ? userName[0] : 'У').toUpperCase();
    final rating = (feedback.estimation ?? 0).toInt();
    final response = _responses[feedback.id];
    final isExpanded = _expandedReply[feedback.id] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.primaryColor,
                  child: Text(
                    avatar,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        feedback.idUser?.toString() ?? 'Неизвестно',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      Icons.star,
                      size: 18,
                      color: i < rating
                          ? Colors.amber
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Действия',
                  onSelected: (v) {
                    if (v == 'delete') {
                      _deleteReview(feedback, block: false);
                    } else if (v == 'block') {
                      _deleteReview(feedback, block: true);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          SizedBox(width: 10),
                          Text('Удалить', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'block',
                      child: Row(
                        children: [
                          Icon(
                            Icons.block_flipped,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Удалить и заблокировать',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              feedback.description ?? 'Описание отсутствует',
              style: TextStyle(fontSize: 15, color: textColor),
            ),
            const SizedBox(height: 10),
            // Ответ администратора (если есть)
            if (response != null)
              Container(
                margin: const EdgeInsets.only(top: 6, left: 2),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.reply, size: 16, color: theme.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        response.answer ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.primaryColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Кнопка "Ответить" или поле ввода
            if (response == null && !widget.readOnly) ...[
              const SizedBox(height: 12),
              if (!isExpanded)
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _expandedReply[feedback.id] = true;
                      });
                    },
                    icon: const Icon(Icons.reply, size: 16),
                    label: const Text('Ответить', style: TextStyle(fontSize: 13)),
                  ),
                )
              else
                // ← КРАСИВОЕ ПОЛЕ ВВОДА
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.background.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ваш ответ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _replyControllers[feedback.id],
                        maxLines: 3,
                        minLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Напишите ответ студенту...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _expandedReply[feedback.id] = false;
                                _replyControllers[feedback.id]?.clear();
                              });
                            },
                            child: Text(
                              'Отмена',
                              style: TextStyle(color: textSecondary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _submitReply(feedback),
                            icon: const Icon(Icons.send, size: 16),
                            label: const Text('Отправить'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
