import 'package:flutter/material.dart';
import '../core/theme/app_components.dart';
import '../models/database_models.dart' as db_models;
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class StudentProfileScreen extends StatefulWidget {
  final bool isDarkMode;
  final db_models.User student;

  const StudentProfileScreen({super.key, required this.isDarkMode, required this.student});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  late bool _isBlocked;
  bool _isLoadingData = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _activeCourses = [];
  List<Map<String, dynamic>> _certificates = [];
  List<Map<String, dynamic>> _achievements = [];

  @override
  void initState() {
    super.initState();
    _isBlocked = !(widget.student.status ?? true);
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
    });

    try {
      // 1. Загружаем все курсы для маппинга
      final coursesData = await SupabaseService.safeDbCall(
        () => SupabaseService.client.from('courses').select('id, name, icon')
      );
      final Map<int, Map<String, dynamic>> coursesMap = {
        for (var c in coursesData as List) c['id'] as int: c as Map<String, dynamic>
      };

      // 2. Загружаем активные курсы из таблицы user_courses
      final userCoursesData = await SupabaseService.safeDbCall(
        () => SupabaseService.client
          .from('user_courses')
          .select('id_courses, purchase_date')
          .eq('id_user', widget.student.id)
      );

      final List<Map<String, dynamic>> active = [];
      for (var uc in userCoursesData as List) {
        final int? courseId = uc['id_courses'] as int?;
        if (courseId != null && coursesMap.containsKey(courseId)) {
          final courseInfo = coursesMap[courseId]!;
          active.add({
            'name': courseInfo['name'] ?? 'Курс',
            'icon': courseInfo['icon'] ?? '📚',
            'progress': 0, // Условный прогресс
            'completed': false,
            'date': uc['purchase_date'],
          });
        }
      }

      // 3. Загружаем сертификаты из таблицы certificates
      final certsData = await SupabaseService.safeDbCall(
        () => SupabaseService.client
          .from('certificates')
          .select('id_courses, issue_date')
          .eq('id_user', widget.student.id)
      );

      final List<Map<String, dynamic>> certs = [];
      for (var c in certsData as List) {
        final int? courseId = c['id_courses'] as int?;
        if (courseId != null && coursesMap.containsKey(courseId)) {
          final courseInfo = coursesMap[courseId]!;
          certs.add({
            'name': courseInfo['name'] ?? 'Курс',
            'icon': courseInfo['icon'] ?? '📚',
            'date': c['issue_date'],
          });
        }
      }

      // 4. Загружаем все достижения для маппинга
      final allAchievementsData = await SupabaseService.safeDbCall(
        () => SupabaseService.client.from('achievement').select('id, name, image')
      );
      final Map<int, Map<String, dynamic>> achievementsMap = {
        for (var a in allAchievementsData as List) a['id'] as int: a as Map<String, dynamic>
      };

      // 5. Загружаем достижения студента
      final userAchievementsData = await SupabaseService.safeDbCall(
        () => SupabaseService.client
          .from('achievements_user')
          .select('id_achievements')
          .eq('id_user', widget.student.id)
      );

      final List<Map<String, dynamic>> loadedAchievements = [];
      for (var ua in userAchievementsData as List) {
        final int? achId = ua['id_achievements'] as int?;
        if (achId != null && achievementsMap.containsKey(achId)) {
          final achInfo = achievementsMap[achId]!;
          loadedAchievements.add({
            'name': achInfo['name'] ?? 'Достижение',
            'image': achInfo['image'],
            'date': null, // В этой таблице нет даты получения, можно оставить null
          });
        }
      }

      if (mounted) {
        setState(() {
          _activeCourses = active;
          _certificates = certs;
          _achievements = loadedAchievements;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки данных студента: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
        
        // Автоматический повтор через 3 секунды
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) _loadStudentData();
        });
      }
    }
  }


  Future<void> _toggleBlockStatus() async {
    final newStatus = !_isBlocked; // Если был заблокирован (true), то новый статус активен (status = true в БД)
    final dbStatus = !newStatus; // status в БД: true = активен, false = заблокирован
    
    try {
      await SupabaseService.client
          .from('users')
          .update({'status': dbStatus})
          .eq('id', widget.student.id);
      
      setState(() {
        _isBlocked = newStatus;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(dbStatus ? 'Студент разблокирован' : 'Студент заблокирован'),
            backgroundColor: dbStatus ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления статуса: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.bgLight, // Светлый фон приложения
      appBar: AppBar(
        title: Text('Профиль студента', style: AppStyles.h1.copyWith(fontSize: 20)),
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textGrey),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.bgLight, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Левая панель: Основная информация
            SizedBox(
              width: 380,
              child: Column(
                children: [
                  _buildMainInfoCard(),
                  const SizedBox(height: 24),
                  _buildActionCard(),
                ],
              ),
            ),
            const SizedBox(width: 32),
            // Правая панель: Контент
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Активные курсы', style: AppStyles.h1.copyWith(fontSize: 22)),
                  const SizedBox(height: 16),
                  if (_errorMessage != null)
                    Text('Повторная попытка загрузки... (${_errorMessage})', style: AppStyles.label.copyWith(color: Colors.red))
                  else if (_isLoadingData)
                    const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple))
                  else if (_activeCourses.isEmpty)
                    Text('Студент пока не записан ни на один курс.', style: AppStyles.label)
                  else
                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: _activeCourses.map((c) => _buildCourseCard(c)).toList(),
                    ),
                  
                  const SizedBox(height: 40),
                  _buildSectionHeader('Достижения'),
                  const SizedBox(height: 16),
                  if (_errorMessage != null)
                    Text('Повторная попытка загрузки...', style: AppStyles.label.copyWith(color: Colors.red))
                  else if (_isLoadingData)
                    const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple))
                  else if (_achievements.isEmpty)
                    Text('У студента пока нет достижений.', style: AppStyles.label)
                  else
                    ..._achievements.map((a) => _buildAchievementTile(a)),
                  
                  const SizedBox(height: 40),
                  _buildSectionHeader('Сертификаты'),
                  const SizedBox(height: 16),
                  if (_errorMessage != null)
                    Text('Повторная попытка загрузки...', style: AppStyles.label.copyWith(color: Colors.red))
                  else if (_isLoadingData)
                    const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple))
                  else if (_certificates.isEmpty)
                    Text('У студента пока нет сертификатов.', style: AppStyles.label)
                  else
                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: _certificates.map((c) => _buildCertificateCard(c)).toList(),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainInfoCard() {
    final displayName = widget.student.name ?? widget.student.email ?? 'Студент';
    final avatarLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    String formatDate(DateTime? d) => d == null ? '—' : DateFormat('dd.MM.yyyy HH:mm').format(d.toLocal());

    return KodixComponents.cardContainer(
      child: Column(
        children: [
          // Аватар
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [BoxShadow(color: AppColors.primaryPurple.withValues(alpha: 0.3), blurRadius: 15)],
            ),
            child: widget.student.avatar != null && widget.student.avatar!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      widget.student.avatar!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(avatarLetter),
                    ),
                  )
                : _buildAvatarPlaceholder(avatarLetter),
          ),
          const SizedBox(height: 16),
          Text(displayName, style: AppStyles.h1.copyWith(fontSize: 24), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(widget.student.email ?? 'Нет email', style: AppStyles.label),
          const SizedBox(height: 24),
          const Divider(color: AppColors.bgLight),
          _buildInfoItem('ID пользователя', '${widget.student.id}'),
          _buildInfoItem('Регистрация', formatDate(widget.student.dateRegistration)),
          _buildInfoItem('Последний вход', formatDate(widget.student.lastEntry)),
          const SizedBox(height: 16),
          _buildStatusBadge(),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String letter) {
    return Center(
      child: Text(letter, style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final progress = course['progress'] as int;
    
    return Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.bgLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    course['icon'] as String,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(course['name'] as String, style: AppStyles.body.copyWith(fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 8,
              backgroundColor: AppColors.bgLight,
              color: AppColors.primaryPurple,
            ),
          ),
          const SizedBox(height: 10),
          Text('$progress% пройдено', style: AppStyles.label.copyWith(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCertificateCard(Map<String, dynamic> cert) {
    String formatDate(String? dateStr) {
      if (dateStr == null) return 'Завершено';
      try {
        final d = DateTime.parse(dateStr).toLocal();
        return DateFormat('dd.MM.yyyy').format(d);
      } catch (e) {
        return 'Завершено';
      }
    }

    return Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.bgLight),
        boxShadow: [
          BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(Icons.workspace_premium_rounded, color: Color(0xFF10B981)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(cert['name'] as String, style: AppStyles.body.copyWith(fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Выдан: ${formatDate(cert['date']?.toString())}', style: AppStyles.label.copyWith(fontSize: 12)),
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard() {
    return KodixComponents.cardContainer(
      child: Column(
        children: [
          OutlinedButton.icon(
            onPressed: _toggleBlockStatus,
            icon: Icon(_isBlocked ? Icons.lock_open_rounded : Icons.block_rounded, size: 18),
            label: Text(_isBlocked ? 'Разблокировать' : 'Заблокировать'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _isBlocked ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              side: BorderSide(color: _isBlocked ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppStyles.label),
          Text(value, style: AppStyles.body.copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final color = _isBlocked ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Center(
        child: Text(_isBlocked ? 'Заблокирован' : 'Активен', style: AppStyles.label.copyWith(color: color, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildAchievementTile(Map<String, dynamic> ach) {
    final title = ach['name'] as String? ?? 'Достижение';
    final imageUrl = ach['image'] as String?;
    
    String dateStr = '—';
    if (ach['date'] != null) {
      try {
        final d = DateTime.parse(ach['date']).toLocal();
        dateStr = DateFormat('dd.MM.yyyy').format(d);
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.bgLight)),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.hardEdge,
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    SupabaseService.client.storage.from('achievements').getPublicUrl(imageUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.stars_rounded, color: AppColors.primaryPurple),
                  )
                : const Icon(Icons.stars_rounded, color: AppColors.primaryPurple),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: AppStyles.body.copyWith(fontWeight: FontWeight.w600))),
          Text(dateStr, style: AppStyles.label.copyWith(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(title, style: AppStyles.h1.copyWith(fontSize: 22)),
        const SizedBox(width: 16),
        const Expanded(child: Divider(color: AppColors.bgLight)),
      ],
    );
  }
}