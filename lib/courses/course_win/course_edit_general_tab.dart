import 'package:flutter/material.dart';
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
    
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название курса')),
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
                  decoration: KodixComponents.textFieldDecoration(
                    hintText: 'Введите название курса', 
                    prefixIcon: Icons.book_rounded
                  ),
                  style: AppStyles.body,
                  validator: (val) => val?.isEmpty == true ? 'Поле обязательно' : null,
                ),
                const SizedBox(height: 24),

                // Описание
                Text('Описание', style: AppStyles.label.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  enabled: !widget.readOnly,
                  maxLines: 5,
                  decoration: KodixComponents.textFieldDecoration(
                    hintText: 'Введите подробное описание курса', 
                    prefixIcon: Icons.description_rounded
                  ),
                  style: AppStyles.body,
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
                            keyboardType: TextInputType.number,
                            decoration: KodixComponents.textFieldDecoration(
                              hintText: '0', 
                              prefixIcon: Icons.payments_rounded
                            ),
                            style: AppStyles.body,
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
                            decoration: KodixComponents.textFieldDecoration(
                              hintText: 'Выберите уровень', 
                              prefixIcon: Icons.bar_chart_rounded
                            ),
                            items: _complexityLevels.entries.map((entry) {
                              return DropdownMenuItem<int>(
                                value: entry.key,
                                child: Text(entry.value, style: AppStyles.body),
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
