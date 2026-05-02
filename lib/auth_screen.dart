import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_components.dart';
import '../services/email_service.dart';
import '../repositories/password_recovery_repository.dart';

class AuthScreen extends StatefulWidget {
  final ValueChanged<String?> onLoginSuccess;
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
  bool _isObscured = true;
  bool _isLoading = false;

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

        if (!mounted) return;

        if (response == null) {
          _showSnackBar('Пользователь не найден');
        } else {
          if (response['password'] == _passwordController.text &&
              response['status'] == true) {
            widget.onLoginSuccess(response['role'] as String?);
          } else {
            _showSnackBar('Неверный логин или пароль');
          }
        }
      } catch (e) {
        if (mounted) _showSnackBar('Ошибка: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showPasswordRecoveryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PasswordRecoveryDialog(),
    ).then((recoveredEmail) {
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
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Row(
        children: [
          Expanded(
            flex: 6,
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
              child: Center(
                child: Text(
                  'KODIX',
                  style: GoogleFonts.roboto(
                    fontSize: 120,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withValues(alpha: 0.2),
                    letterSpacing: 20,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Вход в систему', style: AppStyles.h1.copyWith(fontSize: 32)),
                      const SizedBox(height: 8),
                      Text('Введите ваши данные для доступа к панели', style: AppStyles.label),
                      const SizedBox(height: 48),
                      Text('Логин (Email)', style: AppStyles.label),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _loginController,
                        style: AppStyles.body,
                        decoration: KodixComponents.textFieldDecoration(
                          hintText: 'admin@kodix.ru',
                          prefixIcon: Icons.person_outline_rounded,
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? "Введите логин" : null,
                      ),
                      const SizedBox(height: 24),
                      Text('Пароль', style: AppStyles.label),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _isObscured,
                        style: AppStyles.body,
                        decoration: KodixComponents.textFieldDecoration(
                          hintText: '••••••••',
                          prefixIcon: Icons.lock_outline_rounded,
                        ).copyWith(
                          suffixIcon: MouseRegion(
                            child: IconButton(
                              icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility, color: AppColors.textGrey,),
                              onPressed: () => setState(() => _isObscured = !_isObscured),
                            ),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? "Введите пароль" : null,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: TextButton(
                            onPressed: _showPasswordRecoveryDialog,
                            child: Text("Забыли пароль?", 
                              style: AppStyles.label.copyWith(color: AppColors.primaryPurple, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _isLoading 
                        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple))
                        : MouseRegion(
                            child: KodixComponents.primaryButton(
                              text: 'Войти',
                              onTap: _tryLogin,
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- ИСПРАВЛЕННЫЙ ДИАЛОГ ВОССТАНОВЛЕНИЯ ---

class PasswordRecoveryDialog extends StatefulWidget {
  const PasswordRecoveryDialog({super.key});

  @override
  State<PasswordRecoveryDialog> createState() => _PasswordRecoveryDialogState();
}

class _PasswordRecoveryDialogState extends State<PasswordRecoveryDialog> {
  int _currentStep = 0; 
  bool _isLoading = false;
  String? _errorMessage;

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  final supabase = Supabase.instance.client;
  final repository = PasswordRecoveryRepository();

  Future<void> _handleAction() async {
    if (_currentStep == 0) {
      await _submitEmail();
    } else if (_currentStep == 1) {
      await _submitCode();
    } else if (_currentStep == 2) {
      await _submitPassword();
    } else {
      Navigator.of(context).pop(_emailController.text.trim());
    }
  }

  Future<void> _submitEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !RegExp(r"^[^@]+@[^@]+\.[^@]+$").hasMatch(email)) {
      setState(() => _errorMessage = "Введите корректный email");
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final user = await supabase.from('employee').select('id').eq('email', email).maybeSingle();
      if (user == null) {
        setState(() => _errorMessage = "Пользователь не найден");
        return;
      }
      final recoveryCode = await EmailService.sendRecoveryCode(email);
      if (recoveryCode == null) {
        setState(() => _errorMessage = "Ошибка отправки кода");
        return;
      }
      await repository.saveRecoveryCode(email, recoveryCode);
      setState(() => _currentStep = 1);
    } catch (e) {
      setState(() => _errorMessage = "Ошибка: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitCode() async {
    if (_codeController.text.length != 6) {
      setState(() => _errorMessage = "Введите 6 цифр");
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    final isValid = await repository.verifyRecoveryCode(_emailController.text.trim(), _codeController.text.trim());
    if (isValid) {
      setState(() => _currentStep = 2);
    } else {
      setState(() => _errorMessage = "Неверный код");
    }
    setState(() => _isLoading = false);
  }

  Future<void> _submitPassword() async {
    if (_passwordController.text.length < 6) {
      setState(() => _errorMessage = "Минимум 6 символов");
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      setState(() => _errorMessage = "Пароли не совпадают");
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await supabase.from('employee').update({'password': _passwordController.text.trim()}).eq('email', _emailController.text.trim());
      setState(() => _currentStep = 3);
    } catch (e) {
      setState(() => _errorMessage = "Ошибка БД: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Принудительно задаем светлую тему для диалога, чтобы текст не сливался
    return Theme(
      data: ThemeData.light(),
      child: AlertDialog(
        backgroundColor: AppColors.white, // Явный белый фон
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppStyles.cardRadius),
        title: Text(_getTitle(), style: AppStyles.h1.copyWith(color: AppColors.textDark)),
        content: SizedBox(
          width: 400,
          child: _buildCurrentStepView(),
        ),
        actions: [
          if (_currentStep < 3) MouseRegion(
            cursor: SystemMouseCursors.click,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Отмена", style: AppStyles.label.copyWith(color: AppColors.textGrey)),
            ),
          ),
          SizedBox(
            width: 120,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: KodixComponents.primaryButton(
                height: 40,
                text: _currentStep == 3 ? "Войти" : "Далее",
                onTap: _isLoading ? () {} : _handleAction,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    if (_currentStep == 0) return "Восстановление";
    if (_currentStep == 1) return "Подтверждение";
    if (_currentStep == 2) return "Новый пароль";
    return "Готово!";
  }

  Widget _buildCurrentStepView() {
    if (_isLoading) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)));
    
    switch (_currentStep) {
      case 0:
        return TextField(
          controller: _emailController,
          style: AppStyles.body.copyWith(color: AppColors.textDark),
          decoration: KodixComponents.textFieldDecoration(hintText: "Email", prefixIcon: Icons.email_outlined).copyWith(errorText: _errorMessage),
        );
      case 1:
        return TextField(
          controller: _codeController,
          textAlign: TextAlign.center,
          maxLength: 6,
          style: AppStyles.h1.copyWith(color: AppColors.textDark, letterSpacing: 10),
          decoration: KodixComponents.textFieldDecoration(hintText: "000000").copyWith(errorText: _errorMessage),
        );
      case 2:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _passwordController, 
              obscureText: true, 
              style: AppStyles.body.copyWith(color: AppColors.textDark),
              decoration: KodixComponents.textFieldDecoration(hintText: "Пароль")
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmController, 
              obscureText: true, 
              style: AppStyles.body.copyWith(color: AppColors.textDark),
              decoration: KodixComponents.textFieldDecoration(hintText: "Повтор").copyWith(errorText: _errorMessage)
            ),
          ],
        );
      default:
        return Text(
          "Пароль успешно изменен. Теперь вы можете войти.",
          style: AppStyles.body.copyWith(color: AppColors.textDark),
        );
    }
  }
}