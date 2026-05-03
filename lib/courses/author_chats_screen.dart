import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_components.dart';
import '../repositories/chat_repository.dart';
import '../services/chat_service.dart';
import 'chat_full_page.dart';

class AuthorChatsScreen extends StatefulWidget {
  final int authorId;

  const AuthorChatsScreen({super.key, required this.authorId});

  @override
  State<AuthorChatsScreen> createState() => _AuthorChatsScreenState();
}

class _AuthorChatsScreenState extends State<AuthorChatsScreen> {
  final ChatService _chatService = ChatService(ChatRepository());
  bool _isLoading = true;
  String? _errorMessage;
  List<ChatThread> _threads = [];

  @override
  void initState() {
    super.initState();
    _loadThreads();
  }

  Future<void> _loadThreads() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final threads = await _chatService.loadAuthorThreads(widget.authorId.toString());
      if (mounted) {
        setState(() {
          _threads = threads;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Не удалось загрузить чаты: $e';
          _isLoading = false;
        });
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
            Icon(Icons.error_outline, size: 48, color: AppColors.textGrey.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: AppStyles.label),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadThreads,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_threads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 40,
                color: AppColors.primaryPurple.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Нет активных чатов',
              style: AppStyles.h1.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Пользователи смогут писать вам после покупки курса',
              style: AppStyles.label,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadThreads,
      color: AppColors.primaryPurple,
      child: ListView.builder(
        padding: const EdgeInsets.all(0),
        itemCount: _threads.length,
        itemBuilder: (context, index) {
          final thread = _threads[index];
          return _buildChatTile(thread);
        },
      ),
    );
  }

  Widget _buildChatTile(ChatThread thread) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppStyles.mainRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppStyles.mainRadius,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatPage(
                  chatId: thread.chatId,
                  currentUserId: widget.authorId.toString(),
                  senderType: 'employee',
                ),
              ),
            );
          },
          borderRadius: AppStyles.mainRadius,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Аватар пользователя
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      thread.displayName.isNotEmpty 
                          ? thread.displayName[0].toUpperCase() 
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Информация о чате
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        thread.displayName,
                        style: AppStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        thread.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppStyles.label.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Время
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(thread.lastUpdated),
                      style: AppStyles.label.copyWith(fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textGrey.withOpacity(0.5),
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн';
    } else {
      return DateFormat('dd.MM').format(dateTime);
    }
  }
}