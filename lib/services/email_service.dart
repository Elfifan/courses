import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  // Новые настройки для Яндекс.Почты
  static const String _smtpHost = 'smtp.yandex.ru';
  static const int _smtpPort = 465; // Яндекс использует порт 465 для SSL-соединения
  static const String _username = 'vergunovcyril@yandex.ru';
  static const String _password = 'sqebwoxmgbldyfsf';

  static SmtpServer get _smtpServer {
    return SmtpServer(
      _smtpHost,
      port: _smtpPort,
      username: _username,
      password: _password,
      ignoreBadCertificate: false,
      ssl: true, // Обязательно true для порта 465 Яндекса
      allowInsecure: false,
    );
  }

  /// Генерирует 6-значный код восстановления
  static String _generateRecoveryCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Отправляет код восстановления пароля на email
  static Future<String?> sendRecoveryCode(String toEmail) async {
    try {
      final recoveryCode = _generateRecoveryCode();

      final message = Message()
        ..from = const Address(_username, 'CYRS App')
        ..recipients.add(toEmail)
        ..subject = 'Код восстановления пароля - CYRS'
        ..html = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Восстановление пароля</title>
</head>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
    <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
        <h2 style="color: #2c3e50; text-align: center;">Восстановление пароля</h2>
        
        <p>Здравствуйте!</p>
        
        <p>Вы запросили восстановление пароля для приложения CYRS.</p>
        
        <div style="background-color: #f8f9fa; border: 1px solid #dee2e6; border-radius: 5px; padding: 20px; margin: 20px 0; text-align: center;">
            <h3 style="margin: 0 0 10px 0; color: #495057;">Ваш код восстановления:</h3>
            <div style="font-size: 32px; font-weight: bold; color: #007bff; letter-spacing: 3px; background-color: #e9ecef; padding: 15px; border-radius: 5px; display: inline-block;">
                $recoveryCode
            </div>
        </div>
        
        <p><strong>Важно:</strong></p>
        <ul>
            <li>Код действителен в течение 15 минут</li>
            <li>Не сообщайте этот код никому</li>
            <li>Если вы не запрашивали восстановление пароля, проигнорируйте это письмо</li>
        </ul>
        
        <p>Если у вас возникли проблемы, обратитесь в службу поддержки.</p>
        
        <hr style="border: none; border-top: 1px solid #dee2e6; margin: 30px 0;">
        
        <p style="color: #6c757d; font-size: 12px; text-align: center;">
            Это автоматическое письмо. Пожалуйста, не отвечайте на него.
        </p>
    </div>
</body>
</html>
        ''';

      final sendReport = await send(message, _smtpServer);
      print('Email sent: ${sendReport.toString()}');

      return recoveryCode;
    } catch (e) {
      print('Error sending email: $e');
      return null;
    }
  }
}