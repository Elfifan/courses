import 'package:flutter/material.dart';
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
    
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название курса')),
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
              Text('Название курса', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Введите название курса',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.book),
                ),
                validator: (val) => val?.isEmpty == true ? 'Поле обязательно' : null,
              ),
              const SizedBox(height: 20),

              // Описание
              Text('Описание', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Введите описание курса',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 20),

              // Цена
              Text('Цена', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Введите цену',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 20),

              // Сложность
              Text('Уровень сложности', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _selectedComplexity,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.trending_up),
                ),
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
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveCourse,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
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
