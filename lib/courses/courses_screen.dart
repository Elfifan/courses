import 'package:flutter/material.dart';
import '../shared/widgets.dart';
import 'course_edit_screen.dart';

class CoursesScreen extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;
  final bool isDarkMode;

  const CoursesScreen({
    Key? key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Фильтры и поиск
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Поиск курсов по названию...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            SizedBox(width: 16),
            CustomDropdown(
              value: selectedFilter,
              items: ['Все', 'Бесплатные', 'Платные', 'Активные', 'В разработке', 'Завершенные'],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  onFilterChanged(newValue);
                }
              },
              isDarkMode: isDarkMode,
            ),
          ],
        ),

        SizedBox(height: 24),

        // Сетка курсов - 4 колонки
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 1.02,
            ),
            itemCount: 8,
            itemBuilder: (context, index) {
              return _buildCourseCard(context, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCourseCard(BuildContext context, int index) {
    final courses = [
      {
        'name': 'Python для начинающих', 
        'students': 234, 
        'status': 'active', 
        'image': '🐍', 
        'price': 'Бесплатно',
        'rating': 4.8,
        'description': 'Изучите основы Python: переменные, циклы, функции'
      },
      {
        'name': 'JavaScript Advanced', 
        'students': 0, 
        'status': 'draft', 
        'image': '⚡', 
        'price': 'Бесплатно',
        'rating': 4.5,
        'description': 'Углубленное изучение JS: асинхронность, замыкания, прототипы'
      },
      {
        'name': 'React.js Fundamentals', 
        'students': 189, 
        'status': 'active', 
        'image': '⚛️', 
        'price': 'Бесплатно',
        'rating': 4.6,
        'description': 'Создавайте интерактивные веб-приложения с компонентами'
      },
      {
        'name': 'Flutter Mobile Dev', 
        'students': 145, 
        'status': 'completed', 
        'image': '📱', 
        'price': 'Бесплатно',
        'rating': 4.7,
        'description': 'Разработка кроссплатформенных мобильных приложений'
      },
      {
        'name': 'Node.js Backend', 
        'students': 87, 
        'status': 'active', 
        'image': '🟢', 
        'price': 'Бесплатно',
        'rating': 4.4,
        'description': 'Создание серверных приложений, API'
      },
      {
        'name': 'Advanced Python', 
        'students': 89, 
        'status': 'active', 
        'image': '🐍', 
        'price': '₽12,990',
        'rating': 4.9,
        'description': 'Профессиональный Python: декораторы, метаклассы'
      },
      {
        'name': 'React Pro', 
        'students': 67, 
        'status': 'active', 
        'image': '⚛️', 
        'price': '₽15,990',
        'rating': 4.8,
        'description': 'Продвинутый React: Context API, Redux, тестирование'
      },
      {
        'name': 'Flutter Master', 
        'students': 34, 
        'status': 'active', 
        'image': '📱', 
        'price': '₽18,990',
        'rating': 4.7,
        'description': 'Мастерство Flutter: анимации, кастомные виджеты'
      },
    ];

    final course = courses[index];
    Color statusColor;
    String statusText;
    bool isPaid = course['price'] != 'Бесплатно';

    switch (course['status']) {
      case 'active':
        statusColor = Color(0xFF10B981);
        statusText = 'Активный';
        break;
      case 'draft':
        statusColor = Color(0xFFF59E0B);
        statusText = 'Черновик';
        break;
      case 'completed':
        statusColor = Color(0xFF6B7280);
        statusText = 'Завершен';
        break;
      default:
        statusColor = Color(0xFF6B7280);
        statusText = 'Неизвестно';
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isPaid
          ? Border.all(color: Color(0xFFF59E0B).withOpacity(0.3), width: 2)
          : (isDarkMode
              ? Border.all(color: Color(0xFF30363D))
              : null),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                course['image'] as String,
                style: TextStyle(fontSize: 25),
              ),
              Spacer(),
              if (isPaid)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 12),
                      SizedBox(width: 4),
                      Text(
                        'PRO',
                        style: TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // Статус курса
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          SizedBox(height: 14),
          
          // Название курса
          Text(
            course['name'] as String,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          SizedBox(height: 8),
          
          // Описание курса
          Expanded(
            child: Text(
              course['description'] as String,
              style: TextStyle(
                fontSize: 13,
                color: isDarkMode ? Color(0xFF8B949E) : Color(0xFF64748B),
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          SizedBox(height: 12),
          
          // Рейтинг курса
          Row(
            children: [
              Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFD700)),
              SizedBox(width: 4),
              Text(
                '${course['rating']}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.people_rounded, 
                size: 16, 
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7)
              ),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${course['students']}',
                  style: TextStyle(
                    color: isDarkMode ? Color(0xFF8B949E) : Color(0xFF64748B), 
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                course['price'] as String,
                style: TextStyle(
                  color: isPaid ? Color(0xFFF59E0B) : Color(0xFF10B981),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 14),
          
          // Кнопка редактирования
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CourseEditScreen(), // передаём текущий курс
        ),
      );
    },
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 10),
                textStyle: TextStyle(fontSize: 12),
              ),
              child: Text('Редактировать'),
            ),
          ),
        ],
      ),
    );
  }
}