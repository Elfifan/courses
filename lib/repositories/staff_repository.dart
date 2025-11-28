import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/database_models.dart';

class StaffRepository {
  final _supabase = Supabase.instance.client;

  Future<List<Staff>> getStaff() async {
    try {
      final response = await _supabase.from('staff').select();
      return (response as List)
          .map((item) => Staff.fromJson(item))
          .toList();
    } catch (e) {
      print('Ошибка загрузки сотрудников: $e');
      rethrow;
    }
  }

  Future<void> addStaff(Staff staff) async {
    try {
      await _supabase.from('staff').insert(staff.toJson());
    } catch (e) {
      print('Ошибка добавления сотрудника: $e');
      rethrow;
    }
  }

  Future<void> updateStaff(Staff staff) async {
    try {
      await _supabase
          .from('staff')
          .update(staff.toJson())
          .eq('id', staff.id);
    } catch (e) {
      print('Ошибка обновления сотрудника: $e');
      rethrow;
    }
  }

  Future<void> deleteStaff(int id) async {
    try {
      await _supabase.from('staff').delete().eq('id', id);
    } catch (e) {
      print('Ошибка удаления сотрудника: $e');
      rethrow;
    }
  }

  // ✅ Диалог добавления сотрудника
  static void showAddStaffDialog(BuildContext context, VoidCallback onStaffAdded) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final positionController = TextEditingController();
    final repository = StaffRepository();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Добавить сотрудника'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'ФИО',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: positionController,
                decoration: InputDecoration(
                  labelText: 'Должность',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  emailController.text.isEmpty ||
                  positionController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Заполни все поля')),
                );
                return;
              }

              try {
                final newStaff = Staff(
                  id: 0,
                  name: nameController.text,
                  email: emailController.text,
                  position: positionController.text,
                );

                await repository.addStaff(newStaff);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Сотрудник добавлен'),
                    backgroundColor: Colors.green,
                  ),
                );

                onStaffAdded(); // Обновляем данные
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ошибка: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Добавить'),
          ),
        ],
      ),
    );
  }
}
