import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widget/gs_image.dart';
import '../model/user.dart' as model;
import '../screen/nav_bottom_screen.dart';
import '../screen/user_profile_screen.dart';
import '../screen/guest_profile_screen.dart';
import '../style/button.dart';

class ProfilePage extends StatelessWidget {
  final model.User? user;
  final String? roleName;
  final VoidCallback? onEditAccount;
  final VoidCallback? onLoginOrSignUp;
  final VoidCallback? onLogout;

  const ProfilePage({
    super.key,
    this.user,
    this.roleName,
    this.onEditAccount,
    this.onLoginOrSignUp,
    this.onLogout,
  });

  bool get _loggedIn => user != null;

  @override
  Widget build(BuildContext context) {
    const _avatarSample =
        'gs://sep490-fa25se182.firebasestorage.app/avatar/sample_avatar.png';

    final avatarUrl = (user?.avatarUrl != null && user!.avatarUrl!.trim().isNotEmpty)
        ? user!.avatarUrl!
        : _avatarSample;
    final fullName = user?.fullName ?? 'Guest';
    final email = user?.email ?? 'Bạn chưa đăng nhập';
    final role = (roleName?.isNotEmpty ?? false)
        ? roleName!
        : (_loggedIn ? 'Thành viên' : 'Khách');

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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            children: [
              // --------- Header tài khoản ----------
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    const Text(
                      'Tài khoản',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(60),
                          child: SizedBox(
                            width: 72, height: 72,
                            child: GsImage(url: avatarUrl, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      fullName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF5B6CF3),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      role,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: ButtonPrimary(
                        text: _loggedIn
                            ? 'Chỉnh sửa tài khoản'
                            : 'Login / Sign up',
                        // Điều hướng theo trạng thái đăng nhập
                        onTap: () {
                          if (_loggedIn) {
                            // Ưu tiên callback nếu được truyền vào
                            if (onEditAccount != null) {
                              onEditAccount!();
                            } else {
                              // Route chỉnh sửa tài khoản
                              context.push('/account/edit');
                            }
                          } else {
                            if (onLoginOrSignUp != null) {
                              onLoginOrSignUp!();
                            } else {
                              // Route đăng nhập
                              context.push('/login');
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // --------- Phần nội dung động ----------
              if (_loggedIn)
                UserProfileSection(onLogout: onLogout)
              else
                const GuestProfileSection(),
            ],
          ),
        ),
      ),

      bottomNavigationBar: const NavBottomBar(currentIndex: 4),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0x1FFFFFFF), Color(0x10FFFFFF)],
        ),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: child,
    );
  }
}
