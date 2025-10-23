import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../style/button.dart';
import '../../style/input_text.dart';
import '../../provider.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _errorText;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  bool _isValidEmail(String v) {
    final s = v.trim().toLowerCase();
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(s);
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();

    // validate local
    if (!_isValidEmail(email)) {
      setState(() => _errorText = 'Vui lòng nhập email hợp lệ');
      return;
    }
    setState(() {
      _errorText = null;
      _loading = true;
    });

    try {
      await ref.read(authRepoProvider).forgotPassword(email);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nếu email tồn tại, chúng tôi đã gửi hướng dẫn đặt lại mật khẩu.')),
      );
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0E2A47), Color(0xFF09121F)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Container(
                width: 520,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: const Color(0x14000000),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tiêu đề
                    const Text(
                      'Bạn quên\nmật khẩu?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Nhập email được kết nối với tài khoản của bạn để nhận mail tạo lại mật khẩu',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 22),

                    // Label
                    const Text('Email của bạn',
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 6),

                    // Input
                    InputFieldBox(
                      child: TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          hintText: 'you@example.com',
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),

                    if (_errorText != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorText!,
                        style: TextStyle(color: Colors.red.shade300),
                      ),
                    ],

                    const SizedBox(height: 18),

                    // Nút gửi
                    ButtonPrimary(
                      text: _loading ? 'Đang xử lý...' : 'Tạo lại mật khẩu',
                      onTap: _loading ? null : _submit,
                      trailing: _loading
                          ? const SizedBox(
                        height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
