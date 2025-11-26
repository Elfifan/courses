import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../shared/search_row.dart';
import '../models/database_models.dart';
import '../repositories/achievement_repository.dart';

class AchievementsScreen extends StatefulWidget {
  final bool isDarkMode;

  const AchievementsScreen({super.key, required this.isDarkMode});

  @override
  _AchievementsScreenState createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<Achievement> _achievements = [];
  List<Achievement> _archivedAchievements = [];
  bool _isLoading = true;
  int _selectedTabIndex = 0;  // 0 = активные, 1 = архив

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    setState(() => _isLoading = true);
    try {
      final achievements = await AchievementRepository.getAllAchievements();
      final archived = await AchievementRepository.getArchivedAchievements();
      setState(() {
        _achievements = achievements;
        _archivedAchievements = archived;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    }
  }

  List<Achievement> get _filteredAchievements {
    final q = _searchController.text.trim().toLowerCase();
    final list = _selectedTabIndex == 0 ? _achievements : _archivedAchievements;
    if (q.isEmpty) return list;
    return list.where((a) {
      final name = a.name.toLowerCase();
      final desc = (a.description ?? '').toLowerCase();
      return name.contains(q) || desc.contains(q);
    }).toList();
  }

  void showForm({Achievement? achievement}) {
    _showForm(achievement: achievement);
  }

  void _showForm({Achievement? achievement}) {
    final isEdit = achievement != null;
    final _titleController = TextEditingController(text: achievement?.name ?? '');
    final _descController = TextEditingController(text: achievement?.description ?? '');
    List<int>? imageData = achievement?.imageData;
    File? pickedFile;
    bool _isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEdit ? 'Редактировать достижение' : 'Добавить достижение'),
            content: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
                        if (file != null) {
                          setState(() {
                            pickedFile = File(file.path);
                          });
                        }
                      },
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Theme.of(context).dividerColor, width: 2),
                          ),
                          child: pickedFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(pickedFile!, fit: BoxFit.cover),
                                )
                              : (imageData != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        Uint8List.fromList(imageData),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.broken_image, size: 48, color: Colors.red),
                                                const SizedBox(height: 8),
                                                Text('Ошибка загрузки'),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.image, size: 48, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                                          const SizedBox(height: 8),
                                          Text('Нажмите для выбора'),
                                        ],
                                      ),
                                    )),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Название *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'Описание',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : () async {
                        final title = _titleController.text.trim();
                        if (title.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Введите название')),
                          );
                          return;
                        }

                        setState(() => _isSaving = true);

                        try {
                          List<int>? uploadedImageData = imageData;

                          if (pickedFile != null) {
                            uploadedImageData = await AchievementRepository.fileToBytes(pickedFile!);
                          }

                          if (isEdit && achievement != null) {
                            await AchievementRepository.updateAchievement(
                              achievement.id,
                              name: title,
                              description: _descController.text.trim(),
                              imageData: uploadedImageData,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Достижение обновлено')),
                            );
                          } else {
                            await AchievementRepository.createAchievement(
                              name: title,
                              description: _descController.text.trim(),
                              imageData: uploadedImageData,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Достижение добавлено')),
                            );
                          }

                          _loadAchievements();
                          Navigator.of(context).pop();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Ошибка: $e')),
                          );
                        } finally {
                          setState(() => _isSaving = false);
                        }
                      },
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(isEdit ? 'Сохранить' : 'Добавить'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _archiveAchievement(Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Архивировать достижение?'),
        content: const Text('Достижение будет перемещено в архив.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await AchievementRepository.archiveAchievement(achievement.id);
                _loadAchievements();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Достижение архивировано')),
                );
              } catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Архивировать', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _restoreAchievement(Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Вернуть достижение?'),
        content: const Text('Достижение будет восстановлено из архива.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await AchievementRepository.restoreAchievement(achievement.id);
                _loadAchievements();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Достижение восстановлено')),
                );
              } catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Вернуть', style: TextStyle(color: Colors.white)),
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
        // Табы: Активные / Архив
        Row(
          children: [
            Expanded(
              child: SearchRow(
                controller: _searchController,
                hintText: 'Поиск по достижениям...',
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 16),
            // Табы
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.isDarkMode ? Color(0xFF30363D) : Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  _buildTab('Активные', 0, theme),
                  _buildTab('Архив', 1, theme),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Сетка достижений
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emoji_events_rounded, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text(
                            _selectedTabIndex == 0 ? 'Активные достижения не найдены' : 'Архив пуст',
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

Widget _buildTab(String label, int index, ThemeData theme) {
    final isActive = _selectedTabIndex == index;
    return MouseRegion(  // ← Добавьте это
      cursor: SystemMouseCursors.click,  // ← Курсор в виде руки
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? theme.primaryColor : Colors.transparent,
            borderRadius: index == 0
                ? BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8))
                : BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementCard(Achievement a, ThemeData theme) {
    final isArchived = !a.status;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: a.imageData != null && a.imageData!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        Uint8List.fromList(a.imageData!),
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: theme.dividerColor.withValues(alpha: 0.04),
                            ),
                            child: Icon(Icons.broken_image, size: 48, color: Colors.red.withValues(alpha: 0.5)),
                          );
                        },
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: theme.dividerColor.withValues(alpha: 0.04),
                      ),
                      child: const Icon(Icons.emoji_events_rounded, size: 48),
                    ),
            ),
            const SizedBox(height: 12),
            Text(a.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 6),
            Text(
              a.description ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.75)),
            ),
            const SizedBox(height: 8),
            if (isArchived)
              // Для архивированных достижений
              ElevatedButton.icon(
                onPressed: () => _restoreAchievement(a),
                icon: const Icon(Icons.unarchive, size: 16),
                label: const Text('Вернуть'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: Size(double.infinity, 36),
                ),
              )
            else
              // Для активных достижений
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showForm(achievement: a),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Редактировать'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  MouseRegion(  // ← Курсор для кнопки архива
                    cursor: SystemMouseCursors.click,
                    child: IconButton(
                      tooltip: 'Архивировать',
                      onPressed: () => _archiveAchievement(a),
                      icon: const Icon(Icons.archive_outlined),
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}