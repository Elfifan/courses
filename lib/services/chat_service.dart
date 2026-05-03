import '../models/message_model.dart';
import '../repositories/chat_repository.dart';

class ChatService {
  final ChatRepository repo;

  ChatService(this.repo);

  Future<int> getOrCreateRoom({
    required int userId,
    required int courseId,
  }) => repo.getOrCreateRoom(userId: userId, courseId: courseId);

  Future<List<MessageModel>> loadMessages(String chatId) =>
      repo.loadMessages(chatId);

  Future<MessageModel?> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    required String senderType,
  }) => repo.sendMessage(
    chatId: chatId,
    senderId: senderId,
    text: text,
    senderType: senderType,
  );

  Future<List<ChatThread>> loadAuthorThreads(String authorId) =>
      repo.loadAuthorThreads(authorId);

  Stream<MessageModel> subscribe(String chatId) =>
      repo.subscribeToMessages(chatId);
}