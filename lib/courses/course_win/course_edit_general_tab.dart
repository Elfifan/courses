import 'package:flutter/material.dart';
import '../../core/theme/app_components.dart';
import '../../models/database_models.dart';
import '../../services/supabase_service.dart';

class CourseEditGeneralTab extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final Course course;
  final Function(String, String, double, int) onCourseUpdated;  // ← ИЗМЕНЕНО

  const CourseEditGeneralTab({
    super.key,
    required this.formKey,
    required this.course,
    required this.onCourseUpdated,
  });

  @override
  _CourseEditGeneralTabState createState() => _CourseEditGeneralTabState();
}

class _CourseEditGeneralTabState extends State<CourseEditGeneralTab> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  
  int? _selectedComplexity;
  bool _isSaving = false;

  final Map<int, String> _complexityLevels = {
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

      await SupabaseService.client
          .from('courses')
          .update({
            'name': _titleController.text,
            'description': _descriptionController.text,
            'price': price,
            'complexity': _selectedComplexity,
          })
          .eq('id', widget.course.id);

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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Form(
          key: widget.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Название
              Text('Название курса', style: AppStyles.label.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: KodixComponents.textFieldDecoration(hintText: 'Введите название курса', prefixIcon: Icons.book),
                validator: (val) => val?.isEmpty == true ? 'Поле обязательно' : null,
              ),
              const SizedBox(height: 20),

              // Описание
              Text('Описание', style: AppStyles.label.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: KodixComponents.textFieldDecoration(hintText: 'Введите описание курса', prefixIcon: Icons.description),
              ),
              const SizedBox(height: 20),

              // Цена
              Text('Цена', style: AppStyles.label.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: KodixComponents.textFieldDecoration(hintText: 'Введите цену', prefixIcon: Icons.attach_money),
              ),
              const SizedBox(height: 20),

              // Сложность
              Text('Уровень сложности', style: AppStyles.label.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _selectedComplexity,
                decoration: KodixComponents.textFieldDecoration(hintText: 'Выберите уровень сложности', prefixIcon: Icons.trending_up),
                items: _complexityLevels.entries.map((entry) {
                  return DropdownMenuItem<int>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedComplexity = value);
                  }
                },
              ),
              const SizedBox(height: 30),

              // Кнопка сохранения
              SizedBox(
                width: double.infinity,
                child: KodixComponents.primaryButton(
                  onPressed: _isSaving ? null : _saveCourse,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Сохранить'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
