import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../shared/search_row.dart';

class StaffScreen extends StatefulWidget {
  final bool isDarkMode;

  const StaffScreen({
    super.key,
    required this.isDarkMode,
  });

  @override
  StaffScreenState createState() => StaffScreenState();
}

class StaffScreenState extends State<StaffScreen> {
  int? _hoveredIndex;
  final Map<int, bool> _passwordVisibility = {};
  List<Map<String, dynamic>> _staffList = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadStaffFromDatabase();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.removeListener(() {});
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStaffFromDatabase() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final response = await supabase
          .from('employee')
          .select()
          .order('id', ascending: true);

      if (!mounted) return;
      setState(() {
        _staffList = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки данных: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surface;
    final borderColor = widget.isDarkMode ? Color(0xFF30363D) : Color(0xFFE2E8F0);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final textSecondary = widget.isDarkMode ? Color(0xFF8B949E) : Color(0xFF64748B);

    final q = _searchController.text.trim().toLowerCase();
    final List<Map<String, dynamic>> filtered = _staffList.where((s) {
      final name = ('${s['surname'] ?? ''} ${s['name'] ?? ''} ${s['patronymic'] ?? ''}').toLowerCase();
      final email = (s['email'] ?? '').toString().toLowerCase();
      return q.isEmpty || name.contains(q) || email.contains(q);
    }).toList();

    return Column(
      children: [
        // Поиск сотрудников - обёртка как в StudentsScreen
        Padding(
          padding: EdgeInsets.symmetric(vertical: 0),
          child: Row(
            children: [
              Expanded(
                child: SearchRow(
                  controller: _searchController,
                  hintText: 'Поиск по имени или email...',
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24),

        // Таблица сотрудников
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                // Заголовки
                Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: widget.isDarkMode ? Color(0xFF161B22) : Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 1, child: Text('ID', style: headerStyle(onSurface))),
                      Expanded(flex: 2, child: Text('ФИО', style: headerStyle(onSurface))),
                      Expanded(flex: 2, child: Text('Email', style: headerStyle(onSurface))),
                      Expanded(flex: 1, child: Text('Пароль', style: headerStyle(onSurface))),
                      Expanded(flex: 1, child: Text('Статус', style: headerStyle(onSurface), textAlign: TextAlign.center)),
                      Expanded(flex: 1, child: Text('Дата устройства', style: headerStyle(onSurface), textAlign: TextAlign.center)),
                      Expanded(flex: 1, child: Text('Действия', style: headerStyle(onSurface), textAlign: TextAlign.center)),
                    ],
                  ),
                ),
                // Строки
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : _staffList.isEmpty
                          ? Center(
                              child: Text(
                                'Нет данных о сотрудниках',
                                style: TextStyle(
                                  color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: filtered.length,
                              itemBuilder: (ctx, i) {
                                final staff = filtered[i];
                                final hovered = _hoveredIndex == i;
                                final isFired = staff['status'] == false;
                                final isVisible = _passwordVisibility[i] ?? false;

                                String fullName = [
                                  staff['surname'] ?? '',
                                  staff['name'] ?? '',
                                  staff['patronymic'] ?? ''
                                ].where((x) => x.isNotEmpty).join(' ');
                                if (fullName.isEmpty) fullName = 'Не указано';

                                String deviceDate = '';
                                if (staff['device_date'] != null) {
                                  try {
                                    deviceDate = DateFormat('dd.MM.yyyy').format(DateTime.parse(staff['device_date']));
                                  } catch (_) {
                                    deviceDate = staff['device_date'].toString();
                                  }
                                } else {
                                  deviceDate = 'Нет даты';
                                }

                                return MouseRegion(
                                  onEnter: (_) => setState(() => _hoveredIndex = i),
                                  onExit: (_) => setState(() => _hoveredIndex = null),
                                  cursor: SystemMouseCursors.click,
                                  child: Container(
                                    padding: EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: hovered
                                          ? (widget.isDarkMode ? Color(0xFF21262D) : Color(0xFFF0F4F8))
                                          : Colors.transparent,
                                      border: Border(bottom: BorderSide(color: borderColor)),
                                    ),
                                    child: Row(
                                      children: [
                                        // ID
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            '${staff['id']}',
                                            style: rowTextStyle(
                                              isFired
                                                  ? (widget.isDarkMode ? Color(0xFF6B7280) : Color(0xFF9CA3AF))
                                                  : onSurface,
                                            ),
                                          ),
                                        ),
                                        // ФИО
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            fullName,
                                            style: rowTextStyle(
                                              isFired
                                                  ? (widget.isDarkMode ? Color(0xFF6B7280) : Color(0xFF9CA3AF))
                                                  : onSurface,
                                            ),
                                          ),
                                        ),
                                        // Email
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            staff['email'] ?? 'Не указан',
                                            style: rowTextStyle(
                                              isFired
                                                  ? (widget.isDarkMode ? Color(0xFF6B7280) : Color(0xFF9CA3AF))
                                                  : textSecondary,
                                            ),
                                          ),
                                        ),
                                        // Пароль
                                        Expanded(
                                          flex: 1,
                                          child: Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  isVisible ? (staff['password'] ?? '••••••••') : '••••••••',
                                                  style: TextStyle(
                                                    color: isFired
                                                        ? (widget.isDarkMode ? Color(0xFF6B7280) : Color(0xFF9CA3AF))
                                                        : textSecondary,
                                                    fontSize: 14,
                                                    fontFamily: 'monospace',
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              SizedBox(width: 4),
                                              IconButton(
                                                icon: Icon(
                                                  isVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                                  size: 16,
                                                ),
                                                padding: EdgeInsets.zero,
                                                constraints: BoxConstraints(minWidth: 28, minHeight: 28),
                                                onPressed: () {
                                                  setState(() {
                                                    _passwordVisibility[i] = !isVisible;
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Статус
                                        Expanded(
                                          flex: 1,
                                          child: Center(
                                            child: Container(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: isFired
                                                    ? Colors.red.withValues(alpha: 0.12)
                                                    : Colors.green.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: isFired
                                                      ? Colors.red.withValues(alpha: 0.4)
                                                      : Colors.green.withValues(alpha: 0.4),
                                                ),
                                              ),
                                              child: Text(
                                                isFired ? 'Неактивен' : 'Активен',
                                                style: TextStyle(
                                                  color: isFired ? Colors.red : Colors.green,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Дата устройства
                                        Expanded(
                                          flex: 1,
                                          child: Center(
                                            child: Text(
                                              deviceDate,
                                              style: rowTextStyle(textSecondary),
                                            ),
                                          ),
                                        ),
                                        // Действия
                                        Expanded(
                                          flex: 1,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.edit_rounded, size: 18),
                                                onPressed: () => _editStaff(staff),
                                                tooltip: 'Редактировать',
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.person_off_rounded, size: 18, color: Colors.red),
                                                onPressed: () => _deleteStaff(staff['id'], staff),
                                                tooltip: 'Удалить',
                                              ),
                                            ],
                                          ),
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
          ),
        ),
      ],
    );
  }

  TextStyle headerStyle(Color color) => TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: color,
      );

  TextStyle rowTextStyle(Color color) => TextStyle(
        fontSize: 14,
        color: color,
      );

  void showAddStaffDialog() {
    _showAddStaffDialog(context);
  }

  void _editStaff(Map<String, dynamic> staff) {
    _showEditStaffDialog(context, staff);
  }

  void _showEditStaffDialog(BuildContext context, Map<String, dynamic> staff) {
    final surnameController = TextEditingController(text: staff['surname'] ?? '');
    final nameController = TextEditingController(text: staff['name'] ?? '');
    final patronymicController = TextEditingController(text: staff['patronymic'] ?? '');
    final emailController = TextEditingController(text: staff['email'] ?? '');
    final passwordController = TextEditingController();
    final deviceDateController = TextEditingController(text: staff['device_date'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Редактировать сотрудника'),
        content: SizedBox(
          width: 700,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: surnameController,
                  decoration: InputDecoration(labelText: 'Фамилия', contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12)),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Имя', contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12)),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: patronymicController,
                  decoration: InputDecoration(labelText: 'Отчество', contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12)),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email', contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12)),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Пароль (оставьте пустым чтобы не менять)',
                    contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  ),
                  obscureText: true,
                  style: TextStyle(height: 1.2),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: deviceDateController,
                  decoration: InputDecoration(
                    labelText: 'Дата устройства (yyyy-MM-dd)',
                    hintText: '2024-11-01',
                    contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isEmpty || nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Заполните, пожалуйста, имя и email')),
                );
                return;
              }

              final updated = <String, dynamic>{
                'surname': surnameController.text,
                'name': nameController.text,
                'patronymic': patronymicController.text,
                'email': emailController.text,
                'device_date': deviceDateController.text,
              };

              if (passwordController.text.isNotEmpty) {
                updated['password'] = passwordController.text;
              }

              try {
                await supabase.from('employee').update(updated).eq('id', staff['id']);
                Navigator.pop(context);
                await _loadStaffFromDatabase();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Сотрудник обновлён')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка обновления: $e')),
                );
              }
            },
            child: Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStaff(int id, Map<String, dynamic> staff) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Уволить сотрудника?'),
        content: Text('Сотрудник будет помечен как неактивный. Это действие можно отменить через административную панель.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Уволить', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase.from('employee').update({
        'status': false,
        'fired_at': DateTime.now().toIso8601String(),
      }).eq('id', id);

      await _loadStaffFromDatabase();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Сотрудник помечен как неактивный')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  void _showAddStaffDialog(BuildContext context) {
    final surnameController = TextEditingController();
    final nameController = TextEditingController();
    final patronymicController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final deviceDateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Добавить сотрудника'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: surnameController,
                decoration: InputDecoration(labelText: 'Фамилия', contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12)),
              ),
              SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Имя', contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12)),
              ),
              SizedBox(height: 12),
              TextField(
                controller: patronymicController,
                decoration: InputDecoration(labelText: 'Отчество', contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12)),
              ),
              SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email', contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12)),
              ),
              SizedBox(height: 12),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Пароль', contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12)),
                obscureText: true,
              ),
              SizedBox(height: 12),
              TextField(
                controller: deviceDateController,
                decoration: InputDecoration(
                  labelText: 'Дата устройства (yyyy-MM-dd)',
                  hintText: '2024-11-01',
                  contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
              try {
                await supabase.from('employee').insert({
                  'surname': surnameController.text,
                  'name': nameController.text,
                  'patronymic': patronymicController.text,
                  'email': emailController.text,
                  'password': passwordController.text,
                  'device_date': deviceDateController.text,
                  'status': true,
                });
                Navigator.pop(context);
                await _loadStaffFromDatabase();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Сотрудник добавлен')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка: $e')),
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
