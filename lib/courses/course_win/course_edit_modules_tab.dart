import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../models/database_models.dart' as db_models;
import '../../services/supabase_service.dart';
import '../lessons/lesson_viewer_screen.dart';

class CourseEditModulesTab extends StatefulWidget {
  final int courseId;
  final String courseName;
  final String courseIcon;

  const CourseEditModulesTab({
    super.key,
    required this.courseId,
    required this.courseName,
    required this.courseIcon,
  });

  @override
  State<CourseEditModulesTab> createState() => _CourseEditModulesTabState();
}

class _CourseEditModulesTabState extends State<CourseEditModulesTab> {
  List<db_models.Module> _modules = [];
  Map<int, List<db_models.Submodule>> _submodules = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  Future<void> _loadModules() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final modulesData = await SupabaseService.client
          .from('module')
          .select()
          .eq('id_courses', widget.courseId)
          .order('order_module', ascending: true);

      Map<int, List<db_models.Submodule>> submodulesMap = {};

      for (var moduleData in modulesData) {
        final moduleId = moduleData['id'];
        final submodulesData = await SupabaseService.client
            .from('submodule')
            .select()
            .eq('id_module', moduleId)
            .order('order_submodule', ascending: true);

        submodulesMap[moduleId] = (submodulesData as List)
            .map((item) => db_models.Submodule.fromJson(item))
            .toList();
      }

      if (mounted) {
        setState(() {
          _modules = (modulesData as List)
              .map((item) => db_models.Module.fromJson(item))
              .toList();
          _submodules = submodulesMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки модулей: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Модули курса',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showAddModuleDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Добавить модуль'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _modules.isEmpty
                    ? const Center(child: Text('Модулей нет'))
                    : ListView.builder(
                        itemCount: _modules.length,
                        itemBuilder: (context, index) {
                          final module = _modules[index];
                          final submodules = _submodules[module.id] ?? [];
                          return _buildModuleCard(module, submodules, index);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(
    db_models.Module module,
    List<db_models.Submodule> submodules,
    int moduleIndex,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${module.orderModule}. ${module.name ?? 'Без названия'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteModule(module.id);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Удалить', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showAddTheoryDialog(module.id),
                  icon: const Icon(Icons.menu_book, size: 18),
                  label: const Text('Добавить теорию'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _showAddTaskDialog(module.id),
                  icon: const Icon(Icons.assignment, size: 18),
                  label: const Text('Добавить задание'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (submodules.isEmpty)
              Text(
                'Нет подмодулей',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: submodules.length,
                itemBuilder: (context, index) {
                  final submodule = submodules[index];
                  return _buildSubmoduleItem(submodule, module.id);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmoduleItem(
    db_models.Submodule submodule,
    int moduleId,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LessonViewerScreen(
              submoduleId: submodule.id,
              courseName: widget.courseName,
              courseIcon: widget.courseIcon,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Icon(
                  Icons.play_circle_outline,
                  color: Theme.of(context).primaryColor,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    submodule.name ?? 'Без названия',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (submodule.leadTime != null)
                    Text(
                      '${submodule.leadTime} мин',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteSubmodule(submodule.id, moduleId);
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Удалить', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddModuleDialog() {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить модуль'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Название модуля',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book),
              ),
              validator: (value) =>
                  value?.isEmpty == true ? 'Введите название' : null,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await _addModule(nameController.text);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _showAddTheoryDialog(int moduleId) {
    String? selectedFilePath;
    final nameController = TextEditingController();
    final leadTimeController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool _isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Добавить теоретический материал'),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Выбор markdown файла
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Markdown документ',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (selectedFilePath != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle,
                                          color: Colors.green, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          selectedFilePath!
                                              .split('/')
                                              .last,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result =
                                  await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['md', 'markdown', 'txt'],
                              );

                              if (result != null) {
                                setState(() {
                                  selectedFilePath =
                                      result.files.single.path;
                                });
                              }
                            },
                            icon: const Icon(Icons.upload_file, size: 18),
                            label: const Text('Выбрать файл'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Название урока',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) =>
                          value?.isEmpty == true ? 'Введите название' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: leadTimeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Время изучения (мин)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.schedule),
                        hintText: 'Например: 15',
                      ),
                      validator: (value) =>
                          value?.isEmpty == true ? 'Введите время' : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isUploading ? null : () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: _isUploading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate() &&
                          selectedFilePath != null) {
                        setState(() => _isUploading = true);
                        await _addSubmodule(
                          moduleId,
                          nameController.text,
                          int.parse(leadTimeController.text),
                          selectedFilePath!,
                        );
                        if (mounted) {
                          Navigator.pop(context);
                        }
                      } else if (selectedFilePath == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Выберите markdown файл')),
                        );
                      }
                    },
              child: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog(int moduleId) {
    String? selectedFilePath;
    final nameController = TextEditingController();
    final leadTimeController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool _isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Добавить задание'),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Markdown документ',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (selectedFilePath != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle,
                                          color: Colors.green, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          selectedFilePath!
                                              .split('/')
                                              .last,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result =
                                  await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['md', 'markdown', 'txt'],
                              );

                              if (result != null) {
                                setState(() {
                                  selectedFilePath =
                                      result.files.single.path;
                                });
                              }
                            },
                            icon: const Icon(Icons.upload_file, size: 18),
                            label: const Text('Выбрать файл'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Название задания',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.assignment),
                      ),
                      validator: (value) =>
                          value?.isEmpty == true ? 'Введите название' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: leadTimeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Время выполнения (мин)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timer),
                        hintText: 'Например: 30',
                      ),
                      validator: (value) =>
                          value?.isEmpty == true ? 'Введите время' : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isUploading ? null : () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: _isUploading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate() &&
                          selectedFilePath != null) {
                        setState(() => _isUploading = true);
                        await _addSubmodule(
                          moduleId,
                          nameController.text,
                          int.parse(leadTimeController.text),
                          selectedFilePath!,
                        );
                        if (mounted) {
                          Navigator.pop(context);
                        }
                      } else if (selectedFilePath == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Выберите markdown файл')),
                        );
                      }
                    },
              child: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addModule(String name) async {
    try {
      final nextOrder = _modules.isEmpty
          ? 1
          : (_modules.map((m) => m.orderModule ?? 0).reduce((a, b) => a > b ? a : b)) + 1;

      await SupabaseService.client.from('module').insert({
        'id_courses': widget.courseId,
        'name': name,
        'order_module': nextOrder,
        'status': true,
      });

      if (mounted) {
        _loadModules();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Модуль "$name" добавлен')),
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

Future<void> _addSubmodule(
  int moduleId,
  String name,
  int leadTime,
  String filePath,
) async {
  try {
    // Сначала получаем order_module текущего модуля
    final moduleData = await SupabaseService.client
        .from('module')
        .select('order_module')
        .eq('id', moduleId)
        .single();
    
    final orderModule = moduleData['order_module'] as int? ?? 1;

    final file = File(filePath);
    final fileExtension = file.path.split('.').last;
    final fileBytes = await file.readAsBytes();

    // ✅ Генерируем безопасное имя файла
    final safeFileName = 'submodule_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    
    // ✅ Вложенные папки: c1/module2/submodule_123.md
    final storagePath = 'c${widget.courseId}/module$orderModule/$safeFileName';
    
    print('📤 Загружаем файл: $storagePath');

    // ✅ Загружаем файл в Storage
    await SupabaseService.client.storage
        .from('course-files')
        .uploadBinary(storagePath, fileBytes);

    // ✅ Создаём подписанный URL, который будет работать вечно
    // Срок: 100 лет (525600 часов * 100 = 52560000 часов)
    final signedUrl = await SupabaseService.client.storage
        .from('course-files')
        .createSignedUrl(storagePath, 5256000);

    print('✅ URL готов: $signedUrl');

    // Определяем order_submodule
    final submodules = _submodules[moduleId] ?? [];
    final nextOrder = submodules.isEmpty
        ? 1
        : (submodules.map((s) => s.orderSubmodule ?? 0).reduce((a, b) => a > b ? a : b)) + 1;

    // ✅ Сохраняем в БД с подписанным URL
    await SupabaseService.client.from('submodule').insert({
      'id_module': moduleId,
      'name': name,
      'lead_time': leadTime,
      'content': signedUrl, 
      'order_submodule': nextOrder,
      'status': true,
    });

    if (mounted) {
      _loadModules();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Подмодуль "$name" добавлен')),
      );
    }
  } catch (e) {
    print('❌ Ошибка: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }
}

  Future<void> _deleteModule(int moduleId) async {
    try {
      await SupabaseService.client
          .from('module')
          .delete()
          .eq('id', moduleId);

      if (mounted) {
        _loadModules();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Модуль удален')),
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

  Future<void> _deleteSubmodule(int submoduleId, int moduleId) async {
    try {
      await SupabaseService.client
          .from('submodule')
          .delete()
          .eq('id', submoduleId);

      if (mounted) {
        _loadModules();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Подмодуль удален')),
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
}
