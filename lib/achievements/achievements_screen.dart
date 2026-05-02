import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/app_components.dart';
import '../shared/search_row.dart';
import '../models/database_models.dart';
import '../repositories/achievement_repository.dart';

class AchievementsScreen extends StatefulWidget {
  final bool isDarkMode;
  const AchievementsScreen({super.key, required this.isDarkMode});
  @override
  _AchievementsScreenState createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  late TabController _tabController;

  List<Achievement> _allAchievements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Обновляем данные когда приложение возвращается из фона
      _loadData(forceRefresh: true);
    }
  }

  /// Загрузка данных с возможностью принудительного обновления
  Future<void> _loadData({bool forceRefresh = false}) async {
    if (!mounted) return;
    
    // Не показываем индикатор загрузки если это не первая загрузка
    if (_allAchievements.isEmpty) {
      setState(() => _isLoading = true);
    }
    
    try {
      final results = await Future.wait([
        AchievementRepository.getAllAchievements(forceRefresh: forceRefresh),
        AchievementRepository.getArchivedAchievements(forceRefresh: forceRefresh),
      ]);

      if (mounted) {
        setState(() {
          _allAchievements = [...results[0], ...results[1]];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки данных: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        if (_allAchievements.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка загрузки: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  List<Achievement> _getFilteredList() {
    final bool targetStatus = _tabController.index == 0;
    final query = _searchController.text.toLowerCase();
    return _allAchievements.where((a) {
      final matchesStatus = a.status == targetStatus;
      final matchesQuery =
          a.name.toLowerCase().contains(query) ||
          (a.description ?? '').toLowerCase().contains(query);
      return matchesStatus && matchesQuery;
    }).toList();
  }

  /// ФОРМА СОЗДАНИЯ / РЕДАКТИРОВАНИЯ
/// ФОРМА СОЗДАНИЯ / РЕДАКТИРОВАНИЯ
void _showForm({Achievement? achievement}) async {
  final isEdit = achievement != null;
  final titleController = TextEditingController(text: achievement?.name ?? '');
  final descController = TextEditingController(text: achievement?.description ?? '');
  
  File? selectedFile;
  final String? currentImageUrl = achievement?.imageUrl;

  // Показываем диалог и ждем результат
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: AppStyles.cardRadius),
        title: Text(isEdit ? 'Редактировать' : 'Новая награда', style: AppStyles.h1),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Обложка достижения', style: AppStyles.label),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    try {
                      final XFile? file = await _picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 85,
                      );
                      if (file != null) {
                        setDialogState(() => selectedFile = File(file.path));
                      }
                    } catch (e) {
                      debugPrint('Ошибка выбора изображения: $e');
                    }
                  },
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.bgLight,
                      borderRadius: AppStyles.mainRadius,
                      image: selectedFile != null
                          ? DecorationImage(
                              image: FileImage(selectedFile!),
                              fit: BoxFit.cover,
                            )
                          : currentImageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(currentImageUrl),
                                  fit: BoxFit.cover,
                                  onError: (exception, stackTrace) {},
                                )
                              : null,
                    ),
                    child: (selectedFile == null && currentImageUrl == null)
                        ? const Icon(Icons.add_photo_alternate_outlined,
                            color: AppColors.primaryPurple, size: 40)
                        : null,
                  ),
                ),
                const SizedBox(height: 24),
                Text('Название', style: AppStyles.label),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  style: AppStyles.body,
                  decoration: KodixComponents.textFieldDecoration(hintText: 'Введите название...'),
                ),
                const SizedBox(height: 20),
                Text('Описание', style: AppStyles.label),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  style: AppStyles.body,
                  decoration: KodixComponents.textFieldDecoration(hintText: 'За какие заслуги выдается?'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), // Закрыть без сохранения
            child: Text('Отмена', style: AppStyles.label.copyWith(color: AppColors.textGrey)),
          ),
          SizedBox(
            width: 140,
            child: KodixComponents.primaryButton(
              onPressed: () {
                // Валидация
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Введите название достижения'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                
                // Закрываем диалог и передаем данные для сохранения
                Navigator.pop(dialogContext, {
                  'name': titleController.text.trim(),
                  'description': descController.text.trim(),
                  'selectedFile': selectedFile,
                });
              },
              child: const Text('Сохранить'),
            ),
          ),
        ],
      ),
    ),
  );

  // Если результат не null - значит нажали "Сохранить"
  if (result != null && mounted) {
    // Показываем индикатор сохранения на основном экране
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Сохранение...'),
          ],
        ),
        backgroundColor: AppColors.primaryPurple,
        duration: Duration(seconds: 1),
      ),
    );

    try {
      if (isEdit) {
        await AchievementRepository.updateAchievement(
          achievement!.id,
          name: result['name'],
          description: result['description'].isEmpty ? null : result['description'],
          imageFile: result['selectedFile'],
        );
      } else {
        await AchievementRepository.createAchievement(
          name: result['name'],
          description: result['description'].isEmpty ? null : result['description'],
          imageFile: result['selectedFile'],
        );
      }
      
      // Обновляем данные
      await _loadData(forceRefresh: true);
      
      // Показываем успешное уведомление
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Достижение обновлено' : 'Достижение создано'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Ошибка сохранения: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
  /// Мгновенное архивирование/восстановление
  Future<void> _toggleArchiveStatus(Achievement achievement) async {
    try {
      if (achievement.status) {
        await AchievementRepository.archiveAchievement(achievement.id);
      } else {
        await AchievementRepository.restoreAchievement(achievement.id);
      }
      
      // Мгновенно обновляем UI
      setState(() {
        final index = _allAchievements.indexWhere((a) => a.id == achievement.id);
        if (index != -1) {
          _allAchievements[index] = Achievement(
            id: achievement.id,
            createdAt: achievement.createdAt,
            name: achievement.name,
            description: achievement.description,
            status: !achievement.status,
            imageUrl: achievement.imageUrl,
          );
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            achievement.status ? 'Достижение архивировано' : 'Достижение восстановлено',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Ошибка смены статуса: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Публичный метод для открытия формы из внешних источников
  void showForm({Achievement? achievement}) {
    _showForm(achievement: achievement);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SearchRow(
                  controller: _searchController,
                  hintText: 'Поиск по наградам...',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 20),
              _buildTabSelector(),
              const SizedBox(width: 20),
              SizedBox(
                width: 50,
                child: KodixComponents.primaryButton(
                  onPressed: () => _showForm(),
                  child: const Text('+'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple))
                : _buildGridView(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      height: 50,
      width: 280,
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        labelColor: AppColors.primaryPurple,
        unselectedLabelColor: AppColors.textGrey,
        labelStyle: AppStyles.label.copyWith(fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: 'Активные'),
          Tab(text: 'Архив'),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    final list = _getFilteredList();
    if (list.isEmpty) {
      return Center(child: Text('Список пуст', style: AppStyles.label));
    }
    return RefreshIndicator(
      onRefresh: () => _loadData(forceRefresh: true),
      color: AppColors.primaryPurple,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 320,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 0.85,
        ),
        itemCount: list.length,
        itemBuilder: (context, i) => _achievementCard(list[i]),
      ),
    );
  }

  Widget _achievementCard(Achievement a) {
    return KodixComponents.cardContainer(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                color: AppColors.bgLight,
              ),
              clipBehavior: Clip.hardEdge,
              child: a.imageUrl != null && a.imageUrl!.isNotEmpty
                  ? Image.network(
                      a.imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                            color: AppColors.primaryPurple,
                            strokeWidth: 2,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                            child: Icon(Icons.broken_image, color: AppColors.primaryPurple),
                          ),
                    )
                  : const Center(
                      child: Icon(Icons.workspace_premium_outlined, size: 48, color: AppColors.primaryPurple),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.name, style: AppStyles.body.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  a.description ?? '',
                  style: AppStyles.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.mode_edit_outline_outlined, color: AppColors.primaryPurple, size: 22),
                      onPressed: () => _showForm(achievement: a),
                    ),
                    IconButton(
                      icon: Icon(
                        a.status ? Icons.archive_outlined : Icons.unarchive_outlined,
                        color: a.status ? Colors.orangeAccent : Colors.greenAccent,
                        size: 22,
                      ),
                      onPressed: () => _toggleArchiveStatus(a),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _searchController.dispose();
    AchievementRepository.clearCache(); // Очищаем кэш при уходе
    super.dispose();
  }
}