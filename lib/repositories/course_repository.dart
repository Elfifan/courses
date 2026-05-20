import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_components.dart';

class CourseService {
  static void showAddCourseForm(BuildContext context, {required int? authorId}) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    int selectedComplexity = 1;
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    // Список эмодзи для выбора
    final List<String> emojiOptions = ['📚', '🐍', '⚡', '📱', '🧑‍💻', '🎯', '🚀', '💻'];
    String selectedEmoji = emojiOptions[0]; // Начальное значение

    final Map<int, String> complexityLevels = {
      1: 'Начальный уровень',
      2: 'Средний уровень',
      3: 'Продвинутый уровень',
    };

    Color getComplexityColor(int key) {
      switch (key) {
        case 1: return Colors.green;
        case 2: return Colors.orange;
        case 3: return Colors.red;
        default: return AppColors.primaryPurple;
      }
    }

    IconData getComplexityIcon(int key) {
      switch (key) {
        case 1: return Icons.signal_cellular_alt_1_bar;
        case 2: return Icons.signal_cellular_alt_2_bar;
        case 3: return Icons.signal_cellular_alt;
        default: return Icons.bar_chart_rounded;
      }
    }

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
            content: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              constraints: BoxConstraints(
                maxWidth: 500,
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: AbsorbPointer(
                    absorbing: isLoading,
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
                        maxLength: 50,
                        decoration: KodixComponents.textFieldDecoration(hintText: 'Введите название курса', prefixIcon: Icons.menu_book_outlined),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Введите название';
                          }
                          final trimmed = v.trim();
                          if (trimmed.length > 50) {
                            return 'Название не должно превышать 50 символов';
                          }
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
                        maxLength: 100,
                        decoration: KodixComponents.textFieldDecoration(hintText: 'Введите описание курса', prefixIcon: Icons.description_outlined),
                        minLines: 3,
                        maxLines: 5,
                        validator: (v) {
                          if (v != null && v.trim().length > 100) {
                            return 'Описание не должно превышать 100 символов';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Text('Цена курса', style: AppStyles.label.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: priceController,
                        maxLength: 5,
                        decoration: KodixComponents.textFieldDecoration(hintText: 'Введите цену (₽)', prefixIcon: Icons.currency_ruble),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          final price = v.trim();
                          if (price.length > 5) {
                            return 'Цена не должна превышать 5 символов';
                          }
                          if (double.tryParse(price) == null) {
                            return 'Введите корректное число';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Text('Уровень сложности', style: AppStyles.label.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        initialValue: selectedComplexity,
                        dropdownColor: AppColors.white,
                        borderRadius: AppStyles.mainRadius,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primaryPurple, size: 26),
                        elevation: 8,
                        decoration: KodixComponents.textFieldDecoration(hintText: 'Выберите уровень сложности', prefixIcon: Icons.bar_chart_outlined),
                        items: complexityLevels.entries.map((entry) {
                          return DropdownMenuItem<int>(
                            value: entry.key,
                            child: Row(
                              children: [
                                Icon(getComplexityIcon(entry.key), color: getComplexityColor(entry.key), size: 20),
                                const SizedBox(width: 10),
                                Text(entry.value, style: AppStyles.body),
                              ],
                            ),
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
            ),
          ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryPurple,
                  textStyle: AppStyles.body.copyWith(fontWeight: FontWeight.w700),
                ),
                child: const Text('Отмена'),
              ),
              SizedBox(
                width: 140,
                child: KodixComponents.primaryButton(
                  backgroundColor: isLoading ? Colors.grey : null,
                  onPressed: isLoading
                      ? null
                      : () async {
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

                            setState(() {
                              isLoading = true;
                            });

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
                              setState(() {
                                isLoading = false;
                              });
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
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Добавить'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Stream<void> watchCourses() {
    final supabase = Supabase.instance.client;
    final controller = StreamController<void>.broadcast();

    final channel = supabase
        .channel('public:courses')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'courses',
          callback: (payload) {
            if (!controller.isClosed) {
              controller.add(null);
            }
          },
        );

    channel.subscribe();

    controller.onCancel = () {
      channel.unsubscribe();
      controller.close();
    };

    return controller.stream;
  }
}
