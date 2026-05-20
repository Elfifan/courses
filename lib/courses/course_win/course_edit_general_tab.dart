import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_components.dart';
import '../../models/database_models.dart';
import '../../services/supabase_service.dart';

class CourseEditGeneralTab extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final Course course;
  final Function(String, String, double, int) onCourseUpdated;
  final bool readOnly;

  const CourseEditGeneralTab({
    super.key,
    required this.formKey,
    required this.course,
    required this.onCourseUpdated,
    this.readOnly = false,
  });

  @override
  State<CourseEditGeneralTab> createState() => _CourseEditGeneralTabState();
}

class _CourseEditGeneralTabState extends State<CourseEditGeneralTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  
  int? _selectedComplexity;
  bool _isSaving = false;

  static const Map<int, String> _complexityLevels = {
    1: 'Начальный уровень',
    2: 'Средний уровень',
    3: 'Продвинутый уровень',
  };

  Color _getComplexityColor(int key) {
    switch (key) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return AppColors.primaryPurple;
    }
  }

  IconData _getComplexityIcon(int key) {
    switch (key) {
      case 1:
        return Icons.signal_cellular_alt_1_bar;
      case 2:
        return Icons.signal_cellular_alt_2_bar;
      case 3:
        return Icons.signal_cellular_alt;
      default:
        return Icons.bar_chart_rounded;
    }
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.course.name ?? '');
    _descriptionController = TextEditingController(text: widget.course.description ?? '');
    _priceController = TextEditingController(text: widget.course.price?.toString() ?? '');
    _selectedComplexity = widget.course.complexity ?? 1;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveCourse() async {
    if (!mounted) return;
    
    if (!(widget.formKey.currentState?.validate() ?? false)) {
      return;
    }
    
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название курса')),
      );
      return;
    }
    if (title.length > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Название не должно превышать 50 символов')),
      );
      return;
    }
    // Проверяем, что название не состоит только из знаков препинания и специальных символов
    final alphanumericOnly = RegExp(r'[a-zA-Zа-яА-Я0-9]').hasMatch(title);
    if (!alphanumericOnly) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Название не может состоять только из знаков препинания и специальных символов')),
      );
      return;
    }

    final description = _descriptionController.text.trim();
    if (description.length > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Описание не должно превышать 100 символов')),
      );
      return;
    }

    final priceStr = _priceController.text.trim();
    if (priceStr.length > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Цена не должна превышать 5 символов')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final price = double.tryParse(_priceController.text) ?? 0;

      await SupabaseService.safeDbCall(() => SupabaseService.client
          .from('courses')
          .update({
            'name': _titleController.text,
            'description': _descriptionController.text,
            'price': price,
            'complexity': _selectedComplexity,
          })
          .eq('id', widget.course.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Курс сохранен успешно')),
        );
        // ← ВЫЗЫВАЕМ CALLBACK с новыми данными
        widget.onCourseUpdated(
          _titleController.text,
          _descriptionController.text,
          price,
          _selectedComplexity!,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: AppStyles.mainRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Form(
            key: widget.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Основная информация', 
                  style: AppStyles.h1.copyWith(fontSize: 20)
                ),
                const SizedBox(height: 24),
                
                // Название
                Text('Название курса', style: AppStyles.label.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  enabled: !widget.readOnly,
                  maxLength: 50,
                  decoration: KodixComponents.textFieldDecoration(
                    hintText: 'Введите название курса', 
                    prefixIcon: Icons.book_rounded
                  ),
                  style: AppStyles.body,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Поле обязательно';
                    if (val.trim().length > 50) return 'Название не должно превышать 50 символов';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Описание
                Text('Описание', style: AppStyles.label.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  enabled: !widget.readOnly,
                  maxLines: 5,
                  maxLength: 100,
                  decoration: KodixComponents.textFieldDecoration(
                    hintText: 'Введите подробное описание курса', 
                    prefixIcon: Icons.description_rounded
                  ),
                  style: AppStyles.body,
                  validator: (val) {
                    if (val != null && val.trim().length > 100) return 'Описание не должно превышать 100 символов';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    // Цена
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Цена (₽)', style: AppStyles.label.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _priceController,
                            enabled: !widget.readOnly,
                            maxLength: 5,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: KodixComponents.textFieldDecoration(
                              hintText: '0', 
                              prefixIcon: Icons.payments_rounded
                            ),
                            style: AppStyles.body,
                            validator: (val) {
                              if (val == null || val.isEmpty) return null;
                              final price = val.trim();
                              if (price.length > 5) return 'Цена не должна превышать 5 символов';
                              if (double.tryParse(price) == null) return 'Введите корректное число';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Сложность
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Сложность', style: AppStyles.label.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            key: ValueKey(_selectedComplexity),
                            initialValue: _selectedComplexity,
                            dropdownColor: AppColors.white,
                            borderRadius: AppStyles.mainRadius,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primaryPurple, size: 26),
                            elevation: 8,
                            decoration: KodixComponents.textFieldDecoration(
                              hintText: 'Выберите уровень', 
                              prefixIcon: Icons.bar_chart_rounded
                            ),
                            items: _complexityLevels.entries.map((entry) {
                              return DropdownMenuItem<int>(
                                value: entry.key,
                                child: Row(
                                  children: [
                                    Icon(_getComplexityIcon(entry.key), color: _getComplexityColor(entry.key), size: 20),
                                    const SizedBox(width: 10),
                                    Text(entry.value, style: AppStyles.body),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: widget.readOnly ? null : (value) {
                              if (value != null) {
                                setState(() => _selectedComplexity = value);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Кнопка сохранения
                if (!widget.readOnly)
                  KodixComponents.primaryButton(
                    width: double.infinity,
                    onPressed: _isSaving ? null : _saveCourse,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Сохранить изменения', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
