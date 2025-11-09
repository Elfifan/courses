// course_edit_modules_tab.dart
import 'package:flutter/material.dart';

class CourseEditModulesTab extends StatelessWidget {
  final Map<String, dynamic> module;

  const CourseEditModulesTab({Key? key, required this.module}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List submodules = module['submodules'] ?? [];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок с кнопками действий
          Row(
            children: [
              Expanded(
                child: Text('1. ${module['title']}', 
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showAddModuleDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Добавить модуль'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          if (module['duration'] != null)
            Text('Продолжительность: ${module['duration']}'),
            
          const SizedBox(height: 16),
          
          // Кнопки для добавления контента
          Row(
            children: [
              const Text('Подмодули:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => _showAddTheoryDialog(context),
                icon: const Icon(Icons.menu_book, size: 18),
                label: const Text('Добавить теорию'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showAddTaskDialog(context),
                icon: const Icon(Icons.assignment, size: 18),
                label: const Text('Добавить задание'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Expanded(
            child: ListView.builder(
              itemCount: submodules.length,
              itemBuilder: (context, index) {
                final sub = submodules[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: sub['completed'] == true ? Colors.green : Colors.grey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '1.${index + 1}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sub['title'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(sub['duration'], style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                          ],
                        ),
                      ),
                      // Кнопки действий для подмодуля
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) => _handleSubmoduleAction(context, value, sub, index),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('Редактировать'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'duplicate',
                            child: Row(
                              children: [
                                Icon(Icons.copy, size: 18),
                                SizedBox(width: 8),
                                Text('Дублировать'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Удалить', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        sub['completed'] == true ? Icons.check_circle : Icons.play_circle_outline,
                        color: sub['completed'] == true ? Colors.green : Colors.grey,
                        size: 24,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddModuleDialog(BuildContext context) {
    final titleController = TextEditingController();
    final durationController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить новый модуль'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Название модуля',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.book),
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Введите название' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: durationController,
                  decoration: const InputDecoration(
                    labelText: 'Продолжительность',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.access_time),
                    hintText: 'Например: 2 часа 30 мин',
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Введите продолжительность' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Модуль "${titleController.text}" добавлен')),
                );
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _showAddTheoryDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final durationController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить теоретический материал'),
        content: SizedBox(
          width: 500,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Название урока',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Введите название' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: contentController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Содержание урока',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                      hintText: 'Опишите теоретический материал...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: durationController,
                    decoration: const InputDecoration(
                      labelText: 'Время изучения',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.schedule),
                      hintText: 'Например: 15 мин',
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Введите время' : null,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Теория "${titleController.text}" добавлена')),
                );
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final durationController = TextEditingController();
    String taskType = 'quiz';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Добавить практическое задание'),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Название задания',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.assignment),
                      ),
                      validator: (value) => value?.isEmpty == true ? 'Введите название' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: taskType,
                      decoration: const InputDecoration(
                        labelText: 'Тип задания',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'quiz', child: Text('Тест')),
                        DropdownMenuItem(value: 'practice', child: Text('Практика')),
                        DropdownMenuItem(value: 'project', child: Text('Проект')),
                        DropdownMenuItem(value: 'essay', child: Text('Эссе')),
                      ],
                      onChanged: (value) => setState(() => taskType = value!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Описание задания',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                        hintText: 'Опишите что нужно сделать...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: durationController,
                      decoration: const InputDecoration(
                        labelText: 'Время выполнения',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timer),
                        hintText: 'Например: 30 мин',
                      ),
                      validator: (value) => value?.isEmpty == true ? 'Введите время' : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() == true) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Задание "${titleController.text}" добавлено')),
                  );
                }
              },
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmoduleAction(BuildContext context, String action, Map<String, dynamic> submodule, int index) {
    switch (action) {
      case 'edit':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Редактирование "${submodule['title']}"')),
        );
        break;
      case 'duplicate':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Подмодуль "${submodule['title']}" дублирован')),
        );
        break;
      case 'delete':
        _showDeleteConfirmation(context, submodule['title']);
        break;
    }
  }

  void _showDeleteConfirmation(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить подмодуль?'),
        content: Text('Вы уверены, что хотите удалить "$title"? Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Подмодуль "$title" удален')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
