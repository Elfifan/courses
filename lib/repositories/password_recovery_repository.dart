class PasswordRecoveryRepository {
  // Статическое хранилище в оперативной памяти (сохраняется, пока приложение запущено)
  static final Map<String, _RecoveryData> _localStore = {};

  /// Сохраняет код восстановления локально
  Future<void> saveRecoveryCode(String email, String code) async {
    // Просто записываем код и время его истечения (15 минут) в словарь
    _localStore[email] = _RecoveryData(
      code: code,
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
    );
    
    // Очищаем старые просроченные коды, чтобы не засорять память
    _cleanupExpiredCodes();
  }

  /// Проверяет введенный код
  Future<bool> verifyRecoveryCode(String email, String code) async {
    final data = _localStore[email];
    
    // Если для этого email нет кода — ошибка
    if (data == null) return false;
    
    // Если код уже был успешно использован — ошибка
    if (data.used) return false;
    
    // Если прошло больше 15 минут — ошибка
    if (DateTime.now().isAfter(data.expiresAt)) return false;
    
    // Если код не совпадает — ошибка
    if (data.code != code) return false;

    // Если всё верно, помечаем код как использованный
    data.used = true;
    return true;
  }

  /// Внутренний метод для очистки просроченных кодов из памяти
  void _cleanupExpiredCodes() {
    _localStore.removeWhere((key, data) => 
        DateTime.now().isAfter(data.expiresAt) || data.used);
  }
}

/// Вспомогательный класс для хранения данных о коде
class _RecoveryData {
  final String code;
  final DateTime expiresAt;
  bool used;

  _RecoveryData({
    required this.code,
    required this.expiresAt,
    this.used = false,
  });
}