class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderType;
  final String text;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderType,
    required this.text,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id']?.toString() ?? '',
      chatId: json['id_room']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      senderType: json['sender_type']?.toString() ?? 'user',
      text: json['message']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_room': int.tryParse(chatId),
      'sender_id': int.tryParse(senderId),
      'sender_type': senderType,
      'message': text,
      'created_at': createdAt.toIso8601String(),
    };
  }
}