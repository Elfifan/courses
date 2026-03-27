import 'dart:async';
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

  DateTime? _nextResetPasswordEmailAt;

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
                const SnackBar(content: Text('Неверный логин или пароль (или аккаунт отключен)')),
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

  Future<void> _onForgotPassword() async {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final emailResult = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Восстановление пароля'),
          contentPadding: const EdgeInsets.all(24),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Введите ваш email, привязанный к аккаунту.'),
                const SizedBox(height: 16),
                Form(
                  key: formKey,
                  child: TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Введите email';
                      if (!RegExp(r"^[^@]+@[^@]+\.[^@]+$").hasMatch(value)) {
                        return 'Введите корректный email';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(context).pop(emailController.text.trim());
                }
              },
              child: const Text('Получить код'),
            ),
          ],
        );
      },
    );

    if (emailResult == null) return;

    try {
      // 1. ПРОВЕРЯЕМ, ЕСТЬ ЛИ ПОЧТА В ПРИНЦИПЕ В БАЗЕ
      final user = await supabase
          .from('employee')
          .select('id, email')
          .eq('email', emailResult)
          .maybeSingle();

      if (user == null) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Ошибка'),
              content: const Text('Пользователь с таким email не найден в системе.'),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Ок'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // 2. ОТПРАВЛЯЕМ КОД И СОХРАНЯЕМ В БАЗУ
      final emailSent = await _sendRecoveryCodeEmail(emailResult);
      if (!emailSent) return;

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('✅ Код отправлен'),
            content: const Text('Проверьте папку "Входящие" и "Спам". Код действителен 15 минут.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Закрываем диалог
                  // Переходим на экран ввода кода и смены пароля
                  Navigator.of(context).pushNamed('/reset-password', arguments: emailResult);
                },
                child: const Text('Ввести код'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<bool> _sendRecoveryCodeEmail(String toEmail) async {
    final now = DateTime.now();
    // Защита от спама (1 раз в минуту)
    if (_nextResetPasswordEmailAt != null && now.isBefore(_nextResetPasswordEmailAt!)) {
      final waitSeconds = _nextResetPasswordEmailAt!.difference(now).inSeconds;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Подождите $waitSeconds сек. перед следующей отправкой.')),
        );
      }
      return false;
    }

    try {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Отправляем письмо...'),
              ],
            ),
          ),
        );
      }

      // Генерируем и отправляем код через ваш Gmail
      final recoveryCode = await EmailService.sendRecoveryCode(toEmail);
      
      if (recoveryCode == null) {
        if (mounted) Navigator.of(context).pop(); // Убираем лоадер
        throw Exception("Сбой SMTP сервера");
      }

      // Сохраняем код в Supabase для дальнейшей проверки
      final repository = PasswordRecoveryRepository();
      await repository.saveRecoveryCode(toEmail, recoveryCode);

      _nextResetPasswordEmailAt = DateTime.now().add(const Duration(minutes: 1));

      if (mounted) Navigator.of(context).pop(); // Убираем лоадер
      return true;

    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // Убираем лоадер
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка отправки: $e')),
        );
      }
      return false;
    }
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
                                  onPressed: _onForgotPassword,
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

// -------------------------------------------------------------------
// ЭКРАН СБРОСА ПАРОЛЯ
// -------------------------------------------------------------------

class ResetPasswordScreen extends StatefulWidget {
  final String? email;
  final bool isDarkMode;
  final ValueChanged<bool> onToggleTheme;
  final VoidCallback onSuccess;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onSuccess,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirm = false;
  bool _codeVerified = false;

  Future<void> _verifyCode() async {
    if (_codeController.text.trim().isEmpty || _codeController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите 6-значный код из письма')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = PasswordRecoveryRepository();
      // 3. ПРОВЕРЯЕМ ВВЕДЕННЫЙ КОД
      final isValid = await repository.verifyRecoveryCode(
        widget.email ?? '',
        _codeController.text.trim(),
      );

      if (isValid) {
        setState(() => _codeVerified = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Код подтверждён! Установите новый пароль.')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Неверный или просроченный код')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      
      // ИСПРАВЛЕНИЕ: Обновляем пароль ТОЛЬКО в таблице employee.
      // Метод supabase.auth.updateUser удален, так как пользователь не авторизован в Supabase Auth.
      if (widget.email != null) {
        await supabase
            .from('employee')
            .update({'password': _passwordController.text.trim()})
            .eq('email', widget.email!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Пароль успешно изменён! Вы можете войти.')),
        );
      }

      // Вызываем коллбек успеха, который вернет нас на главную
      widget.onSuccess();
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Ошибка'),
            content: Text('Не удалось изменить пароль:\n$e'),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Ок'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сброс пароля'),
        actions: [
          Switch(value: widget.isDarkMode, onChanged: widget.onToggleTheme),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: widget.email,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Ваш Email',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ШАГ 1: Ввод кода (Показываем пока код не подтвержден)
                      if (!_codeVerified) ...[
                        TextFormField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: InputDecoration(
                            labelText: 'Код восстановления из письма',
                            prefixIcon: const Icon(Icons.security),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _verifyCode,
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Проверить код'),
                          ),
                        ),
                      ],

                      // ШАГ 2: Ввод нового пароля (Показываем после ввода правильного кода)
                      if (_codeVerified) ...[
                        TextFormField(
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
                          validator: (value) => (value == null || value.length < 6) ? 'Минимум 6 символов' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmController,
                          obscureText: !_showConfirm,
                          decoration: InputDecoration(
                            labelText: 'Повторите пароль',
                            prefixIcon: const Icon(Icons.lock),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            suffixIcon: IconButton(
                              icon: Icon(_showConfirm ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _showConfirm = !_showConfirm),
                            ),
                          ),
                          validator: (value) => value != _passwordController.text ? 'Пароли не совпадают' : null,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _changePassword,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Сохранить новый пароль', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }
}