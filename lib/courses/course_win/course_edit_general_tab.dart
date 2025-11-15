// course_edit_general_tab.dart
import 'package:flutter/material.dart';

class CourseEditGeneralTab extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController priceController;
  final String selectedStatus;
  final String selectedCategory;
  final bool isPublished;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<bool> onPublishedChanged;
  final VoidCallback onSave;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const CourseEditGeneralTab({
    super.key,
    required this.formKey,
    required this.titleController,
    required this.descriptionController,
    required this.priceController,
    required this.selectedStatus,
    required this.selectedCategory,
    required this.isPublished,
    required this.onStatusChanged,
    required this.onCategoryChanged,
    required this.onPublishedChanged,
    required this.onSave,
    required this.onArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Основная информация', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Название курса',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Введите название' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Цена (₽)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Описание',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Категория',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: const [
                DropdownMenuItem(value: 'programming', child: Text('Программирование')),
                DropdownMenuItem(value: 'design', child: Text('Дизайн')),
                DropdownMenuItem(value: 'business', child: Text('Бизнес')),
              ],
              onChanged: onCategoryChanged,
            ),
            const SizedBox(height: 24),
            const Text('Настройки курса', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Статус курса',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Активный')),
                        DropdownMenuItem(value: 'draft', child: Text('Черновик')),
                        DropdownMenuItem(value: 'archived', child: Text('Архивирован')),
                      ],
                      onChanged: onStatusChanged,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SwitchListTile(
                      title: const Text('Опубликован'),
                      subtitle: const Text('Видим студентам'),
                      value: isPublished,
                      onChanged: onPublishedChanged,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('Действия', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onSave,
                    icon: const Icon(Icons.save),
                    label: const Text('Сохранить изменения'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onArchive,
                    icon: const Icon(Icons.archive),
                    label: const Text('Архивировать'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Удалить', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.red),
                    ),
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
