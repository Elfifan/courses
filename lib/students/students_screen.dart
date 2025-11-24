import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cyrs/models.dart' as db_models;
import 'package:intl/intl.dart';
import '../shared/search_row.dart';
import '../students/student_profile_screen.dart';

class StudentsScreen extends StatefulWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final bool isDarkMode;

  const StudentsScreen({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.isDarkMode,
  });

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final supabase = Supabase.instance.client;
  int? _hoveredIndex;
  List<db_models.User> _students = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStudentsFromDatabase();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.removeListener(() {});
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentsFromDatabase() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase.from('users').select().order('id', ascending: true) as List<dynamic>;
      final users = response.map((e) {
        if (e is Map<String, dynamic>) return db_models.User.fromJson(e);
        return db_models.User.fromJson(Map<String, dynamic>.from(e));
      }).toList();
      if (!mounted) return;
      setState(() {
  _students = users.cast<db_models.User>();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка загрузки студентов: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surface;
    final borderColor = widget.isDarkMode ? Color(0xFF30363D) : Color(0xFFE2E8F0);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final textSecondary = widget.isDarkMode ? Color(0xFF8B949E) : Color(0xFF64748B);
  // Compute filtered list according to search and selected filter
    final q = _searchController.text.trim().toLowerCase();
    List<db_models.User> filtered = _students.where((s) {
      final name = (s.name ?? '').toLowerCase();
      final email = (s.email ?? '').toLowerCase();

      // filter by search (nickname or email)
      final matchesSearch = q.isEmpty || name.contains(q) || email.contains(q);

      // filter by selectedFilter from parent
      bool matchesFilter = true;
      switch (widget.selectedFilter) {
        case 'Активные':
          matchesFilter = s.status == true;
          break;
        case 'Неактивные':
          matchesFilter = s.status == false;
          break;
        case 'Новые':
          if (s.dateRegistration == null) {
            matchesFilter = false;
          } else {
            matchesFilter = DateTime.now().difference(s.dateRegistration!).inDays <= 7;
          }
          break;
        default:
          matchesFilter = true;
      }

      return matchesSearch && matchesFilter;
    }).toList();
    // helper to format last entry
    String formatDate(DateTime? d) => d == null ? '' : DateFormat('dd.MM.yyyy HH:mm').format(d.toLocal());

    return Column(
      children: [
        // Поиск и фильтр (без отступов, как в Courses)
        Row(
          children: [
            Expanded(
              child: SearchRow(
                controller: _searchController,
                hintText: 'Поиск студентов по имени или email...',
                onChanged: (_) => setState(() {}),
                trailing: Container(
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
                      Expanded(flex: 1, child: Text('ID', style: headerStyle(onSurface))),
                      Expanded(flex: 1, child: Text('Аватар', style: headerStyle(onSurface))),
                      Expanded(flex: 3, child: Text('ФИО', style: headerStyle(onSurface))),
                      Expanded(flex: 3, child: Text('Email', style: headerStyle(onSurface))),
                      Expanded(flex: 3, child: Text('Последний вход', style: headerStyle(onSurface))),
                      Expanded(flex: 2, child: Text('Статус', style: headerStyle(onSurface), textAlign: TextAlign.center)),
                    ],
                  ),
                ),
                // Строки
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) {
                            final s = filtered[i];
                            final hovered = _hoveredIndex == i;
                            final displayName = s.name ?? s.email ?? '';
                            final avatarLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
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
                                      Expanded(flex: 1, child: Text('${s.id}', style: rowTextStyle(onSurface))),
                                      Expanded(
                                        flex: 1,
                                        child: CircleAvatar(
                                          backgroundColor: Theme.of(context).primaryColor,
                                          child: Text(avatarLetter, style: TextStyle(color: Colors.white)),
                                        ),
                                      ),
                                      Expanded(flex: 3, child: Text(displayName, style: rowTextStyle(onSurface))),
                                      Expanded(flex: 3, child: Text(s.email ?? '', style: rowTextStyle(textSecondary))),
                                      Expanded(flex: 3, child: Text(formatDate(s.lastEntry), style: rowTextStyle(textSecondary))),
                                      Expanded(
                                        flex: 2,
                                        child: Center(
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: (s.status == true) ? Colors.green.withValues(alpha: 0.12) : Colors.red.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: (s.status == true) ? Colors.green.withValues(alpha: 0.4) : Colors.red.withValues(alpha: 0.4),
                                              ),
                                            ),
                                            child: Text(
                                              (s.status == true) ? 'Активен' : 'Заблокирован',
                                              style: TextStyle(
                                                color: (s.status == true) ? Colors.green : Colors.red,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
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
