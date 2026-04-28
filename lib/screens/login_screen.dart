import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hide = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await context.read<AppState>().login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid email or password')),
      );
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailCtrl = TextEditingController(text: _emailController.text.trim());
    final otpCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    bool hideNewPassword = true;
    bool hideConfirmPassword = true;
    bool otpSent = false;
    bool otpVerified = false;
    bool isSubmitting = false;
    String? resetSessionId;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reset Password'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: emailCtrl,
                      enabled: !otpSent,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Registered Email',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (otpSent && !otpVerified) ...[
                      TextField(
                        controller: otpCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: '6-digit OTP',
                          prefixIcon: Icon(Icons.password_outlined),
                        ),
                      ),
                    ],
                    if (otpVerified) ...[
                      TextField(
                        controller: newPasswordCtrl,
                        obscureText: hideNewPassword,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setDialogState(() => hideNewPassword = !hideNewPassword),
                            icon: Icon(hideNewPassword ? Icons.visibility : Icons.visibility_off),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: confirmPasswordCtrl,
                        obscureText: hideConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          prefixIcon: const Icon(Icons.lock_reset),
                          suffixIcon: IconButton(
                            onPressed: () => setDialogState(
                              () => hideConfirmPassword = !hideConfirmPassword,
                            ),
                            icon: Icon(
                              hideConfirmPassword ? Icons.visibility : Icons.visibility_off,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                    final email = emailCtrl.text.trim();
                    if (email.isEmpty) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('Please enter registered email.')),
                      );
                      return;
                    }

                    setDialogState(() => isSubmitting = true);

                    String message;
                    if (!otpSent) {
                      final result = await this.context.read<AppState>().requestPasswordResetOtp(
                            email: email,
                          );
                      message = result['message'] as String? ?? 'Unable to send OTP.';
                      if (result['success'] == true && mounted) {
                        setDialogState(() {
                          otpSent = true;
                          resetSessionId = result['sessionId'] as String?;
                        });
                      }
                    } else if (!otpVerified) {
                      message = await this.context.read<AppState>().verifyPasswordResetOtp(
                            email: email,
                            sessionId: resetSessionId ?? '',
                            otp: otpCtrl.text.trim(),
                          );
                      if (message.toLowerCase().contains('verified') && mounted) {
                        setDialogState(() => otpVerified = true);
                      }
                    } else {
                      final newPassword = newPasswordCtrl.text.trim();
                      final confirmPassword = confirmPasswordCtrl.text.trim();

                      if (newPassword.isEmpty || confirmPassword.isEmpty) {
                        setDialogState(() => isSubmitting = false);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(content: Text('Please fill all fields.')),
                        );
                        return;
                      }

                      message = await this.context.read<AppState>().resetPassword(
                            email: email,
                            sessionId: resetSessionId ?? '',
                            newPassword: newPassword,
                            confirmPassword: confirmPassword,
                          );
                    }

                    if (!mounted || !dialogContext.mounted) return;
                    setDialogState(() => isSubmitting = false);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                    if (message.toLowerCase().contains('successful') && otpVerified) {
                      _emailController.text = email;
                      _passwordController.clear();
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: Text(
                    !otpSent
                        ? 'Send OTP'
                        : !otpVerified
                        ? 'Verify OTP'
                        : 'Reset',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    emailCtrl.dispose();
    otpCtrl.dispose();
    newPasswordCtrl.dispose();
    confirmPasswordCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5B5CE2), Color(0xFF7A5CF0), Color(0xFF66C8FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 460),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 58,
                        width: 58,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF5B5CE2), Color(0xFF7A5CF0)],
                          ),
                        ),
                        child: const Icon(Icons.health_and_safety, color: Colors.white, size: 30),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Health Management System',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Secure login to access your dashboard',
                        style: TextStyle(color: Colors.blueGrey.shade600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 22),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.mail_outline, color: theme.colorScheme.primary),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty
                            ? 'Enter email'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _hide,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _hide = !_hide),
                            icon: Icon(
                              _hide ? Icons.visibility : Icons.visibility_off,
                            ),
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.length < 6 ? 'Minimum 6 characters' : null,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _submit(),
                        icon: const Icon(Icons.login),
                        label: const Text('Login'),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPasswordDialog,
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SignupScreen()),
                          );
                        },
                        child: const Text('Create New Account'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
