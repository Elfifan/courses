import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CourseService {
  static void showAddCourseForm(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final complexityController = TextEditingController(text: '1');
    final formKey = GlobalKey<FormState>();

    // Список эмодзи для выбора
    final List<String> emojiOptions = ['📚', '🐍', '⚡', '📱', '🧑‍💻', '🎯', '🚀', '💻'];
    String selectedEmoji = emojiOptions[0]; // Начальное значение

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Добавить новый курс'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Выбор эмодзи
                    Container(
                      alignment: Alignment.centerLeft,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: const Text(
                        'Выберите иконку:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: emojiOptions.map((emoji) {
                        final isSelected = emoji == selectedEmoji;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedEmoji = emoji;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blueAccent.withValues(alpha: 0.3)
                                  : Colors.transparent,
                              border: isSelected
                                  ? Border.all(color: Colors.blue, width: 2)
                                  : Border.all(color: Colors.grey, width: 1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Название курса
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Название курса *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Введите название' : null,
                    ),
                    const SizedBox(height: 12),

                    // Описание
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Описание',
                        border: OutlineInputBorder(),
                      ),
                      minLines: 3,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 12),

                    // Цена
                    TextFormField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Цена (₽)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v != null && v.isNotEmpty && double.tryParse(v) == null) {
                          return 'Введите корректное число';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Сложность
                    TextFormField(
                      controller: complexityController,
                      decoration: const InputDecoration(
                        labelText: 'Сложность (1-5)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Введите сложность';
                        }
                        final complexity = int.tryParse(v);
                        if (complexity == null || complexity < 1 || complexity > 5) {
                          return 'Сложность должна быть от 1 до 5';
                        }
                        return null;
                      },
                    ),
                  ],
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
                    try {
                      await Supabase.instance.client
                          .from('courses')
                          .insert({
                            'id_employee': 1, // Замени на реальный ID
                            'name': nameController.text.trim(),
                            'description': descriptionController.text.trim(),
                            'date_create': DateTime.now().toIso8601String(),
                            'price': double.tryParse(priceController.text) ?? 0.0,
                            'complexity': int.parse(complexityController.text),
                            'status': true,
                            'icon': selectedEmoji, // Сохраняем эмодзи как текст
                          });

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Курс "${nameController.text}" успешно добавлен'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Ошибка при сохранении: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      print('Ошибка: $e');
                    }
                  }
                },
                child: const Text('Добавить'),
              ),
            ],
          );
        },
      ),
    );
  }
}
