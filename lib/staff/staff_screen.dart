import 'package:flutter/material.dart';

class StaffScreen extends StatefulWidget {
  final bool isDarkMode;

  const StaffScreen({
    Key? key,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  StaffScreenState createState() => StaffScreenState();
}

class StaffScreenState extends State<StaffScreen> {
  int? _hoveredIndex;
  final Map<int, bool> _passwordVisibility = {};
  List<Map<String, String>> _staffList = [];

  @override
  void initState() {
    super.initState();
    _staffList = _getInitialStaffList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Только поиск сотрудников (без кнопки добавления)
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Поиск по имени или email...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 24),

        // Список сотрудников
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: widget.isDarkMode
                ? Border.all(color: Color(0xFF30363D))
                : null,
            ),
            child: Column(
              children: [
                // Заголовки таблицы
                Container(
                  padding: EdgeInsets.all(14), // Уменьшено с 20 до 14
                  decoration: BoxDecoration(
                    color: widget.isDarkMode ? Color(0xFF161B22) : Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    border: Border(bottom: BorderSide(
                      color: widget.isDarkMode ? Color(0xFF30363D) : Color(0xFFE2E8F0),
                    )),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'ФИО',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Email',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1, // Уменьшено с 2 до 1
                        child: Text(
                          'Пароль',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Должность',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2 , // Увеличено с 1 до 2
                        child: Text(
                          'Телефон',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2, // Увеличено с 1 до 2
                        child: Text(
                          'Дата устройства',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Статус',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Действия',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Список администраторов
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _staffList.length,
                    itemBuilder: (context, index) {
                      return _buildStaffRow(context, index);
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

  // Публичный метод для добавления сотрудника (будет вызван из TopBar)
  void showAddStaffDialog() {
    _showAddStaffDialog(context);
  }

  List<Map<String, String>> _getInitialStaffList() {
    return [
      {
        'name': 'Александр Иванов',
        'email': 'a.ivanov@courseadmin.com',
        'password': 'admin123',
        'role': 'Администратор',
        'phone': '+7 (905) 123-45-67',
        'joinDate': '15 января 2022',
        'status': 'Активен'
      },
      {
        'name': 'Мария Петрова',
        'email': 'm.petrova@courseadmin.com',
        'password': 'pass456',
        'role': 'Администратор',
        'phone': '+7 (905) 234-56-78',
        'joinDate': '22 марта 2022',
        'status': 'Активен'
      },
      {
        'name': 'Дмитрий Сидоров',
        'email': 'd.sidorov@courseadmin.com',
        'password': 'secure789',
        'role': 'Администратор',
        'phone': '+7 (905) 345-67-89',
        'joinDate': '08 мая 2021',
        'status': 'Активен'
      },
      {
        'name': 'Анна Козлова',
        'email': 'a.kozlova@courseadmin.com',
        'password': 'admin321',
        'role': 'Администратор',
        'phone': '+7 (905) 456-78-90',
        'joinDate': '12 сентября 2022',
        'status': 'Уволен'
      },
      {
        'name': 'Сергей Морозов',
        'email': 's.morozov@courseadmin.com',
        'password': 'pass654',
        'role': 'Администратор',
        'phone': '+7 (905) 567-89-01',
        'joinDate': '25 ноября 2021',
        'status': 'Активен'
      },
      {
        'name': 'Елена Волкова',
        'email': 'e.volkova@courseadmin.com',
        'password': 'secure987',
        'role': 'Администратор',
        'phone': '+7 (905) 678-90-12',
        'joinDate': '03 февраля 2023',
        'status': 'Активен'
      },
      {
        'name': 'Игорь Лебедев',
        'email': 'i.lebedev@courseadmin.com',
        'password': 'admin111',
        'role': 'Администратор',
        'phone': '+7 (905) 789-01-23',
        'joinDate': '17 апреля 2022',
        'status': 'Активен'
      },
      {
        'name': 'Ольга Федорова',
        'email': 'o.fedorova@courseadmin.com',
        'password': 'pass222',
        'role': 'Администратор',
        'phone': '+7 (905) 890-12-34',
        'joinDate': '30 июня 2021',
        'status': 'Уволен'
      },
    ];
  }

  Widget _buildStaffRow(BuildContext context, int index) {
    final staff = _staffList[index];
    final bool isVisible = _passwordVisibility[index] ?? false;
    final bool isHovered = _hoveredIndex == index;
    final bool isFired = staff['status'] == 'Уволен';

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      cursor: SystemMouseCursors.click,
      child: Container(
        padding: EdgeInsets.all(14), // Уменьшено с 20 до 14
        decoration: BoxDecoration(
          color: isHovered 
            ? (widget.isDarkMode ? Color(0xFF21262D) : Color(0xFFF0F4F8))
            : Colors.transparent,
          border: Border(bottom: BorderSide(
            color: widget.isDarkMode ? Color(0xFF30363D) : Color(0xFFE2E8F0),
            width: 1,
          )),
        ),
        child: Row(
          children: [
            // ФИО
            Expanded(
              flex: 2,
              child: Text(
                staff['name']!,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isFired 
                    ? (widget.isDarkMode ? Color(0xFF6B7280) : Color(0xFF9CA3AF))
                    : Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                ),
              ),
            ),
            
            // Email
            Expanded(
              flex: 2,
              child: Text(
                staff['email']!,
                style: TextStyle(
                  color: isFired
                    ? (widget.isDarkMode ? Color(0xFF6B7280) : Color(0xFF9CA3AF))
                    : (widget.isDarkMode ? Color(0xFF8B949E) : Color(0xFF64748B)),
                  fontSize: 13,
                ),
              ),
            ),
            
            // Пароль с кнопкой (уменьшенная колонка)
            Expanded(
              flex: 1, // Уменьшено с 2 до 1
              child: Row(
                children: [
                  Flexible( // Изменено с Expanded на Flexible
                    child: Text(
                      isVisible ? staff['password']! : '••••••••',
                      style: TextStyle(
                        color: isFired
                          ? (widget.isDarkMode ? Color(0xFF6B7280) : Color(0xFF9CA3AF))
                          : (widget.isDarkMode ? Color(0xFF8B949E) : Color(0xFF64748B)),
                        fontSize: 14,
                        fontFamily: isVisible ? null : 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 6), // Уменьшено с 12 до 6
                  InkWell(
                    onTap: () {
                      setState(() {
                        _passwordVisibility[index] = !isVisible;
                      });
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 16,
                        color: isFired 
                          ? (widget.isDarkMode ? Color(0xFF6B7280) : Color(0xFF9CA3AF))
                          : Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Должность
            Expanded(
              flex: 2,
              child: Text(
                staff['role']!,
                style: TextStyle(
                  color: isFired
                    ? (widget.isDarkMode ? Color(0xFF6B7280) : Color(0xFF9CA3AF))
                    : Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                ),
              ),
            ),
            
            // Телефон (увеличенная колонка)
            Expanded(
              flex: 2, // Увеличено с 1 до 2
              child: Text(
                staff['phone']!,
                style: TextStyle(
                  color: isFired
                    ? (widget.isDarkMode ? Color(0xFF6B7280) : Color(0xFF9CA3AF))
                    : (widget.isDarkMode ? Color(0xFF8B949E) : Color(0xFF64748B)),
                  fontSize: 14,
                ),
              ),
            ),
            
            // Дата устройства (увеличенная колонка)
            Expanded(
              flex: 2, // Увеличено с 1 до 2
              child: Text(
                staff['joinDate']!,
                style: TextStyle(
                  color: isFired
                    ? (widget.isDarkMode ? Color(0xFF6B7280) : Color(0xFF9CA3AF))
                    : (widget.isDarkMode ? Color(0xFF8B949E) : Color(0xFF64748B)),
                  fontSize: 14,
                ),
              ),
            ),

            // Статус
            Expanded(
              flex: 1,
              child: Container(
                alignment: Alignment.center,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isFired 
                      ? Color(0xFFEF4444).withOpacity(0.1)
                      : Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    staff['status']!,
                    style: TextStyle(
                      color: isFired ? Color(0xFFEF4444) : Color(0xFF10B981),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // Действия (кнопки редактировать и уволить/восстановить)
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Кнопка редактирования
                  InkWell(
                    onTap: () {
                      _showEditDialog(context, staff, index);
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: isFired 
                          ? (widget.isDarkMode ? Color(0xFF6B7280) : Color(0xFF9CA3AF))
                          : Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 8),
                  
                  // Кнопка увольнения/восстановления
                  InkWell(
                    onTap: () {
                      if (isFired) {
                        _showRestoreDialog(context, staff['name']!, index);
                      } else {
                        _showFireDialog(context, staff['name']!, index);
                      }
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        isFired ? Icons.restore_rounded : Icons.person_remove_outlined,
                        size: 18,
                        color: isFired ? Color(0xFF10B981) : Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddStaffDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();
    final _roleController = TextEditingController();
    final _phoneController = TextEditingController();
    final _dateController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Добавить нового сотрудника'),
          content: Container(
            width: 500,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ФИО
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'ФИО *',
                        hintText: 'Введите полное имя',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите ФИО';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email *',
                        hintText: 'example@courseadmin.com',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите email';
                        }
                        if (!value.contains('@')) {
                          return 'Введите корректный email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Пароль
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Пароль *',
                        hintText: 'Минимум 6 символов',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите пароль';
                        }
                        if (value.length < 6) {
                          return 'Пароль должен быть минимум 6 символов';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Должность
                    TextFormField(
                      controller: _roleController,
                      decoration: InputDecoration(
                        labelText: 'Должность *',
                        hintText: 'Например: Администратор курсов',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите должность';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Телефон
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Телефон *',
                        hintText: '+7 (900) 123-45-67',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите номер телефона';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Дата устройства
                    TextFormField(
                      controller: _dateController,
                      decoration: InputDecoration(
                        labelText: 'Дата устройства *',
                        hintText: '15 января 2024',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите дату устройства';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  setState(() {
                    _staffList.add({
                      'name': _nameController.text,
                      'email': _emailController.text,
                      'password': _passwordController.text,
                      'role': _roleController.text,
                      'phone': _phoneController.text,
                      'joinDate': _dateController.text,
                      'status': 'Активен',
                    });
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Сотрудник ${_nameController.text} добавлен')),
                  );
                }
              },
              child: Text('Добавить'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, Map<String, String> staff, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Редактировать сотрудника'),
          content: Text('Здесь будет форма редактирования для ${staff['name']}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Данные ${staff['name']} обновлены')),
                );
              },
              child: Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  void _showFireDialog(BuildContext context, String name, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Уволить сотрудника'),
          content: Text('Вы уверены, что хотите уволить $name?\n\nСотрудник будет переведен в статус "Уволен", но останется в системе.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _staffList[index]['status'] = 'Уволен';
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$name уволен'),
                    backgroundColor: Color(0xFFEF4444),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFEF4444),
              ),
              child: Text('Уволить'),
            ),
          ],
        );
      },
    );
  }

  void _showRestoreDialog(BuildContext context, String name, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Восстановить сотрудника'),
          content: Text('Вы хотите восстановить $name в должности?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _staffList[index]['status'] = 'Активен';
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$name восстановлен'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF10B981),
              ),
              child: Text('Восстановить'),
            ),
          ],
        );
      },
    );
  }
}