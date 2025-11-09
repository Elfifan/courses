// course_edit_analytics_students_tab.dart
import 'package:flutter/material.dart';

class CourseEditAnalyticsStudentsTab extends StatelessWidget {
  const CourseEditAnalyticsStudentsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStudentCard(context, 'Всего записано', '1,234', Icons.people, Colors.blue),
              const SizedBox(width: 12),
              _buildStudentCard(context, 'Активных', '892', Icons.person, Colors.green),
              const SizedBox(width: 12),
              _buildStudentCard(context, 'Завершили', '456', Icons.school, Colors.orange),
              const SizedBox(width: 12),
              _buildStudentCard(context, 'Средний прогресс', '67%', Icons.trending_up, Colors.purple),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Аналитика курса', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildAnalyticsCard(context, 'Общий доход', '₽347,820', '+12.5%', Colors.green),
              const SizedBox(width: 12),
              _buildAnalyticsCard(context, 'Средний рейтинг', '4.8', '+0.2', Colors.amber),
              const SizedBox(width: 12),
              _buildAnalyticsCard(context, 'Время просмотра', '156 ч', '+8.3%', Colors.blue),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Последние регистрации', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: ListView.builder(
                itemCount: 8,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=${index + 1}'),
                    ),
                    title: Text('Пользователь ${index + 1}'),
                    subtitle: Text('student${index + 1}@example.com'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${65 + index * 5}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('прогресс', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(BuildContext context, String title, String value, String change, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(change, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
