import 'package:flutter/material.dart';
import '../core/theme/app_components.dart'; // Ваша дизайн-система

class StudentProfileScreen extends StatefulWidget {
  final bool isDarkMode;

  const StudentProfileScreen({super.key, required this.isDarkMode});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  bool _showPassword = false;
  bool _isBlocked = false;

  @override
  Widget build(BuildContext context) {
    // Данные студента (сохранены из оригинала)
    final student = {
      'avatar': 'А',
      'name': 'Анна Петрова',
      'email': 'anna.petrova@email.com',
      'phone': '+7 (900) 123-45-67',
      'registration_date': '15 марта 2024',
      'password': 'mypass123',
      'last_login': '20 сентября, 18:45',
    };

    final courses = [
      {'name': 'Python для начинающих', 'icon': Icons.code, 'progress': 85, 'completed': false},
      {'name': 'Flutter Mobile Dev', 'icon': Icons.phone_iphone, 'progress': 100, 'completed': true},
      {'name': 'JavaScript Advanced', 'icon': Icons.javascript, 'progress': 60, 'completed': false},
    ];

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
                  _buildMainInfoCard(student),
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
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: courses.map((c) => _buildCourseCard(c)).toList(),
                  ),
                  const SizedBox(height: 40),
                  _buildSectionHeader('Достижения и Сертификаты'),
                  const SizedBox(height: 16),
                  _buildAchievementTile('Сертификат Python', '10 сент.', Icons.workspace_premium),
                  _buildAchievementTile('Регистрация на платформе', '15 марта', Icons.stars_rounded),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainInfoCard(Map<String, String> student) {
    return KodixComponents.cardContainer(
      child: Column(
        children: [
          // Аватар с градиентом Кодикс[cite: 1]
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [BoxShadow(color: AppColors.primaryPurple.withOpacity(0.3), blurRadius: 15)],
            ),
            child: Center(
              child: Text(student['avatar']!, style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
          Text(student['name']!, style: AppStyles.h1.copyWith(fontSize: 24)),
          Text(student['email']!, style: AppStyles.label),
          const SizedBox(height: 24),
          const Divider(color: AppColors.bgLight),
          _buildInfoItem('Телефон', student['phone']!),
          _buildPasswordItem(student['password']!),
          _buildInfoItem('Регистрация', student['registration_date']!),
          _buildInfoItem('Последний вход', student['last_login']!),
          const SizedBox(height: 16),
          _buildStatusBadge(),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Map course) {
    final isComplete = course['completed'] as bool;
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
              Icon(course['icon'] as IconData, color: AppColors.primaryPurple),
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
              color: isComplete ? const Color(0xFF10B981) : AppColors.primaryPurple,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$progress% завершено', style: AppStyles.label.copyWith(fontSize: 12)),
              if (isComplete) const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
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
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('Редактировать профиль'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => setState(() => _isBlocked = !_isBlocked),
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

  Widget _buildPasswordItem(String password) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Пароль', style: AppStyles.label),
          Row(
            children: [
              Text(_showPassword ? password : '••••••••', style: AppStyles.body.copyWith(fontWeight: FontWeight.bold)),
              IconButton(
                icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, size: 18, color: AppColors.textGrey),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final color = _isBlocked ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Center(
        child: Text(_isBlocked ? 'Заблокирован' : 'Активен', style: AppStyles.label.copyWith(color: color, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildAchievementTile(String title, String date, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.bgLight)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryPurple, size: 24),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: AppStyles.body.copyWith(fontWeight: FontWeight.w600))),
          Text(date, style: AppStyles.label.copyWith(fontSize: 12)),
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