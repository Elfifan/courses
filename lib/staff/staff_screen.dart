import 'package:flutter/material.dart';
import '../../repositories/staff_repository.dart';
import '../../models/database_models.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({Key? key}) : super(key: key);

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final courseRepository = StaffRepository();
  List<Staff> allStaff = [];
  List<Staff> filteredStaff = [];
  bool isLoading = true;
  String searchQuery = '';

  void refreshStaff() {
    _loadStaff();
  }

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() => isLoading = true);
    try {
      final staff = await courseRepository.getStaff();
      setState(() {
        allStaff = staff;
        filteredStaff = staff;
        isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки сотрудников: $e');
      setState(() => isLoading = false);
    }
  }

  void _filterStaff(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredStaff = allStaff;
      } else {
        filteredStaff = allStaff
            .where((staff) =>
                staff.name.toLowerCase().contains(query.toLowerCase()) ||
                staff.email.toLowerCase().contains(query.toLowerCase()) ||
                staff.position.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _showAddStaffDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final positionController = TextEditingController();

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

                await courseRepository.addStaff(newStaff);
                Navigator.pop(context);
                _loadStaff();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Сотрудник добавлен'),
                    backgroundColor: Colors.green,
                  ),
                );
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

  void _showEditStaffDialog(Staff staff) {
    final nameController = TextEditingController(text: staff.name);
    final emailController = TextEditingController(text: staff.email);
    final positionController = TextEditingController(text: staff.position);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Редактировать сотрудника'),
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
                final updatedStaff = Staff(
                  id: staff.id,
                  name: nameController.text,
                  email: emailController.text,
                  position: positionController.text,
                );

                await courseRepository.updateStaff(updatedStaff);
                Navigator.pop(context);
                _loadStaff();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Сотрудник обновлен'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ошибка: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _deleteStaff(Staff staff) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить сотрудника?'),
        content: Text('Вы уверены? "${staff.name}" будет удален.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await courseRepository.deleteStaff(staff.id);
                Navigator.pop(context);
                _loadStaff();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Сотрудник удален'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ошибка: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Сотрудники'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Строка поиска
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              onChanged: _filterStaff,
              decoration: InputDecoration(
                hintText: 'Поиск по имени, email, должности...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          // Список сотрудников
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredStaff.isEmpty
                    ? Center(
                        child: Text(
                          searchQuery.isEmpty
                              ? 'Нет сотрудников'
                              : 'Сотрудники не найдены',
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredStaff.length,
                        itemBuilder: (context, index) {
                          final staff = filteredStaff[index];
                          return Card(
                            margin: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              title: Text(staff.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Text(
                                    staff.email,
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    staff.position,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    child: Text('Редактировать'),
                                    onTap: () =>
                                        _showEditStaffDialog(staff),
                                  ),
                                  PopupMenuItem(
                                    child: Text(
                                      'Удалить',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    onTap: () => _deleteStaff(staff),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStaffDialog,
        child: Icon(Icons.add),
        tooltip: 'Добавить сотрудника',
      ),
    );
  }
}
