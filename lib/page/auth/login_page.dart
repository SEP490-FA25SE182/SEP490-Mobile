import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../provider.dart';
import '../../style/button.dart';
import '../../style/input_text.dart';
import '../../widget/gs_image.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authRepoProvider).login(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      context.go('/');
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    const gIcon = 'gs://sep490-fa25se182.firebasestorage.app/icon/google.png';
    const fIcon = 'gs://sep490-fa25se182.firebasestorage.app/icon/facebook.png';
    const viewIcon = 'gs://sep490-fa25se182.firebasestorage.app/icon/view.png';
    const hideIcon = 'gs://sep490-fa25se182.firebasestorage.app/icon/hide.png';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF12345B), Color(0xFF0F2746)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withOpacity(0.06),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        'Mừng bạn quay lại!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Trải nghiệm sách theo cách chưa từng có với\n'
                            'công nghệ AR, tưởng thuật AI và kể chuyện nhập vai.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, height: 1.4),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: ButtonSoft(
                              text: 'Google',
                              leading: SizedBox(
                                width: 18, height: 18,
                                child: GsImage(url: gIcon, fit: BoxFit.contain),
                              ),
                              onTap: () {/* TODO: Google Sign-In */},
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ButtonSoft(
                              text: 'Facebook',
                              leading: SizedBox(
                                width: 18, height: 18,
                                child: GsImage(url: fIcon, fit: BoxFit.contain),
                              ),
                              onTap: () {/* TODO: Facebook Login */},
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),
                      const Center(
                        child: Text('Hoặc tiếp tục với', style: TextStyle(color: Colors.white70)),
                      ),
                      const SizedBox(height: 14),

                      const Text('Địa chỉ Email', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 6),
                      InputFieldBox(
                        child: TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.username, AutofillHints.email],
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'john@example.com',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.white54),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),
                      const Text('Mật khẩu', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 6),
                      InputFieldBox(
                        child: TextField(
                          controller: _password,
                          obscureText: _obscure,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Nhập mật khẩu của bạn',
                            border: InputBorder.none,
                            hintStyle: const TextStyle(color: Colors.white54),
                            suffixIcon: GestureDetector(
                              onTap: () => setState(() => _obscure = !_obscure),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: GsImage(
                                  url: _obscure ? viewIcon : hideIcon,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => context.go('/forgot_password'),
                          child: const Text('Bạn quên mật khẩu của mình?', style: TextStyle(color: Colors.white70)),
                        ),
                      ),

                      const SizedBox(height: 16),
                      if (_error != null) ...[
                        Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                        const SizedBox(height: 12),
                      ],

                      ButtonPrimary(
                        text: _loading ? 'Đang đăng nhập...' : 'Đăng nhập',
                        onTap: _loading
                            ? null
                            : () async {
                          setState(() { _loading = true; _error = null; });
                          try {
                            final u = await ref.read(authRepoProvider).login(
                              email: _email.text.trim(),
                              password: _password.text,
                            );

                            // LƯU userId
                            ref.read(currentUserIdProvider.notifier).state = u.userId;

                            // Điều hướng
                            if (context.mounted) context.go('/profile');
                          } catch (e) {
                            setState(() { _error = e.toString(); });
                          } finally {
                            if (mounted) setState(() { _loading = false; });
                          }
                        },
                        trailing: _loading
                            ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                            : null,
                      ),

                      const SizedBox(height: 16),
                      Center(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text('Không có tài khoản? ', style: TextStyle(color: Colors.white70)),
                            GestureDetector(
                              onTap: () => context.push('/register'),
                              child: const Text(
                                'Vào đây để tạo tài khoản',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
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
      ),
    );
  }
}
