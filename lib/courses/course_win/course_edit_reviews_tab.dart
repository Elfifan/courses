// course_edit_reviews_tab.dart
import 'package:flutter/material.dart';

class CourseEditReviewsTab extends StatefulWidget {
  final List<Map<String, dynamic>>? reviewsFromParent;

  const CourseEditReviewsTab({super.key, this.reviewsFromParent});

  @override
  State<CourseEditReviewsTab> createState() => _CourseEditReviewsTabState();
}

class _CourseEditReviewsTabState extends State<CourseEditReviewsTab> {
  String _search = '';
  late List<Map<String, dynamic>> _reviews;

  @override
  void initState() {
    super.initState();
    _reviews = widget.reviewsFromParent ?? [
      {
        'name': 'Александр К.',
        'avatar': 'А',
        'date': '12.09.2025',
        'rating': 5,
        'text': 'Отличный курс, много практики!',
        'reply': 'Спасибо за ваш отзыв!',
        'blocked': false,
      },
      {
        'name': 'Мария П.',
        'avatar': 'М',
        'date': '10.09.2025',
        'rating': 4,
        'text': 'Всё понятно, хотелось бы больше заданий.',
        'reply': null,
        'blocked': false,
      },
      {
        'name': 'Иван Л.',
        'avatar': 'И',
        'date': '09.09.2025',
        'rating': 2,
        'text': 'Местами скучно, но материал хороший.',
        'reply': null,
        'blocked': false,
      }
    ];
  }

  void _deleteReview(int index, {bool block = false}) {
    final removedName = _filteredList()[index]['name'];
    setState(() {
      // Удаляем из исходного списка _reviews именно того, кто сейчас на экране (_filteredList()[index])
      final toRemove = _filteredList()[index];
      _reviews.remove(toRemove);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          block
              ? 'Отзыв пользователя "$removedName" удалён и он был заблокирован'
              : 'Отзыв пользователя "$removedName" удалён',
        ),
        backgroundColor: block ? Colors.red : null,
      ),
    );
  }

  List<Map<String, dynamic>> _filteredList() {
    if (_search.trim().isEmpty) return _reviews;
    final req = _search.trim().toLowerCase();
    return _reviews.where((r) =>
        r['name'].toString().toLowerCase().contains(req) ||
        r['text'].toString().toLowerCase().contains(req) ||
        (r['reply'] ?? '').toString().toLowerCase().contains(req)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurface.withOpacity(0.7);
    final filtered = _filteredList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок и количество отзывов
          Row(
            children: [
              Expanded(
                child: Text(
                  'Отзывы о курсе',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Всего: ${_reviews.length}',
                  style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Поиск
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Поиск по имени, тексту, отзыву или ответу...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Список отзывов
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'Отзывов не найдено.',
                      style: TextStyle(color: textSecondary, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) =>
                        _buildReviewCard(filtered[index], index, theme, textColor, textSecondary),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(
      Map review, int filteredIndex, ThemeData theme, Color textColor, Color textSecondary) {
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
                  child: Text(review['avatar'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review['name'], style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16)),
                      Text(review['date'], style: TextStyle(color: textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      Icons.star,
                      size: 18,
                      color: i < (review['rating'] ?? 0) ? Colors.amber : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                ),
                // Меню действия (три точки)
                PopupMenuButton<String>(
                  tooltip: 'Действия',
                  onSelected: (v) {
                    if (v == 'delete') {
                      _deleteReview(filteredIndex, block: false);
                    } else if (v == 'block') {
                      _deleteReview(filteredIndex, block: true);
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
                          Icon(Icons.block_flipped, color: Colors.redAccent, size: 20),
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
              review['text'],
              style: TextStyle(fontSize: 15, color: textColor),
            ),
            const SizedBox(height: 10),
            if (review['reply'] != null)
              Container(
                margin: EdgeInsets.only(top: 6, left: 2),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.reply, size: 16, color: theme.primaryColor),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        review['reply'],
                        style: TextStyle(fontSize: 14, color: theme.primaryColor, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            if (review['reply'] == null)
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton.icon(
                  onPressed: () {}, // Здесь реализуйте диалог ответа если надо
                   icon: const Icon(Icons.reply, size: 16),
                  label: const Text('Ответить', style: TextStyle(fontSize: 13)),
                ),
              )
          ],
        ),
      ),
    );
  }
}
