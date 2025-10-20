import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widget/gs_image.dart';
import '../provider.dart';

class NavBottomBar extends ConsumerWidget {
  final int currentIndex;
  const NavBottomBar({super.key, required this.currentIndex});

  static const String _iconBase =
      'gs://sep490-fa25se182.firebasestorage.app/icon';

  static final List<({String label, String icon, String route})> _items = [
    (label: 'Trang chủ', icon: '$_iconBase/home.png',    route: '/'),
    (label: 'Blogs',     icon: '$_iconBase/blog.png',    route: '/blogs'),
    (label: 'Thư viện',  icon: '$_iconBase/library.png', route: '/library'),
    (label: 'Giỏ hàng',  icon: '$_iconBase/cart.png',    route: '/cart'),
    (label: 'Tài khoản', icon: '$_iconBase/account.png', route: '/profile'),
  ];

  void _navigate(BuildContext context, WidgetRef ref, int i) {
    final dest = _items[i].route;

    // Đang ở đúng route thì bỏ qua
    final go = GoRouter.maybeOf(context);
    if (go != null && go.routeInformationProvider.value.location == dest) {
      return;
    }

    // Nếu đi tới profile thì đính kèm userId hiện có
    if (go != null) {
      if (dest == '/profile') {
        final uid = ref.read(currentUserIdProvider);
        go.go(dest, extra: uid ?? '');
      } else {
        go.go(dest);
      }
      return;
    }

    // Fallback Navigator
    final nav = Navigator.maybeOf(context);
    if (nav != null) {
      if (ModalRoute.of(context)?.settings.name == dest) return;
      nav.pushNamedAndRemoveUntil(dest, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5B6CF3), Color(0xFF8B6CF3)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final selected = i == currentIndex;
              final color = selected ? Colors.white : Colors.white70;
              final item = _items[i];

              return GestureDetector(
                onTap: () => _navigate(context, ref, i),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 72,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 22, height: 22,
                        child: GsImage(url: item.icon, fit: BoxFit.contain),
                      ),
                      const SizedBox(height: 4),
                      Text(item.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: color, fontSize: 12)),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
