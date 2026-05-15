import 'package:flutter/material.dart';
import '../core/theme/app_components.dart';
import '../services/supabase_service.dart';

class AuthorsManagementScreen extends StatefulWidget {
  const AuthorsManagementScreen({super.key});

  @override
  State<AuthorsManagementScreen> createState() =>
      _AuthorsManagementScreenState();
}

class _AuthorsManagementScreenState extends State<AuthorsManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _authors = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAuthors();
  }

  Future<void> _loadAuthors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await SupabaseService.client
          .from('employee')
          .select()
          .eq('role', 'Автор')
          .order('surname', ascending: true);

      if (mounted) {
        setState(() {
          _authors = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleAuthorStatus(int id, bool currentStatus) async {
    try {
      await SupabaseService.client
          .from('employee')
          .update({'status': !currentStatus})
          .eq('id', id);

      _loadAuthors();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления статуса: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryPurple),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки авторов',
              style: AppStyles.h1.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(_errorMessage!, style: AppStyles.label),
            const SizedBox(height: 24),
            KodixComponents.primaryButton(
              onPressed: _loadAuthors,
              child: const Text('Попробовать снова'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Управление авторами', style: AppStyles.h1),
        const SizedBox(height: 8),
        Text(
          'Список всех зарегистрированных авторов и их статус доступа',
          style: AppStyles.label,
        ),
        const SizedBox(height: 32),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: AppStyles.cardRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: AppStyles.cardRadius,
              child: _authors.isEmpty
                  ? const Center(child: Text('Авторы не найдены'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(24),
                      itemCount: _authors.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, color: AppColors.bgLight),
                      itemBuilder: (context, index) {
                        final author = _authors[index];
                        final bool isActive = author['status'] ?? false;
                        final String fullName =
                            '${author['surname'] ?? ''} ${author['name'] ?? ''} ${author['patronymic'] ?? ''}'
                                .trim();

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryPurple.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    author['surname']
                                            ?.substring(0, 1)
                                            .toUpperCase() ??
                                        '?',
                                    style: AppStyles.h1.copyWith(
                                      fontSize: 20,
                                      color: AppColors.primaryPurple,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fullName,
                                      style: AppStyles.body.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      author['email'] ?? 'Нет email',
                                      style: AppStyles.label.copyWith(
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (isActive
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFF59E0B))
                                          .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isActive ? 'Активен' : 'Ожидает одобрения',
                                  style: AppStyles.label.copyWith(
                                    color: isActive
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFF59E0B),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              SizedBox(
                                width: 180,
                                child: KodixComponents.primaryButton(
                                  height: 36,
                                  onPressed: () => _toggleAuthorStatus(
                                    author['id'],
                                    isActive,
                                  ),
                                  backgroundColor: isActive
                                      ? Colors.red.withValues(alpha: 0.1)
                                      : AppColors.primaryPurple,
                                  child: Text(
                                    isActive ? 'Деактивировать' : 'Одобрить',
                                    style: TextStyle(
                                      color: isActive
                                          ? Colors.red
                                          : Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
