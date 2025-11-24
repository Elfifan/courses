import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  _AuthScreenState createState() => _AuthScreenState();
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
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _onForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Восстановление пароля...')),
    );
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
              color: Colors.black.withValues(alpha: 0.3),
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
                          style: theme.textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
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
                                  border: InputBorder.none,
                                  enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Colors.grey.shade400)),
                                  focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: theme.colorScheme.primary)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 18, horizontal: 0),
                                ),
                                validator: (v) => (v == null || v.isEmpty) ? "Введите логин" : null,
                              ),
                              const SizedBox(height: 22),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_showPassword,
                                decoration: InputDecoration(
                                  labelText: "Пароль",
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  border: InputBorder.none,
                                  enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Colors.grey.shade400)),
                                  focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: theme.colorScheme.primary)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 18, horizontal: 0),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                        _showPassword ? Icons.visibility : Icons.visibility_off),
                                    onPressed: () =>
                                        setState(() => _showPassword = !_showPassword),
                                  ),
                                ),
                                validator: (v) =>
                                    (v == null || v.isEmpty) ? "Введите пароль" : null,
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _onForgotPassword,
                                  child: Text(
                                    "Забыли пароль?",
                                    style: TextStyle(color: theme.colorScheme.primary),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _tryLogin,
                                  child: _isLoading
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : const Text("Войти"),
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
