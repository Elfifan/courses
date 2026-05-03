import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/database_models.dart';
import '../models/message_model.dart';

class ChatThread {
  final String chatId;
  final String otherUserId;
  final String displayName;
  final String lastMessage;
  final DateTime lastUpdated;
  final int? courseId;

  ChatThread({
    required this.chatId,
    required this.otherUserId,
    required this.displayName,
    required this.lastMessage,
    required this.lastUpdated,
    this.courseId,
  });

  ChatThread copyWith({String? displayName}) {
    return ChatThread(
      chatId: chatId,
      otherUserId: otherUserId,
      displayName: displayName ?? this.displayName,
      lastMessage: lastMessage,
      lastUpdated: lastUpdated,
      courseId: courseId,
    );
  }
}

class ChatRepository {
  final supabase = Supabase.instance.client;

  /// Создать или получить комнату чата
  Future<int> getOrCreateRoom({
    required int userId,
    required int courseId,
  }) async {
    // Проверяем, существует ли уже комната
    final existing = await supabase
        .from('chat_rooms')
        .select('id')
        .eq('id_user', userId)
        .eq('id_courses', courseId)
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as int;
    }

    // Создаем новую комнату
    final newRoom = await supabase
        .from('chat_rooms')
        .insert({
          'id_user': userId,
          'id_courses': courseId,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return newRoom['id'] as int;
  }

  /// Загрузка сообщений
  Future<List<MessageModel>> loadMessages(String chatId) async {
    final roomId = int.tryParse(chatId);
    if (roomId == null) return [];

    final result = await supabase
        .from('chat_messages')
        .select('id, id_room, sender_type, sender_id, message, is_read, created_at')
        .eq('id_room', roomId)
        .order('created_at', ascending: true);

    return (result as List)
        .map((e) => MessageModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Отправка сообщения
  Future<MessageModel?> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    required String senderType,
  }) async {
    final roomId = int.tryParse(chatId);
    final sId = int.tryParse(senderId);
    if (roomId == null || sId == null) return null;

    final result = await supabase
        .from('chat_messages')
        .insert({
          'id_room': roomId,
          'sender_type': senderType,
          'sender_id': sId,
          'message': text,
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return MessageModel.fromJson(Map<String, dynamic>.from(result as Map));
  }

  /// Загрузка списка чатов для автора
  Future<List<ChatThread>> loadAuthorThreads(String authorId) async {
    final authorIdInt = int.tryParse(authorId);
    if (authorIdInt == null) return [];

    // Получаем все комнаты для курсов этого автора
    final roomsResult = await supabase
        .from('chat_rooms')
        .select('''
          id,
          id_user,
          id_courses,
          created_at,
          courses!inner(id, id_employee, name)
        ''')
        .eq('courses.id_employee', authorIdInt)
        .order('created_at', ascending: false);

    final rooms = roomsResult as List;
    if (rooms.isEmpty) return [];

    final List<ChatThread> threads = [];

    for (final room in rooms) {
      final roomId = room['id'] as int;
      final userId = room['id_user'] as int;
      final courseData = room['courses'] as Map<String, dynamic>;
      final courseName = courseData['name']?.toString() ?? 'Курс';

      // Получаем последнее сообщение
      final lastMsgResult = await supabase
          .from('chat_messages')
          .select('message, created_at, sender_type')
          .eq('id_room', roomId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final lastMessage = lastMsgResult?['message']?.toString() ?? 'Нет сообщений';
      final lastUpdated = lastMsgResult?['created_at'] != null
          ? DateTime.tryParse(lastMsgResult!['created_at'].toString()) ?? DateTime.now()
          : DateTime.now();

      // Получаем данные пользователя
      final userResult = await supabase
          .from('users')
          .select('id, name, email')
          .eq('id', userId)
          .maybeSingle();

      final userName = userResult?['name']?.toString() ?? 
                       userResult?['email']?.toString() ?? 
                       'Пользователь $userId';

      threads.add(ChatThread(
        chatId: roomId.toString(),
        otherUserId: userId.toString(),
        displayName: '$userName ($courseName)',
        lastMessage: lastMessage,
        lastUpdated: lastUpdated,
        courseId: courseData['id'] as int?,
      ));
    }

    threads.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
    return threads;
  }

  /// Realtime подписка
  Stream<MessageModel> subscribeToMessages(String chatId) {
    final roomId = int.tryParse(chatId);
    
    final channel = supabase.channel(
      'chat-$chatId',
      opts: const RealtimeChannelConfig(),
    );

    final controller = StreamController<MessageModel>();

    controller.onCancel = () async {
      await channel.unsubscribe();
      await controller.close();
    };

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'chat_messages',
      filter: roomId != null
          ? PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id_room',
              value: roomId,
            )
          : null,
      callback: (payload) {
        final messageJson = Map<String, dynamic>.from(payload.newRecord);
        controller.add(MessageModel.fromJson(messageJson));
      },
    );

    channel.subscribe();

    return controller.stream;
  }
}