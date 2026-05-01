import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_components.dart'; // Ваша дизайн-система
import '../models/database_models.dart' as db_models;
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
    // Цвета из дизайн-системы
    final borderColor = AppColors.bgLight; 
    final q = _searchController.text.trim().toLowerCase();
    
    List<db_models.User> filtered = _students.where((s) {
      final name = (s.name ?? '').toLowerCase();
      final email = (s.email ?? '').toLowerCase();
      final matchesSearch = q.isEmpty || name.contains(q) || email.contains(q);

      bool matchesFilter = true;
      switch (widget.selectedFilter) {
        case 'Активные': matchesFilter = s.status == true; break;
        case 'Неактивные': matchesFilter = s.status == false; break;
        case 'Новые':
          if (s.dateRegistration == null) {
            matchesFilter = false;
          } else {
            matchesFilter = DateTime.now().difference(s.dateRegistration!).inDays <= 7;
          }
          break;
        default: matchesFilter = true;
      }
      return matchesSearch && matchesFilter;
    }).toList();

    String formatDate(DateTime? d) => d == null ? '—' : DateFormat('dd.MM.yyyy HH:mm').format(d.toLocal());

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SearchRow(
                controller: _searchController,
                hintText: 'Поиск студентов по имени или email...',
                onChanged: (_) => setState(() {}),
                trailing: _buildFilterDropdown(), // Стилизованный фильтр
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: AppStyles.cardRadius, // 24px
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 8))
              ],
            ),
            child: Column(
              children: [
                // Обновленные заголовки таблицы
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  decoration: BoxDecoration(
                    color: AppColors.bgLight.withOpacity(0.5),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 1, child: Text('ID', style: AppStyles.label.copyWith(fontWeight: FontWeight.bold))),
                      Expanded(flex: 1, child: Text('Аватар', style: AppStyles.label.copyWith(fontWeight: FontWeight.bold))),
                      Expanded(flex: 3, child: Text('ФИО', style: AppStyles.label.copyWith(fontWeight: FontWeight.bold))),
                      Expanded(flex: 3, child: Text('Email', style: AppStyles.label.copyWith(fontWeight: FontWeight.bold))),
                      Expanded(flex: 3, child: Text('Последний вход', style: AppStyles.label.copyWith(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('Статус', style: AppStyles.label.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple))
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
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => StudentProfileScreen(isDarkMode: widget.isDarkMode),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: hovered ? AppColors.bgLight.withOpacity(0.3) : Colors.transparent,
                                    border: Border(bottom: BorderSide(color: borderColor)),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(flex: 1, child: Text('${s.id}', style: AppStyles.body.copyWith(fontSize: 13))),
                                      Expanded(
                                        flex: 1,
                                        child: CircleAvatar(
                                          radius: 18,
                                          backgroundColor: AppColors.primaryPurple.withOpacity(0.1),
                                          child: Text(avatarLetter, style: const TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold, fontSize: 14)),
                                        ),
                                      ),
                                      Expanded(flex: 3, child: Text(displayName, style: AppStyles.body.copyWith(fontWeight: FontWeight.w600))),
                                      Expanded(flex: 3, child: Text(s.email ?? '', style: AppStyles.label)),
                                      Expanded(flex: 3, child: Text(formatDate(s.lastEntry), style: AppStyles.label)),
                                      Expanded(
                                        flex: 2,
                                        child: Center(child: _buildStatusBadge(s.status == true)),
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

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.bgLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: widget.selectedFilter,
          icon: const Icon(Icons.filter_list_rounded, size: 18, color: AppColors.primaryPurple),
          style: AppStyles.body.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
          items: ['Все пользователи', 'Активные', 'Неактивные', 'Новые']
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) {
            if (v != null) widget.onFilterChanged(v);
          },
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    final color = isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isActive ? 'Активен' : 'Заблокирован',
        style: AppStyles.label.copyWith(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}