import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class AchievementsScreen extends StatefulWidget {
  final bool isDarkMode;

  const AchievementsScreen({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _achievements = [
    {
      'id': 1,
      'title': '1212121',
      'description': 'Зарегистрирован первый студент на платформе',
      'image': null,
      'date': '15 марта 2024',
      'isArchived': false,
    },
    {
      'id': 2,
      'title': 'jkkkklkklkl',
      'description': 'Достигнуто 100 зарегистрированных студентов',
      'image': null,
      'date': '25 мая 2024',
      'isArchived': false,
    },
  ];

  List<Map<String, dynamic>> get _filteredAchievements {
    final query = _searchController.text.toLowerCase();
    return _achievements.where((achievement) {
      if (achievement['isArchived'] == true) return false;
      final title = (achievement['title'] as String).toLowerCase();
      final description = (achievement['description'] as String).toLowerCase();
      return title.contains(query) || description.contains(query);
    }).toList();
  }

  int? _editingId;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _selectedImage;

  void _showForm({Map<String, dynamic>? achievement}) {
      if (achievement != null) {
        _editingId = achievement['id'];
        _titleController.text = achievement['title'];
        _descriptionController.text = achievement['description'];
        _selectedImage = achievement['image'];
      } else {
        _editingId = null;
        _titleController.clear();
        _descriptionController.clear();
        _selectedImage = null;
      }

      showDialog(
          context: context,
          builder: (context) {
            return Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 540,
                ),
                child: Material(
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.hardEdge,
                  color: Theme.of(context).dialogBackgroundColor,
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: SingleChildScrollView(
                        child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                              if (image != null) {
                                setState(() {
                                  _selectedImage = File(image.path);
                                });
                              }
                            },
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey),
                              ),
                              child: _selectedImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(_selectedImage!,
                                          width: 200, height: 200, fit: BoxFit.cover),
                                    )
                                  : Icon(Icons.image, size: 70, color: Colors.grey[400]),
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(labelText: 'Название'),
                            validator: (value) => value == null || value.isEmpty ? 'Введите название' : null,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(labelText: 'Описание'),
                            maxLines: 5,
                            validator: (value) => value == null || value.isEmpty ? 'Введите описание' : null,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 28),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Отмена', style: TextStyle(fontSize: 17)),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    final currentDate = _editingId == null
                                        ? _getTodayDate()
                                        : achievement?['date'] ?? _getTodayDate();

                                    if (_editingId == null) {
                                      final newAchievement = {
                                        'id': _achievements.isEmpty
                                            ? 1
                                            : _achievements
                                                .map((e) => e['id'] as int)
                                                .reduce((a, b) => a > b ? a : b) + 1,
                                        'title': _titleController.text,
                                        'description': _descriptionController.text,
                                        'image': _selectedImage,
                                        'date': currentDate,
                                        'isArchived': false,
                                      };
                                      setState(() {
                                        _achievements.add(newAchievement);
                                      });
                                    } else {
                                      setState(() {
                                        final index = _achievements.indexWhere((e) => e['id'] == _editingId);
                                        if (index != -1) {
                                          _achievements[index] = {
                                            'id': _editingId,
                                            'title': _titleController.text,
                                            'description': _descriptionController.text,
                                            'image': _selectedImage,
                                            'date': currentDate,
                                            'isArchived': false,
                                          };
                                        }
                                      });
                                    }
                                    Navigator.of(context).pop();
                                  }
                                },
                                child: Text(_editingId == null ? 'Добавить' : 'Сохранить',
                                  style: const TextStyle(fontSize: 18),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),
                  ),
                ),
              ),
            );
          });
    }

  String _getTodayDate() {
    final now = DateTime.now();
    const months = [
      'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    return '${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]} ${now.year}';
  }

  void _archiveAchievement(int id) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Архивировать достижение?'),
              content: const Text('Вы уверены, что хотите отправить это достижение в архив? Это действие можно отменить в будущем.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      final index = _achievements.indexWhere((e) => e['id'] == id);
                      if (index != -1) {
                        _achievements[index]['isArchived'] = true;
                      }
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Архивировать'),
                ),
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredAchievements;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 20),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Поиск по достижениям...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 18),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Новое достижение', style: TextStyle(fontSize: 16)),
                  onPressed: () => _showForm(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text('Достижения не найдены', style: TextStyle(fontSize: 18)),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final achievement = filtered[index];
                        return ListTile(
                          leading: achievement['image'] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(achievement['image'],
                                      width: 48, height: 48, fit: BoxFit.cover),
                                )
                              : Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.grey[200],
                                  ),
                                  child: Icon(Icons.emoji_events_rounded,
                                      color: theme.primaryColor, size: 28),
                                ),
                          title: Text(
                            achievement['title'],
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          subtitle: Text(
                            '${achievement['description']}\nДата: ${achievement['date']}',
                            style: const TextStyle(height: 1.35, fontSize: 14),
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showForm(achievement: achievement);
                              } else if (value == 'archive') {
                                _archiveAchievement(achievement['id']);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                  value: 'edit', child: Text('Редактировать')),
                              const PopupMenuItem(
                                  value: 'archive', child: Text('Архивировать')),
                            ],
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}
