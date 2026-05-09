import 'package:cyrs/core/theme/app_components.dart';
import 'package:flutter/material.dart';
import '../../models/database_models.dart' as db_models;
import '../../services/supabase_service.dart';

class CourseEditReviewsTab extends StatefulWidget {
  final int courseId;
  final bool readOnly;

  const CourseEditReviewsTab({
    super.key,
    required this.courseId,
    this.readOnly = false,
  });

  @override
  State<CourseEditReviewsTab> createState() => _CourseEditReviewsTabState();
}

class _CourseEditReviewsTabState extends State<CourseEditReviewsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _search = '';
  List<db_models.Feedback> _feedbacks = [];
  Map<int, db_models.ResponseFeedback?> _responses = {};
  final Map<int, bool> _expandedReply = {}; // Отслеживаем открытое поле ввода
  final Map<int, TextEditingController> _replyControllers =
      {}; // Контроллеры для каждого отзыва
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
      // Оптимизированный запрос: получаем отзыв и ответ одним махом
      final feedbackData = await SupabaseService.safeDbCall(
        () => SupabaseService.client
            .from('feedback')
            .select('''
            *,
            users(name),
            response_feedback(*)
          ''')
            .eq('id_courses', widget.courseId)
            .eq('status', true)
            .order('id', ascending: false),
      );

      Map<int, db_models.ResponseFeedback?> responses = {};

      for (var item in (feedbackData as List)) {
        final feedbackId = item['id'] as int;
        final responseList = item['response_feedback'] as List?;

        if (responseList != null && responseList.isNotEmpty) {
          responses[feedbackId] = db_models.ResponseFeedback.fromJson(
            responseList.first,
          );
        }

        // Инициализируем контроллеры и состояние
        _expandedReply[feedbackId] = _expandedReply[feedbackId] ?? false;
        _replyControllers[feedbackId] =
            _replyControllers[feedbackId] ?? TextEditingController();
      }

      if (mounted) {
        setState(() {
          _feedbacks = (feedbackData).map((item) {
            return db_models.Feedback.fromJson(item);
          }).toList();
          _responses = responses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки отзывов: $e')));
      }
    }
  }

  void _deleteReview(db_models.Feedback feedback, {bool block = false}) async {
    try {
      await SupabaseService.safeDbCall(
        () => SupabaseService.client
            .from('feedback')
            .update({'status': false})
            .eq('id', feedback.id),
      );

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
      }
    }
  }

  Future<void> _submitReply(db_models.Feedback feedback) async {
    final text = _replyControllers[feedback.id]?.text.trim() ?? '';

    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Введите текст ответа')));
      return;
    }

    try {
      await SupabaseService.safeDbCall(
        () => SupabaseService.client.from('response_feedback').insert({
          'id_feedback': feedback.id,
          'id_employee': 1,
          'answer': text,
        }),
      );

      if (mounted) {
        setState(() {
          _expandedReply[feedback.id] = false;
          _replyControllers[feedback.id]?.clear();
        });
        _loadReviews();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ответ добавлен')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
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
    super.build(context);
    final filtered = _getFilteredFeedbacks();

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryPurple),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Отзывы студентов',
                style: AppStyles.h1.copyWith(fontSize: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_feedbacks.length} отзывов',
                  style: AppStyles.label.copyWith(
                    color: AppColors.primaryPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          TextField(
            decoration: KodixComponents.textFieldDecoration(
              hintText: 'Поиск по тексту отзыва...',
              prefixIcon: Icons.search_rounded,
            ),
            style: AppStyles.body,
            onChanged: (v) => setState(() => _search = v),
          ),

          const SizedBox(height: 24),

          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 64,
                          color: AppColors.textGrey.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text('Отзывов не найдено', style: AppStyles.label),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final feedback = filtered[index];
                      final response = _responses[feedback.id];
                      return _buildReviewCard(feedback, response);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(
    db_models.Feedback feedback,
    db_models.ResponseFeedback? response,
  ) {
    final isExpanded = _expandedReply[feedback.id] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppStyles.mainRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: AppColors.bgLight,
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Студент #${feedback.idUser}',
                          style: AppStyles.body.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        _buildStars(feedback.estimation ?? 0),
                        if (!widget.readOnly)
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
                                    Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Удалить',
                                      style: TextStyle(color: Colors.red),
                                    ),
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
                    const SizedBox(height: 8),
                    Text(
                      feedback.description ?? 'Без комментария',
                      style: AppStyles.body,
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (response != null) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryPurple.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.reply_rounded,
                        size: 16,
                        color: AppColors.primaryPurple,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ваш ответ',
                        style: AppStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryPurple,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    response.answer ?? '',
                    style: AppStyles.body.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
          ] else if (!widget.readOnly) ...[
            const SizedBox(height: 16),
            if (!isExpanded)
              TextButton.icon(
                onPressed: () =>
                    setState(() => _expandedReply[feedback.id] = true),
                icon: const Icon(Icons.add_comment_rounded, size: 18),
                label: const Text('Ответить на отзыв'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryPurple,
                ),
              )
            else
              Column(
                children: [
                  TextField(
                    controller: _replyControllers[feedback.id],
                    maxLines: 3,
                    decoration: KodixComponents.textFieldDecoration(
                      hintText: 'Напишите ваш ответ...',
                    ),
                    style: AppStyles.body,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () =>
                            setState(() => _expandedReply[feedback.id] = false),
                        child: const Text(
                          'Отмена',
                          style: TextStyle(color: AppColors.textGrey),
                        ),
                      ),
                      const SizedBox(width: 12),
                      KodixComponents.primaryButton(
                        onPressed: () => _submitReply(feedback),
                        child: const Text('Отправить'),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStars(double rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          color: Colors.amber,
          size: 20,
        );
      }),
    );
  }

}
