import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Bọc child và CHỈ render khi đã có user Firebase (kể cả anonymous).
/// Nếu chưa có, lắng nghe authState và render ngay khi user đăng nhập.
/// => Tác dụng như "retry 1 lần" khi ảnh được gọi sớm hơn quá trình sign-in.
class AuthReady extends StatelessWidget {
  final Widget child;
  final Widget? placeholder; // skeleton tạm thời (optional)
  const AuthReady({super.key, required this.child, this.placeholder});

  @override
  Widget build(BuildContext context) {
    final current = FirebaseAuth.instance.currentUser;
    if (current != null) return child;

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.data != null) return child;             // user đã có -> render
        return placeholder ?? const SizedBox.shrink();    // chờ (retry 1 lần)
      },
    );
  }
}
