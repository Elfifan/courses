import 'package:flutter/material.dart';
import '../students/student_profile_screen.dart';

class StudentsScreen extends StatefulWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final bool isDarkMode;

  const StudentsScreen({
    Key? key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  _StudentsScreenState createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  int? _hoveredIndex;
  final List<Map<String, String>> _students = [
    {'avatar': 'А', 'name': 'Анна Петрова', 'email': 'anna.petrova@email.com'},
    {'avatar': 'М', 'name': 'Михаил Смирнов', 'email': 'mikhail.smirnov@email.com'},
    {'avatar': 'Е', 'name': 'Екатерина Волкова', 'email': 'ekaterina.volkova@email.com'},
    {'avatar': 'Д', 'name': 'Дмитрий Козлов', 'email': 'dmitriy.kozlov@email.com'},
    {'avatar': 'О', 'name': 'Ольга Морозова', 'email': 'olga.morozova@email.com'},
    {'avatar': 'С', 'name': 'Светлана Орлова', 'email': 'svetlana.orlova@email.com'},
    {'avatar': 'И', 'name': 'Игорь Федоров', 'email': 'igor.fedorov@email.com'},
    {'avatar': 'А', 'name': 'Артем Соколов', 'email': 'artem.sokolov@email.com'},
  ];

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surface;
    final borderColor = widget.isDarkMode ? Color(0xFF30363D) : Color(0xFFE2E8F0);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final textSecondary = widget.isDarkMode ? Color(0xFF8B949E) : Color(0xFF64748B);

    return Column(
      children: [
        // Поиск и фильтр
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Поиск студентов по имени или email...',
                  prefixIcon: Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
                onChanged: widget.onFilterChanged,
              ),
            ),
            SizedBox(width: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: DropdownButton<String>(
                value: widget.selectedFilter,
                underline: SizedBox(),
                items: ['Все пользователи', 'Активные', 'Неактивные', 'Новые']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) widget.onFilterChanged(v);
                },
              ),
            ),
          ],
        ),

        SizedBox(height: 24),

        // Таблица студентов
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
                      Expanded(flex: 1, child: Text('Аватар', style: headerStyle(onSurface))),
                      Expanded(flex: 3, child: Text('ФИО', style: headerStyle(onSurface))),
                      Expanded(flex: 4, child: Text('Email', style: headerStyle(onSurface))),
                    ],
                  ),
                ),
                // Строки
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _students.length,
                    itemBuilder: (ctx, i) {
                      final s = _students[i];
                      final hovered = _hoveredIndex == i;
                      return MouseRegion(
                        onEnter: (_) => setState(() => _hoveredIndex = i),
                        onExit: (_) => setState(() => _hoveredIndex = null),
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => StudentProfileScreen(isDarkMode: widget.isDarkMode),
                              ),
                            );
                          },
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
                                Expanded(
                                  flex: 1,
                                  child: CircleAvatar(
                                    backgroundColor: Theme.of(context).primaryColor,
                                    child: Text(s['avatar']!, style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(s['name']!, style: rowTextStyle(onSurface)),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Text(s['email']!, style: rowTextStyle(textSecondary)),
                                ),
                              ],
                            ),
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
}
