import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../shared/search_row.dart';

class AchievementsScreen extends StatefulWidget {
  final bool isDarkMode;

  const AchievementsScreen({super.key, required this.isDarkMode});

  @override
  _AchievementsScreenState createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> _achievements = [
    {
      'id': 1,
      'title': 'Первое достижение',
      'description': 'Зарегистрирован первый студент на платформе',
      'image': null,
      'date': '15 мар 2024',
      'isArchived': false,
    },
    {
      'id': 2,
      'title': '100 студентов',
      'description': 'Достигнуто 100 зарегистрированных студентов',
      'image': null,
      'date': '25 мая 2024',
      'isArchived': false,
    },
  ];

  List<Map<String, dynamic>> get _filteredAchievements {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _achievements.where((a) => a['isArchived'] == false).toList();
    return _achievements.where((a) {
      final title = (a['title'] ?? '').toString().toLowerCase();
      final desc = (a['description'] ?? '').toString().toLowerCase();
      return (title.contains(q) || desc.contains(q)) && a['isArchived'] == false;
    }).toList();
  }

  String _getTodayDate() {
    final now = DateTime.now();
    const months = ['янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
    return '${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]} ${now.year}';
  }

  Future<void> _pickImage(Function(File?) onPicked) async {
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        onPicked(File(file.path));
      } else {
        onPicked(null);
      }
    } catch (_) {
      onPicked(null);
    }
  }

  void openAddDialog() => _showForm();

  void _showForm({Map<String, dynamic>? achievement}) {
    final isEdit = achievement != null;
    final _titleController = TextEditingController(text: achievement?['title'] ?? '');
    final _descController = TextEditingController(text: achievement?['description'] ?? '');
    File? pickedImage = achievement != null ? achievement['image'] as File? : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEdit ? 'Редактировать достижение' : 'Добавить достижение'),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Название *', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(labelText: 'Описание', border: OutlineInputBorder()),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: pickedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(pickedImage as File, height: 90, fit: BoxFit.cover),
                                )
                              : Container(
                                  height: 90,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Theme.of(context).dividerColor),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text('Изображение не выбрано'),
                                ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await _pickImage((file) => setState(() => pickedImage = file));
                          },
                          icon: const Icon(Icons.image),
                          label: const Text('Выбрать'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Отмена')),
              ElevatedButton(
                onPressed: () {
                  final title = _titleController.text.trim();
                  if (title.isEmpty) return;
                  setState(() {
                    if (isEdit) {
                      final idx = _achievements.indexWhere((e) => e['id'] == achievement['id']);
                      if (idx != -1) {
                        _achievements[idx]['title'] = title;
                        _achievements[idx]['description'] = _descController.text.trim();
                        _achievements[idx]['image'] = pickedImage;
                      }
                    } else {
                      final id = (_achievements.isEmpty ? 1 : (_achievements.map((e) => e['id'] as int).reduce((a, b) => a > b ? a : b) + 1));
                      _achievements.insert(0, {
                        'id': id,
                        'title': title,
                        'description': _descController.text.trim(),
                        'image': pickedImage,
                        'date': _getTodayDate(),
                        'isArchived': false,
                      });
                    }
                  });
                  Navigator.of(context).pop();
                },
                child: Text(isEdit ? 'Сохранить' : 'Добавить'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _archiveAchievement(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Архивировать достижение?'),
        content: const Text('Вы уверены, что хотите отправить это достижение в архив?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                final idx = _achievements.indexWhere((e) => e['id'] == id);
                if (idx != -1) _achievements[idx]['isArchived'] = true;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Архивировать'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredAchievements;

    

    return Column(
      children: [
        // Поиск (без отступов, как в Courses)
        Row(
          children: [
            Expanded(
              child: SearchRow(
                controller: _searchController,
                hintText: 'Поиск по достижениям...',
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        SizedBox(height: 24),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events_rounded, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'Достижения не найдены',
                        style: TextStyle(
                          fontSize: 18,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final achievement = filtered[index];
                      return _buildAchievementCard(achievement, theme);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildAchievementCard(Map<String, dynamic> a, ThemeData theme) {
    return GestureDetector(
      onTap: () => _showForm(achievement: a),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: a['image'] != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(a['image'] as File, width: double.infinity, fit: BoxFit.cover))
                    : Container(
                        width: double.infinity,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: theme.dividerColor.withValues(alpha: 0.04)),
                        child: const Icon(Icons.emoji_events_rounded, size: 48),
                      ),
              ),
              const SizedBox(height: 12),
              Text(a['title'] ?? '', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
              const SizedBox(height: 6),
              Text(
                a['description'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.75)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(a['date'] ?? '', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                  const Spacer(),
                  IconButton(
                    tooltip: 'В архив',
                    onPressed: () => _archiveAchievement(a['id'] as int),
                    icon: const Icon(Icons.archive_outlined),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
