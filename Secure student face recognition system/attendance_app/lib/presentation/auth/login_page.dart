import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  bool _isRegistering = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _displayNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }

    setState(() { _loading = true; _error = null; });

    final auth = ref.read(authRepoProvider);

    if (_isRegistering) {
      final displayName = _displayNameCtrl.text.trim();
      if (displayName.isEmpty) {
        setState(() { _loading = false; _error = 'Enter your display name'; });
        return;
      }
      final ok = await auth.register(
        username: username, password: password, displayName: displayName);
      if (!ok) {
        setState(() { _loading = false; _error = 'Username already exists'; });
        return;
      }
    }

    final teacher = await auth.login(username: username, password: password);
    if (teacher == null) {
      setState(() { _loading = false; _error = 'Invalid credentials'; });
      return;
    }

    ref.read(isLoggedInProvider.notifier).state = true;
    ref.read(currentTeacherProvider.notifier).state =
        teacher['display_name'] as String?;

    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.face_retouching_natural,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(height: 20),
                Text('FaceAttend',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                const SizedBox(height: 6),
                Text(
                  _isRegistering ? 'Create your account' : 'Sign in to continue',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),

                if (_isRegistering) ...[
                  TextField(
                    controller: _displayNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                TextField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                  onSubmitted: (_) => _submit(),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ],

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_isRegistering ? 'Create Account' : 'Sign In'),
                  ),
                ),

                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() {
                    _isRegistering = !_isRegistering;
                    _error = null;
                  }),
                  child: Text(
                    _isRegistering
                        ? 'Already have an account? Sign in'
                        : 'First time? Create an account',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
