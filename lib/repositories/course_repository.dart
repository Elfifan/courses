import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_components.dart';

class CourseService {
  static void showAddCourseForm(BuildContext context, {required int? authorId}) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    int selectedComplexity = 1;
    final formKey = GlobalKey<FormState>();

    // Список эмодзи для выбора
    final List<String> emojiOptions = ['📚', '🐍', '⚡', '📱', '🧑‍💻', '🎯', '🚀', '💻'];
    String selectedEmoji = emojiOptions[0]; // Начальное значение

    final Map<int, String> complexityLevels = {
      1: 'Начальный уровень',
      2: 'Средний уровень',
      3: 'Продвинутый уровень',
    };

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.white,
            shape: RoundedRectangleBorder(borderRadius: AppStyles.mainRadius),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            title: Text('Добавить новый курс', style: AppStyles.h1.copyWith(fontSize: 20)),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Иконка курса', style: AppStyles.label.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
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
                            width: 52,
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryPurple.withValues(alpha: 0.15) : AppColors.bgLight,
                              border: Border.all(
                                color: isSelected ? AppColors.primaryPurple : AppColors.bgLight,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(emoji, style: const TextStyle(fontSize: 28)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Text('Название курса', style: AppStyles.label.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: nameController,
                      decoration: KodixComponents.textFieldDecoration(hintText: 'Введите название курса', prefixIcon: Icons.menu_book_outlined),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Введите название';
                        }
                        final trimmed = v.trim();
                        final alphanumericOnly = RegExp(r'[a-zA-Zа-яА-Я0-9]').hasMatch(trimmed);
                        if (!alphanumericOnly) {
                          return 'Название должно содержать хотя бы одну букву или цифру';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Text('Описание курса', style: AppStyles.label.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: descriptionController,
                      decoration: KodixComponents.textFieldDecoration(hintText: 'Введите описание курса', prefixIcon: Icons.description_outlined),
                      minLines: 3,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 12),
                    Text('Цена курса', style: AppStyles.label.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: priceController,
                      decoration: KodixComponents.textFieldDecoration(hintText: 'Введите цену (₽)', prefixIcon: Icons.attach_money_outlined),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v != null && v.isNotEmpty && double.tryParse(v) == null) {
                          return 'Введите корректное число';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Text('Уровень сложности', style: AppStyles.label.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: selectedComplexity,
                      decoration: KodixComponents.textFieldDecoration(hintText: 'Выберите уровень сложности', prefixIcon: Icons.bar_chart_outlined),
                      items: complexityLevels.entries.map((entry) {
                        return DropdownMenuItem<int>(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedComplexity = value);
                        }
                      },
                      validator: (value) => value == null ? 'Выберите уровень сложности' : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryPurple,
                  textStyle: AppStyles.body.copyWith(fontWeight: FontWeight.w700),
                ),
                child: const Text('Отмена'),
              ),
              SizedBox(
                width: 140,
                child: KodixComponents.primaryButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      if (authorId == null) {
                        final scaffold = ScaffoldMessenger.of(context);
                        scaffold.showSnackBar(
                          const SnackBar(content: Text('Не удалось определить автора курса')),
                        );
                        return;
                      }

                      final navigator = Navigator.of(context);
                      final scaffold = ScaffoldMessenger.of(context);

                      try {
                        await Supabase.instance.client
                            .from('courses')
                            .insert({
                              'id_employee': authorId,
                              'name': nameController.text.trim(),
                              'description': descriptionController.text.trim(),
                              'date_create': DateTime.now().toIso8601String(),
                              'price': double.tryParse(priceController.text) ?? 0.0,
                              'complexity': selectedComplexity,
                              'status': 'На проверке',
                              'icon': selectedEmoji,
                            });

                        navigator.pop();
                        scaffold.showSnackBar(
                          SnackBar(
                            content: Text('Курс "${nameController.text}" успешно добавлен'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        navigator.pop();
                        scaffold.showSnackBar(
                          SnackBar(
                            content: Text('Ошибка при сохранении: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        debugPrint('Ошибка: $e');
                      }
                    }
                  },
                  child: const Text('Добавить'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
