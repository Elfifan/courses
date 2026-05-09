import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../../models/database_models.dart' as db_models;
import '../../services/supabase_service.dart';
import '../lessons/lesson_viewer_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_components.dart';

class CourseEditModulesTab extends StatefulWidget {
  final int courseId;
  final String courseName;
  final String courseIcon;
  final bool readOnly;

  const CourseEditModulesTab({
    super.key,
    required this.courseId,
    required this.courseName,
    required this.courseIcon,
    this.readOnly = false,
  });

  @override
  State<CourseEditModulesTab> createState() => _CourseEditModulesTabState();
}

class _CourseEditModulesTabState extends State<CourseEditModulesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<db_models.Module> _modules = [];
  Map<int, List<db_models.Submodule>> _submodules = {};
  Map<int, List<db_models.Test>> _tests = {};
  Map<int, List<Map<String, dynamic>>> _practicalTasks = {};
  Map<int, bool> _expandedModules = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  bool _isPerformingLoad = false;

  Future<void> _loadModules() async {
    if (!mounted || _isPerformingLoad) return;

    setState(() {
      _isLoading = true;
      _isPerformingLoad = true;
    });

    try {
      final data = await SupabaseService.safeDbCall(
        () => SupabaseService.client
            .from('module')
            .select('''
            *,
            submodule (
              *,
              submodule_test (
                order_test,
                test (*)
              ),
              practical_task (*)
            )
          ''')
            .eq('id_courses', widget.courseId)
            .timeout(const Duration(seconds: 5)),
      );

      if (data == null) throw 'Нет ответа от сервера (Timeout)';

      Map<int, List<db_models.Submodule>> submodulesMap = {};
      Map<int, List<db_models.Test>> testsMap = {};
      Map<int, List<Map<String, dynamic>>> tasksMap = {};
      Map<int, bool> expandedMap = {};
      List<db_models.Module> modulesList = [];

      for (var moduleData in (data as List)) {
        final moduleId = moduleData['id'];
        expandedMap[moduleId] = _expandedModules[moduleId] ?? true;

        modulesList.add(db_models.Module.fromJson(moduleData));

        final submodulesRaw = moduleData['submodule'] as List? ?? [];
        final submodulesList = List<Map<String, dynamic>>.from(submodulesRaw);

        submodulesList.sort(
          (a, b) =>
              (a['order_submodule'] ?? 0).compareTo(b['order_submodule'] ?? 0),
        );

        submodulesMap[moduleId] = submodulesList
            .map((item) => db_models.Submodule.fromJson(item))
            .toList();

        for (var subData in submodulesList) {
          final subId = subData['id'];

          final testsRaw = subData['submodule_test'] as List? ?? [];
          final testsData = testsRaw
              .where((t) => t['test'] != null)
              .map(
                (t) =>
                    db_models.Test.fromJson(t['test'] as Map<String, dynamic>),
              )
              .toList();

          testsData.sort((a, b) => a.id.compareTo(b.id));
          testsMap[subId] = testsData;

          final tasksRaw = subData['practical_task'] as List? ?? [];
          final tasksData = tasksRaw
              .where((t) => t['status'] == true)
              .map((t) => t as Map<String, dynamic>)
              .toList();

          tasksData.sort(
            (a, b) => (a['order_task'] ?? 0).compareTo(b['order_task'] ?? 0),
          );
          tasksMap[subId] = tasksData;
        }
      }

      modulesList.sort(
        (a, b) => (a.orderModule ?? 0).compareTo(b.orderModule ?? 0),
      );

      if (mounted) {
        setState(() {
          _modules = modulesList;
          _submodules = submodulesMap;
          _tests = testsMap;
          _practicalTasks = tasksMap;
          _expandedModules = expandedMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки модулей: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } finally {
      _isPerformingLoad = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Программа обучения', style: AppStyles.h1)),
              if (!widget.readOnly)
                KodixComponents.primaryButton(
                  width: 200,
                  height: 48,
                  onPressed: () => _showAddModuleDialog(),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Добавить модуль',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryPurple,
                    ),
                  )
                : _modules.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.layers_clear_rounded,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'В этом курсе еще нет модулей',
                          style: AppStyles.label,
                        ),
                      ],
                    ),
                  )
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

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppStyles.cardRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          onExpansionChanged: (val) =>
              setState(() => _expandedModules[module.id] = val),
          title: Text(
            'Модуль ${module.orderModule}: ${module.name ?? 'Без названия'}',
            style: AppStyles.h1,
          ),
          trailing: widget.readOnly
              ? null
              : IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => _deleteModule(module.id),
                ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            if (!widget.readOnly) ...[
              const Divider(height: 1, color: AppColors.bgLight),
              const SizedBox(height: 16),
              Row(
                children: [
                  KodixComponents.secondaryButton(
                    onPressed: () => _showAddTheoryDialog(module.id),
                    icon: Icons.menu_book_rounded,
                    height: 40,
                    child: const Text(
                      'Добавить теорию',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (submodules.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Подмодули еще не добавлены',
                  style: AppStyles.label,
                ),
              )
            else
              ...submodules.asMap().entries.map((entry) {
                return _buildSubmoduleItem(
                  entry.value,
                  module.id,
                  module.orderModule ?? 1,
                  entry.key + 1,
                );
              }),
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
    final practicalTasks = _practicalTasks[submodule.id] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.bgLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.bgLight),
          ),
          child: Column(
            children: [
              ListTile(
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
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '$moduleOrder.$submoduleNumber',
                      style: const TextStyle(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  submodule.name ?? 'Без названия',
                  style: AppStyles.body.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: submodule.leadTime != null
                    ? Text('${submodule.leadTime} мин', style: AppStyles.label)
                    : null,
                trailing: widget.readOnly
                    ? null
                    : PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, size: 20),
                        onSelected: (val) {
                          if (val == 'delete')
                            _deleteSubmodule(submodule.id, moduleId);
                          else if (val == 'add_test')
                            _showAddTestDialog(submodule.id);
                          else if (val == 'add_practice')
                            _showAddPracticeDialog(submodule.id);
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'add_test',
                            child: Row(
                              children: [
                                Icon(Icons.quiz_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Добавить тест'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'add_practice',
                            child: Row(
                              children: [
                                Icon(Icons.code_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('Добавить практику'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Удалить',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
              if (tests.isNotEmpty || practicalTasks.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(height: 1, color: AppColors.bgLight),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      ...tests.map(
                        (test) => _buildTestItem(test, submodule.id),
                      ),
                      ...practicalTasks.map(
                        (task) => _buildPracticalTaskItem(task, submodule.id),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTestItem(db_models.Test test, int submoduleId) {
    return Container(
      margin: const EdgeInsets.only(left: 48, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        onTap: widget.readOnly
            ? null
            : () => _showEditTestDialog(test, submoduleId),
        leading: const Icon(Icons.quiz_outlined, size: 16, color: Colors.blue),
        title: Text(
          test.question ?? 'Вопрос',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        trailing: widget.readOnly
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 14, color: Colors.grey),
                onPressed: () => _deleteTest(test.id, submoduleId),
              ),
      ),
    );
  }

  Widget _buildPracticalTaskItem(Map<String, dynamic> task, int submoduleId) {
    return Container(
      margin: const EdgeInsets.only(left: 48, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        onTap: widget.readOnly
            ? null
            : () => _showEditPracticeDialog(task, submoduleId),
        leading: const Icon(Icons.code_rounded, size: 16, color: Colors.orange),
        title: Text(
          task['name'] ?? 'Практика',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        trailing: widget.readOnly
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 14, color: Colors.grey),
                onPressed: () => _deletePracticalTask(task['id'], submoduleId),
              ),
      ),
    );
  }

  // --- ДИАЛОГИ ---

  void _showAddModuleDialog() {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: AppStyles.cardRadius),
        title: Text('Новый модуль', style: AppStyles.h1),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: KodixComponents.textFieldDecoration(
              hintText: 'Название модуля',
              prefixIcon: Icons.layers_outlined,
            ),
            validator: (v) => v?.isEmpty == true ? 'Введите название' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена', style: AppStyles.label),
          ),
          KodixComponents.primaryButton(
            width: 120,
            height: 44,
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await _addModule(nameController.text);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text(
              'Создать',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
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
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: AppStyles.cardRadius),
          title: Text('Теория / Видео', style: AppStyles.h1),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KodixComponents.secondaryButton(
                    width: double.infinity,
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: [
                          'md',
                          'markdown',
                          'txt',
                          'mp4',
                          'mov',
                          'avi',
                        ],
                      );
                      if (result != null && context.mounted) {
                        setState(
                          () => selectedFilePath = result.files.single.path,
                        );
                      }
                    },
                    icon: Icons.upload_file_rounded,
                    child: Expanded(
                      child: Text(
                        selectedFilePath == null
                            ? 'Выбрать файл (MD или MP4)'
                            : selectedFilePath!.split('/').last,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    decoration: KodixComponents.textFieldDecoration(
                      hintText: 'Название урока',
                      prefixIcon: Icons.title_rounded,
                    ),
                    validator: (v) =>
                        v?.isEmpty == true ? 'Введите название' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: leadTimeController,
                    keyboardType: TextInputType.number,
                    decoration: KodixComponents.textFieldDecoration(
                      hintText: 'Время изучения (мин)',
                      prefixIcon: Icons.timer_rounded,
                    ),
                    validator: (v) =>
                        int.tryParse(v ?? '') == null ? 'Введите число' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена', style: AppStyles.label),
            ),
            KodixComponents.primaryButton(
              width: 140,
              height: 44,
              onPressed: isUploading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate() &&
                          selectedFilePath != null) {
                        setState(() => isUploading = true);
                        try {
                          await _addSubmodule(
                            moduleId,
                            nameController.text,
                            int.parse(leadTimeController.text),
                            selectedFilePath!,
                          );
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          if (context.mounted) {
                            setState(() => isUploading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Ошибка загрузки: ${e.toString()}',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } else if (selectedFilePath == null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Выберите файл')),
                          );
                        }
                      }
                    },
              child: isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Добавить',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPracticeDialog(int submoduleId) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final contentController = TextEditingController();
    final starterController = TextEditingController();
    final testsController = TextEditingController(
      text:
          '[\n  {"input": "5 3", "expected_output": "8", "description": "Тест 1"}\n]',
    );
    String lang = 'dart';
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: AppStyles.cardRadius),
          title: Text('Новая практика', style: AppStyles.h1),
          content: SizedBox(
            width: 700,
            height: 600,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: KodixComponents.textFieldDecoration(
                        hintText: 'Название задачи',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: lang,
                      items:
                          [
                                'dart',
                                'python',
                                'javascript',
                                'cpp',
                                'csharp',
                                'java',
                              ]
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e.toUpperCase()),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => lang = v ?? 'dart'),
                      decoration: KodixComponents.textFieldDecoration(
                        hintText: 'Язык программирования',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descController,
                      maxLines: 2,
                      decoration: KodixComponents.textFieldDecoration(
                        hintText: 'Описание',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: contentController,
                      maxLines: 4,
                      decoration: KodixComponents.textFieldDecoration(
                        hintText: 'Условие (Markdown)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: starterController,
                      maxLines: 4,
                      decoration: KodixComponents.textFieldDecoration(
                        hintText: 'Стартовый код',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: testsController,
                      maxLines: 4,
                      decoration: KodixComponents.textFieldDecoration(
                        hintText: 'Тестовые кейсы (JSON)',
                      ),
                      validator: (v) {
                        try {
                          jsonDecode(v!);
                          return null;
                        } catch (_) {
                          return 'Неверный JSON';
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена', style: AppStyles.label),
            ),
            KodixComponents.primaryButton(
              width: 140,
              height: 44,
              onPressed: isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setState(() => isLoading = true);
                        try {
                          await _addPracticalTask(
                            submoduleId,
                            nameController.text,
                            descController.text,
                            contentController.text,
                            lang,
                            starterController.text,
                            testsController.text,
                          );
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          if (context.mounted) {
                            setState(() => isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Ошибка: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
              child: const Text(
                'Добавить',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPracticeDialog(Map<String, dynamic> task, int submoduleId) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: task['name']);
    final descController = TextEditingController(text: task['description']);
    final contentController = TextEditingController(text: task['content']);
    final starterController = TextEditingController(text: task['starter_code']);
    final testsController = TextEditingController(
      text: jsonEncode(task['test_cases'] ?? []),
    );
    String lang = task['language'] ?? 'dart';
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: AppStyles.cardRadius),
          title: Text('Редактировать практику', style: AppStyles.h1),
          content: SizedBox(
            width: 700,
            height: 600,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: KodixComponents.textFieldDecoration(
                        hintText: 'Название задачи',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: lang,
                      items:
                          [
                                'dart',
                                'python',
                                'javascript',
                                'cpp',
                                'csharp',
                                'java',
                              ]
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e.toUpperCase()),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => lang = v ?? 'dart'),
                      decoration: KodixComponents.textFieldDecoration(
                        hintText: 'Язык программирования',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descController,
                      maxLines: 2,
                      decoration: KodixComponents.textFieldDecoration(
                        hintText: 'Описание',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: contentController,
                      maxLines: 4,
                      decoration: KodixComponents.textFieldDecoration(
                        hintText: 'Условие (Markdown)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: starterController,
                      maxLines: 4,
                      decoration: KodixComponents.textFieldDecoration(
                        hintText: 'Стартовый код',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: testsController,
                      maxLines: 4,
                      decoration: KodixComponents.textFieldDecoration(
                        hintText: 'Тестовые кейсы (JSON)',
                      ),
                      validator: (v) {
                        try {
                          jsonDecode(v!);
                          return null;
                        } catch (_) {
                          return 'Неверный JSON';
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена', style: AppStyles.label),
            ),
            KodixComponents.primaryButton(
              width: 140,
              height: 44,
              onPressed: isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setState(() => isLoading = true);
                        try {
                          await _updatePracticalTask(
                            task['id'],
                            nameController.text,
                            descController.text,
                            contentController.text,
                            lang,
                            starterController.text,
                            testsController.text,
                          );
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          if (context.mounted) {
                            setState(() => isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Ошибка: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
              child: const Text(
                'Сохранить',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTestDialog(int submoduleId) {
    final formKey = GlobalKey<FormState>();
    final questionController = TextEditingController();
    final rightAnswerController = TextEditingController();
    final wrong1Controller = TextEditingController();
    final wrong2Controller = TextEditingController();
    final wrong3Controller = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: AppStyles.cardRadius),
          title: Text('Новый тест', style: AppStyles.h1),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: questionController,
                      maxLines: 2,
                      decoration: KodixComponents.textFieldDecoration(
                        hintText: 'Вопрос',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: rightAnswerController,
                      decoration: KodixComponents.textFieldDecoration(
                        hintText: 'Правильный ответ',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: wrong1Controller,
                      decoration: KodixComponents.textFieldDecoration(
                        hintText: 'Неверный ответ 1',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: wrong2Controller,
                      decoration: KodixComponents.textFieldDecoration(
                        hintText: 'Неверный ответ 2',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: wrong3Controller,
                      decoration: KodixComponents.textFieldDecoration(
                        hintText: 'Неверный ответ 3',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена', style: AppStyles.label),
            ),
            KodixComponents.primaryButton(
              width: 140,
              height: 44,
              onPressed: isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setState(() => isLoading = true);
                        await _addTest(
                          submoduleId,
                          questionController.text,
                          rightAnswerController.text,
                          [
                            wrong1Controller.text,
                            wrong2Controller.text,
                            wrong3Controller.text,
                          ],
                        );
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
              child: const Text(
                'Добавить',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTestDialog(db_models.Test test, int submoduleId) {
    final formKey = GlobalKey<FormState>();
    final questionController = TextEditingController(text: test.question);
    final rightAnswerController = TextEditingController(text: test.rightAnswer);
    final wrong1Controller = TextEditingController(text: test.wrongAnswer1);
    final wrong2Controller = TextEditingController(text: test.wrongAnswer2);
    final wrong3Controller = TextEditingController(text: test.wrongAnswer3);
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: AppStyles.cardRadius),
          title: Text('Редактировать тест', style: AppStyles.h1),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: questionController,
                      maxLines: 2,
                      decoration: KodixComponents.textFieldDecoration(
                        hintText: 'Вопрос',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: rightAnswerController,
                      decoration: KodixComponents.textFieldDecoration(
                        hintText: 'Правильный ответ',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: wrong1Controller,
                      decoration: KodixComponents.textFieldDecoration(
                        hintText: 'Неверный ответ 1',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: wrong2Controller,
                      decoration: KodixComponents.textFieldDecoration(
                        hintText: 'Неверный ответ 2',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: wrong3Controller,
                      decoration: KodixComponents.textFieldDecoration(
                        hintText: 'Неверный ответ 3',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена', style: AppStyles.label),
            ),
            KodixComponents.primaryButton(
              width: 140,
              height: 44,
              onPressed: isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setState(() => isLoading = true);
                        await _updateTest(
                          test.id,
                          questionController.text,
                          rightAnswerController.text,
                          [
                            wrong1Controller.text,
                            wrong2Controller.text,
                            wrong3Controller.text,
                          ],
                        );
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
              child: const Text(
                'Сохранить',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- МЕТОДЫ API ---

  Future<void> _addModule(String name) async {
    final order = _modules.isEmpty ? 1 : (_modules.last.orderModule ?? 0) + 1;
    await SupabaseService.client.from('module').insert({
      'id_courses': widget.courseId,
      'name': name,
      'order_module': order,
      'status': true,
    });
    _loadModules();
  }

  Future<void> _addSubmodule(int moduleId, String name, int leadTime, String filePath) async {
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

      await SupabaseService.client.storage
          .from('course-files')
          .uploadBinary(storagePath, fileBytes);

      final signedUrl = await SupabaseService.client.storage
          .from('course-files')
          .createSignedUrl(storagePath, 5256000);

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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Подмодуль "$name" добавлен')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  Future<void> _addPracticalTask(
    int subId,
    String name,
    String desc,
    String content,
    String lang,
    String starter,
    String tests,
  ) async {
    await SupabaseService.client.from('practical_task').insert({
      'id_submodule': subId,
      'name': name,
      'description': desc,
      'content': content,
      'language': lang,
      'starter_code': starter,
      'test_cases': jsonDecode(tests),
      'status': true,
      'order_task': (_practicalTasks[subId]?.length ?? 0) + 1,
    });
    _loadModules();
  }

  Future<void> _updatePracticalTask(
    int taskId,
    String name,
    String desc,
    String content,
    String lang,
    String starter,
    String tests,
  ) async {
    await SupabaseService.client
        .from('practical_task')
        .update({
          'name': name,
          'description': desc,
          'content': content,
          'language': lang,
          'starter_code': starter,
          'test_cases': jsonDecode(tests),
        })
        .eq('id', taskId);
    _loadModules();
  }

  Future<void> _addTest(
    int subId,
    String question,
    String right,
    List<String> wrongs,
  ) async {
    final res = await SupabaseService.client
        .from('test')
        .insert({
          'question': question,
          'right_answer': right,
          'wrong_answer1': wrongs[0],
          'wrong_answer2': wrongs[1],
          'wrong_answer3': wrongs[2],
          'status': true,
        })
        .select()
        .single();
    await SupabaseService.client.from('submodule_test').insert({
      'id_submodule': subId,
      'id_test': res['id'],
      'order_test': (_tests[subId]?.length ?? 0) + 1,
    });
    _loadModules();
  }

  Future<void> _updateTest(
    int tid,
    String question,
    String right,
    List<String> wrongs,
  ) async {
    await SupabaseService.client
        .from('test')
        .update({
          'question': question,
          'right_answer': right,
          'wrong_answer1': wrongs[0],
          'wrong_answer2': wrongs[1],
          'wrong_answer3': wrongs[2],
        })
        .eq('id', tid);
    _loadModules();
  }

  Future<void> _deleteModule(int id) async {
    await SupabaseService.client.from('module').delete().eq('id', id);
    _loadModules();
  }

  Future<void> _deleteSubmodule(int id, int mid) async {
    await SupabaseService.client.from('submodule').delete().eq('id', id);
    _loadModules();
  }

  Future<void> _deleteTest(int tid, int sid) async {
    await SupabaseService.client
        .from('submodule_test')
        .delete()
        .eq('id_test', tid);
    await SupabaseService.client.from('test').delete().eq('id', tid);
    _loadModules();
  }

  Future<void> _deletePracticalTask(int tid, int sid) async {
    await SupabaseService.client.from('practical_task').delete().eq('id', tid);
    _loadModules();
  }
}
