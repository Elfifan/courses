import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_components.dart';
import '../services/chat_service.dart';
import '../models/message_model.dart';
import '../repositories/chat_repository.dart';

/// ===============================
/// CONTROLLER
/// ===============================
class ChatController extends ChangeNotifier {
  final ChatService service;
  final String chatId;
  final String currentUserId;
  final String senderType;

  List<MessageModel> messages = [];
  bool isLoading = true;
  String? errorMessage;
  StreamSubscription<MessageModel>? _subscription;

  ChatController({
    required this.service,
    required this.chatId,
    required this.currentUserId,
    this.senderType = 'employee',
  });

  Future<void> init() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      messages = await service.loadMessages(chatId);
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } catch (error) {
      errorMessage = 'Ошибка загрузки истории: $error';
    } finally {
      isLoading = false;
      notifyListeners();
    }

    // Подписка на новые сообщения в реальном времени
    _subscription = service.subscribe(chatId).listen(
      (msg) {
        if (!messages.any((existing) => existing.id == msg.id)) {
          messages.add(msg);
          messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          notifyListeners();
        }
      },
      onError: (error) {
        errorMessage = 'Ошибка realtime-подписки: $error';
        notifyListeners();
      },
    );
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    try {
      final message = await service.sendMessage(
        chatId: chatId,
        senderId: currentUserId,
        text: trimmed,
        senderType: senderType,
      );
      if (message != null && !messages.any((m) => m.id == message.id)) {
        messages.add(message);
        messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        notifyListeners();
      }
    } catch (error) {
      errorMessage = 'Ошибка отправки сообщения: $error';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// ===============================
/// MAIN CHAT PAGE
/// ===============================
class ChatPage extends StatelessWidget {
  final String chatId;
  final String currentUserId;
  final String senderType;

  const ChatPage({
    super.key,
    required this.chatId,
    required this.currentUserId,
    this.senderType = 'employee',
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatController(
        service: ChatService(ChatRepository()),
        chatId: chatId,
        currentUserId: currentUserId,
        senderType: senderType,
      )..init(),
      child: const _ChatPageBody(),
    );
  }
}

class _ChatPageBody extends StatefulWidget {
  const _ChatPageBody();

  @override
  State<_ChatPageBody> createState() => _ChatPageBodyState();
}

class _ChatPageBodyState extends State<_ChatPageBody> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend(ChatController controller) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    await controller.send(text);
    _scrollToBottom();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChatController>();

    if (controller.messages.isNotEmpty) {
      _scrollToBottom();
    }

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textGrey, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Чат с пользователем',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Список сообщений
          Expanded(
            child: controller.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryPurple),
                  )
                : controller.errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: AppColors.textGrey.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            Text(controller.errorMessage!, style: AppStyles.label),
                          ],
                        ),
                      )
                    : controller.messages.isEmpty
                        ? Center(
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
                                  'Начните общение',
                                  style: AppStyles.h1.copyWith(fontSize: 18),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Ответьте на сообщение пользователя',
                                  style: AppStyles.label,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: controller.messages.length,
                            itemBuilder: (_, i) {
                              final msg = controller.messages[i];
                              final isMe = msg.senderId == controller.currentUserId;
                              return _buildMessageBubble(msg, isMe);
                            },
                          ),
          ),
          // Поле ввода
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(
                top: BorderSide(color: AppColors.bgLight, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      style: AppStyles.body.copyWith(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Сообщение...',
                        hintStyle: AppStyles.label,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        border: InputBorder.none,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSend(controller),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _handleSend(controller),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryPurple.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg, bool isMe) {
    final time = '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isMe ? AppColors.primaryGradient : null,
          color: isMe ? null : AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: isMe
                  ? AppColors.primaryPurple.withOpacity(0.2)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                color: isMe ? Colors.white : AppColors.textDark,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: isMe ? Colors.white.withOpacity(0.7) : AppColors.textGrey,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}