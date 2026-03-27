import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/email_service.dart';
import 'repositories/password_recovery_repository.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final bool isDarkMode;
  final ValueChanged<bool> onToggleTheme;

  const AuthScreen({
    super.key,
    required this.onLoginSuccess,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;

  final String bgImage =
      "https://image.winudf.com/v2/image/bW9iaS5hbmRyb2FwcC5wcm9zcGVyaXR5YXBwcy5jNTExMV9zY3JlZW5fN18xNTI0MDQxMDUwXzAyMQ/screen-7.jpg?fakeurl=1&type=.jpg";

  final supabase = Supabase.instance.client;

  Future<void> _tryLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
        final response = await supabase
            .from('employee')
            .select()
            .eq('email', _loginController.text.trim())
            .maybeSingle();

        if (response == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Пользователь не найден')),
            );
          }
        } else {
          if (response['password'] == _passwordController.text &&
              response['status'] == true) {
            if (mounted) {
              widget.onLoginSuccess();
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Неверный логин или пароль')),
              );
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showPasswordRecoveryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Запрещаем закрывать кликом мимо
      builder: (context) => const PasswordRecoveryDialog(),
    ).then((recoveredEmail) {
      // Если диалог вернул email (после успешного сброса), подставляем его в логин
      if (recoveredEmail != null && recoveredEmail is String) {
        setState(() {
          _loginController.text = recoveredEmail;
          _passwordController.clear();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 7,
            child: Image.network(
              bgImage,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withOpacity(0.3),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Добро пожаловать",
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _loginController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: "Логин",
                                  prefixIcon: const Icon(Icons.person_outline),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                validator: (v) => (v == null || v.isEmpty) ? "Введите логин" : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_showPassword,
                                decoration: InputDecoration(
                                  labelText: "Пароль",
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  suffixIcon: IconButton(
                                    icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                                    onPressed: () => setState(() => _showPassword = !_showPassword),
                                  ),
                                ),
                                validator: (v) => (v == null || v.isEmpty) ? "Введите пароль" : null,
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _showPasswordRecoveryDialog,
                                  child: Text("Забыли пароль?", style: TextStyle(color: theme.colorScheme.primary)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _tryLogin,
                                  child: _isLoading
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : const Text("Войти", style: TextStyle(fontSize: 16)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

// ============================================================================
// УМНОЕ ДИАЛОГОВОЕ ОКНО ВОССТАНОВЛЕНИЯ ПАРОЛЯ
// ============================================================================

class PasswordRecoveryDialog extends StatefulWidget {
  const PasswordRecoveryDialog({super.key});

  @override
  State<PasswordRecoveryDialog> createState() => _PasswordRecoveryDialogState();
}

class _PasswordRecoveryDialogState extends State<PasswordRecoveryDialog> {
  int _currentStep = 0; // 0: Email, 1: Код, 2: Новый пароль, 3: Успех
  bool _isLoading = false;
  String? _errorMessage;

  // Контроллеры для разных шагов
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirm = false;

  final supabase = Supabase.instance.client;
  final repository = PasswordRecoveryRepository();

  // --- ЛОГИКА ШАГОВ ---

  Future<void> _submitEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !RegExp(r"^[^@]+@[^@]+\.[^@]+$").hasMatch(email)) {
      setState(() => _errorMessage = "Введите корректный email");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Проверяем, есть ли такой юзер в базе
      final user = await supabase
          .from('employee')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (user == null) {
        setState(() => _errorMessage = "Пользователь с таким email не найден");
        return;
      }

      // 2. Отправляем код на почту (Яндекс.Почта)
      final recoveryCode = await EmailService.sendRecoveryCode(email);
      if (recoveryCode == null) {
        setState(() => _errorMessage = "Ошибка сервера. Не удалось отправить код.");
        return;
      }

      // 3. Сохраняем код локально
      await repository.saveRecoveryCode(email, recoveryCode);

      // Переходим к вводу кода
      setState(() {
        _currentStep = 1;
      });
    } catch (e) {
      setState(() => _errorMessage = "Ошибка: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _errorMessage = "Введите 6-значный код");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Проверяем код локально
      final isValid = await repository.verifyRecoveryCode(_emailController.text.trim(), code);

      if (isValid) {
        setState(() => _currentStep = 2); // Идем придумывать новый пароль
      } else {
        setState(() => _errorMessage = "Неверный или просроченный код");
      }
    } catch (e) {
      setState(() => _errorMessage = "Ошибка: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitPassword() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.length < 6) {
      setState(() => _errorMessage = "Пароль должен содержать минимум 6 символов");
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = "Пароли не совпадают");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Обновляем пароль в БД
      await supabase
          .from('employee')
          .update({'password': password.trim()})
          .eq('email', _emailController.text.trim());

      setState(() => _currentStep = 3); // Идем на экран успеха
    } catch (e) {
      setState(() => _errorMessage = "Не удалось сохранить пароль: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- ИНТЕРФЕЙС ШАГОВ ---

  Widget _buildStep0Email() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Введите ваш email, привязанный к аккаунту. Мы отправим на него код подтверждения."),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: const Icon(Icons.email),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            errorText: _errorMessage,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitEmail,
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Отправить код'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep1Code() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Проверьте вашу почту (и папку Спам). Введите полученный 6-значный код ниже."),
        const SizedBox(height: 16),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            counterText: "",
            hintText: "000000",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            errorText: _errorMessage,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitCode,
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Подтвердить'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2Password() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Код подтвержден! Придумайте новый надежный пароль."),
        const SizedBox(height: 16),
        if (_errorMessage != null) ...[
           Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
           const SizedBox(height: 8),
        ],
        TextField(
          controller: _passwordController,
          obscureText: !_showPassword,
          decoration: InputDecoration(
            labelText: 'Новый пароль',
            prefixIcon: const Icon(Icons.lock),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: IconButton(
              icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmController,
          obscureText: !_showConfirm,
          decoration: InputDecoration(
            labelText: 'Повторите пароль',
            prefixIcon: const Icon(Icons.lock_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: IconButton(
              icon: Icon(_showConfirm ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _showConfirm = !_showConfirm),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitPassword,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Сохранить', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3Success() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 64),
        const SizedBox(height: 16),
        const Text(
          "Ура! Пароль успешно изменён.",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text("Теперь вы можете войти в систему с новым паролем."),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            // Закрываем диалог и передаем email обратно на главный экран
            onPressed: () => Navigator.of(context).pop(_emailController.text.trim()),
            child: const Text('Войти'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Выбираем какой контент показывать в зависимости от шага
    Widget content;
    String title;

    switch (_currentStep) {
      case 0:
        title = 'Восстановление пароля';
        content = _buildStep0Email();
        break;
      case 1:
        title = 'Ввод кода';
        content = _buildStep1Code();
        break;
      case 2:
        title = 'Смена пароля';
        content = _buildStep2Password();
        break;
      case 3:
      default:
        title = 'Успех';
        content = _buildStep3Success();
        break;
    }

    return AlertDialog(
      title: Text(title),
      contentPadding: const EdgeInsets.all(24),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400, // Фиксированная ширина, чтобы диалог не прыгал
          child: content,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }
}