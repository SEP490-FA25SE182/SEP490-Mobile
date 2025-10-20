import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../widget/gs_image.dart';
import '../../style/button.dart';
import '../../style/input_text.dart';
import '../../provider.dart';


class RegisterPage extends ConsumerStatefulWidget  {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _showPwd = false;
  bool _asAuthor = false;
  bool _loading = false;

  static const _gsIconBase = 'gs://sep490-fa25se182.firebasestorage.app/icon';
  final _viewIcon = '$_gsIconBase/view.png';
  final _hideIcon = '$_gsIconBase/hide.png';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _doRegister() async {
    setState(() => _loading = true);
    try {
      // 1) chọn roleName theo checkbox
      final desiredRoleName = _asAuthor ? 'Author' : 'Customer';

      // 2) tra roleId ACTIVE theo roleName
      final roleRepo = ref.read(roleRepoProvider);
      final roleId = await roleRepo.getActiveRoleIdByName(desiredRoleName);

      debugPrint('Register as $desiredRoleName, roleId=$roleId');

      // 3) gọi API register, truyền roleId (null => server gán default Customer)
      await ref.read(authRepoProvider).register(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        password: _passwordCtrl.text,
        roleId: roleId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng ký thành công! Vui lòng đăng nhập.')),
      );
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
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
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: const Color(0x14000000),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Text(
                      'Rất vui vì gặp bạn!',
                      style: TextStyle(
                        fontSize: 28, height: 1.2,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Social buttons
                    Row(
                      children: [
                        Expanded(
                          child: ButtonSoft(
                            leading: SizedBox(
                              width: 20, height: 20,
                              child: GsImage(url: '$_gsIconBase/google.png', fit: BoxFit.contain),
                            ),
                            text: 'Google',
                            onTap: _loading ? null : () {/* TODO: Google sign-in */},
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ButtonSoft(
                            leading: SizedBox(
                              width: 20, height: 20,
                              child: GsImage(url: '$_gsIconBase/facebook.png', fit: BoxFit.contain),
                            ),
                            text: 'Facebook',
                            onTap: _loading ? null : () {/* TODO: Facebook sign-in */},
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),
                    const Center(
                      child: Text('Hoặc tiếp tục với',
                          style: TextStyle(color: Colors.white70)),
                    ),
                    const SizedBox(height: 14),

                    // Name
                    const Text('Tên của bạn',
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 6),
                    InputFieldBox(
                      child: TextField(
                        controller: _nameCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'Tên của bạn', border: InputBorder.none,
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Email
                    const Text('Địa chỉ Mail',
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 6),
                    InputFieldBox(
                      child: TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'john@example.com', border: InputBorder.none,
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Phone
                    const Text('Cho xin cái số phone',
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 6),
                    InputFieldBox(
                      child: TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'Số điện thoại của bạn', border: InputBorder.none,
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Password
                    const Text('Nhập mật khẩu dô',
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 6),
                    InputFieldBox(
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _passwordCtrl,
                              obscureText: !_showPwd,
                              decoration: const InputDecoration(
                                hintText: 'Nhập mật khẩu của bạn',
                                border: InputBorder.none,
                              ),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _showPwd = !_showPwd),
                            child: SizedBox(
                              width: 26, height: 26,
                              child: GsImage(
                                url: _showPwd ? _hideIcon : _viewIcon,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Checkbox author
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Bạn muốn thử làm người vẽ truyện không?',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        Checkbox(
                          value: _asAuthor,
                          onChanged: (v) => setState(() => _asAuthor = v ?? false),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),


                    // Submit
                    ButtonPrimary(
                      text: _loading ? 'Đang đăng ký...' : 'Đăng ký',
                      onTap: _loading ? null : _doRegister,
                    ),

                    const SizedBox(height: 18),

                    // Back to login
                    Center(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text('Bạn đã có tài khoản?',
                              style: TextStyle(color: Colors.white70)),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => context.go('/login'),
                            child: const Text(
                              'Vậy quay lại đăng nhập đi!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ),
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
    );
  }
}
