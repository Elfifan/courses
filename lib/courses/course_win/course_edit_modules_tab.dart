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
  Map<int, List<db_models.Test>> _tests = {};
  Map<int, bool> _expandedModules = {}; // ← НОВОЕ: свернутость модулей
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
      Map<int, List<db_models.Test>> testsMap = {};
      Map<int, bool> expandedMap = {};

      for (var moduleData in modulesData) {
        final moduleId = moduleData['id'];
        expandedMap[moduleId] = _expandedModules[moduleId] ?? true; // По умолчанию развернуто

        final submodulesData = await SupabaseService.client
            .from('submodule')
            .select()
            .eq('id_module', moduleId)
            .order('order_submodule', ascending: true);

        submodulesMap[moduleId] = (submodulesData as List)
            .map((item) => db_models.Submodule.fromJson(item))
            .toList();

        for (var submoduleData in submodulesData) {
          final submoduleId = submoduleData['id'];
          final testsData = await SupabaseService.client
              .from('submodule_test')
              .select('id_test, test(*)')
              .eq('id_submodule', submoduleId)
              .order('order_test', ascending: true);

          testsMap[submoduleId] = (testsData as List)
              .map((item) {
                final testData = item['test'] as Map<String, dynamic>;
                return db_models.Test.fromJson(testData);
              })
              .toList();
        }
      }

      if (mounted) {
        setState(() {
          _modules = (modulesData as List)
              .map((item) => db_models.Module.fromJson(item))
              .toList();
          _submodules = submodulesMap;
          _tests = testsMap;
          _expandedModules = expandedMap;
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
    final isExpanded = _expandedModules[module.id] ?? true;

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
                // ← НОВОЕ: Кнопка свернуть/развернуть
                IconButton(
                  icon: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 28,
                  ),
                  onPressed: () {
                    setState(() {
                      _expandedModules[module.id] = !isExpanded;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
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
            // ← НОВОЕ: Контент отображается только если развернуто
            if (isExpanded) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showAddTheoryDialog(module.id),
                    icon: const Icon(Icons.menu_book, size: 18),
                    label: const Text('Добавить теорию'),
                  ),
                  // ← Убрали кнопку "Добавить задание"
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
                    return _buildSubmoduleItem(
                      submodule,
                      module.id,
                      module.orderModule ?? 1,
                      index + 1, // ← Номер подмодуля в модуле
                    );
                  },
                ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildSubmoduleItem(
    db_models.Submodule submodule,
    int moduleId,
    int moduleOrder,
    int submoduleNumber,
  ) {
    final tests = _tests[submodule.id] ?? [];

    return Column(
      children: [
        GestureDetector(
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
                // ← НОВОЕ: Нумерация (1.1, 1.2 и т.д.)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '$moduleOrder.$submoduleNumber',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
                    } else if (value == 'add_test') {
                      _showAddTestDialog(submodule.id);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'add_test',
                      child: Row(
                        children: [
                          Icon(Icons.quiz, size: 18),
                          SizedBox(width: 8),
                          Text('Добавить тест'),
                        ],
                      ),
                    ),
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
        ),
        if (tests.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(left: 40, top: 8, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Тесты (${tests.length})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                ...tests.map((test) => GestureDetector(
                  onTap: () => _showEditTestDialog(test, submodule.id), // ← НОВОЕ: редактирование
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.quiz, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                test.question ?? 'Вопрос',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Ответ: ${test.rightAnswer}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton(
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              child: const Text('Удалить'),
                              onTap: () => _deleteTest(test.id, submodule.id),
                            ),
                          ],
                          icon: const Icon(Icons.more_vert, size: 16),
                        ),
                      ],
                    ),
                  ),
                )),
              ],
            ),
          ),
      ],
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
                                          selectedFilePath!.split('/').last,
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
                                  selectedFilePath = result.files.single.path;
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите время';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Можно вводить только цифры';
                        }
                        return null;
                      },
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
                          const SnackBar(
                              content: Text('Выберите markdown файл')),
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

  void _showAddTestDialog(int submoduleId) {
    final formKey = GlobalKey<FormState>();
    final questionController = TextEditingController();
    final difficultyController = TextEditingController();

    final List<TextEditingController> answerControllers = [
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
    ];

    int? selectedCorrectAnswer;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Добавить тест'),
          content: SizedBox(
            width: 600,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: questionController,
                      decoration: const InputDecoration(
                        labelText: 'Вопрос',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.help_outline),
                      ),
                      maxLines: 3,
                      validator: (value) =>
                          value?.isEmpty == true ? 'Введите вопрос' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: difficultyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Сложность (1-5)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.star),
                        hintText: '1',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Выберите один правильный ответ',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(4, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: index,
                              groupValue: selectedCorrectAnswer,
                              onChanged: (value) {
                                setState(() => selectedCorrectAnswer = value);
                              },
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: answerControllers[index],
                                decoration: InputDecoration(
                                  labelText: 'Вариант ${index + 1}',
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                                validator: (value) => value?.isEmpty == true
                                    ? 'Введите ответ'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      if (selectedCorrectAnswer == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Выберите правильный ответ')),
                        );
                        return;
                      }

                      setState(() => isLoading = true);
                      await _addTest(
                        submoduleId,
                        questionController.text,
                        int.tryParse(difficultyController.text) ?? 1,
                        answerControllers,
                        selectedCorrectAnswer!,
                      );
                      if (mounted) Navigator.pop(context);
                    },
              child: isLoading
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

  // ← НОВОЕ: Редактирование теста
  void _showEditTestDialog(db_models.Test test, int submoduleId) {
    final formKey = GlobalKey<FormState>();
    final questionController = TextEditingController(text: test.question);
    final difficultyController = TextEditingController(
      text: test.difficulty?.toString() ?? '1',
    );

    final List<TextEditingController> answerControllers = [
      TextEditingController(text: test.rightAnswer),
      TextEditingController(text: test.wrongAnswer1),
      TextEditingController(text: test.wrongAnswer2),
      TextEditingController(text: test.wrongAnswer3),
    ];

    int? selectedCorrectAnswer = 0; // По умолчанию правильный ответ первый
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Редактировать тест'),
          content: SizedBox(
            width: 600,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: questionController,
                      decoration: const InputDecoration(
                        labelText: 'Вопрос',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.help_outline),
                      ),
                      maxLines: 3,
                      validator: (value) =>
                          value?.isEmpty == true ? 'Введите вопрос' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: difficultyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Сложность (1-5)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.star),
                        hintText: '1',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Выберите один правильный ответ',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(4, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: index,
                              groupValue: selectedCorrectAnswer,
                              onChanged: (value) {
                                setState(() => selectedCorrectAnswer = value);
                              },
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: answerControllers[index],
                                decoration: InputDecoration(
                                  labelText: 'Вариант ${index + 1}',
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                                validator: (value) => value?.isEmpty == true
                                    ? 'Введите ответ'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      if (selectedCorrectAnswer == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Выберите правильный ответ')),
                        );
                        return;
                      }

                      setState(() => isLoading = true);
                      await _updateTest(
                        test.id,
                        questionController.text,
                        int.tryParse(difficultyController.text) ?? 1,
                        answerControllers,
                        selectedCorrectAnswer!,
                      );
                      if (mounted) Navigator.pop(context);
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Сохранить'),
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
      final moduleData = await SupabaseService.client
          .from('module')
          .select('order_module')
          .eq('id', moduleId)
          .single();

      final orderModule = moduleData['order_module'] as int? ?? 1;

      final file = File(filePath);
      final fileExtension = file.path.split('.').last;
      final fileBytes = await file.readAsBytes();

      final safeFileName = 'submodule_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final storagePath = 'c${widget.courseId}/module$orderModule/$safeFileName';

      print('📤 Загружаем файл: $storagePath');

      await SupabaseService.client.storage
          .from('course-files')
          .uploadBinary(storagePath, fileBytes);

      final signedUrl = await SupabaseService.client.storage
          .from('course-files')
          .createSignedUrl(storagePath, 5256000);

      print('✅ URL готов: $signedUrl');

      final submodules = _submodules[moduleId] ?? [];
      final nextOrder = submodules.isEmpty
          ? 1
          : (submodules.map((s) => s.orderSubmodule ?? 0).reduce((a, b) => a > b ? a : b)) + 1;

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

  Future<void> _addTest(
  int submoduleId,
  String question,
  int difficulty,
  List<TextEditingController> answerControllers,
  int correctAnswerIndex,
) async {
  try {
    final existingTests = await SupabaseService.client
        .from('submodule_test')
        .select('order_test')
        .eq('id_submodule', submoduleId)
        .order('order_test', ascending: false)
        .limit(1);

    int nextOrder = 1;
    if (existingTests.isNotEmpty) {
      nextOrder = (existingTests[0]['order_test'] as int? ?? 0) + 1;
    }

    // ← ИСПРАВЛЕНО: Правильное распределение ответов
    String rightAnswer = answerControllers[correctAnswerIndex].text;
    
    // Собираем неправильные ответы в правильном порядке
    List<String> wrongAnswers = [];
    for (int i = 0; i < 4; i++) {
      if (i != correctAnswerIndex) {
        wrongAnswers.add(answerControllers[i].text);
      }
    }

    final testResponse = await SupabaseService.client
        .from('test')
        .insert({
          'question': question,
          'right_answer': rightAnswer,
          'wrong_answer1': wrongAnswers[0],
          'wrong_answer2': wrongAnswers[1],
          'wrong_answer3': wrongAnswers[2],
          'difficulty': difficulty,
          'status': true,
        })
        .select()
        .single();

    final testId = testResponse['id'];

    await SupabaseService.client.from('submodule_test').insert({
      'id_submodule': submoduleId,
      'id_test': testId,
      'order_test': nextOrder,
    });

    if (mounted) {
      _loadModules();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Тест добавлен')),
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

  // ← НОВОЕ: Обновление теста
  Future<void> _updateTest(
  int testId,
  String question,
  int difficulty,
  List<TextEditingController> answerControllers,
  int correctAnswerIndex,
) async {
  try {
    // ← ИСПРАВЛЕНО: Правильное распределение ответов
    String rightAnswer = answerControllers[correctAnswerIndex].text;
    
    // Собираем неправильные ответы в правильном порядке
    List<String> wrongAnswers = [];
    for (int i = 0; i < 4; i++) {
      if (i != correctAnswerIndex) {
        wrongAnswers.add(answerControllers[i].text);
      }
    }

    await SupabaseService.client.from('test').update({
      'question': question,
      'right_answer': rightAnswer,
      'wrong_answer1': wrongAnswers[0],
      'wrong_answer2': wrongAnswers[1],
      'wrong_answer3': wrongAnswers[2],
      'difficulty': difficulty,
    }).eq('id', testId);

    if (mounted) {
      _loadModules();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Тест обновлен')),
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


  Future<void> _deleteModule(int moduleId) async {
    try {
      await SupabaseService.client.from('module').delete().eq('id', moduleId);

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

  Future<void> _deleteTest(int testId, int submoduleId) async {
    try {
      await SupabaseService.client
          .from('submodule_test')
          .delete()
          .eq('id_test', testId);

      await SupabaseService.client.from('test').delete().eq('id', testId);

      if (mounted) {
        _loadModules();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Тест удален')),
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

  @override
  void dispose() {
    super.dispose();
  }
}
