import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widget/gs_image.dart';
import '../provider.dart';

/// Trang **dành cho user đã đăng nhập** ở trang hồ sơ.
class UserProfileSection extends ConsumerWidget {
  final VoidCallback? onLogout;
  const UserProfileSection({super.key, this.onLogout});

  static const String _gsIconBase =
      'gs://sep490-fa25se182.firebasestorage.app/icon';

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Đăng xuất')),
        ],
      ),
    );
    if (ok != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Lưu lại userId cũ để invalidate cache đúng key
      final oldId = ref.read(currentUserIdProvider);

      final ttl = await ref.read(authRepoProvider).logout();
      debugPrint('[Logout] server TTL=$ttl');

      // Dọn token & state trong app
      invalidateUserCache(ref, oldId);
      ref.read(currentUserIdProvider.notifier).state = null;

      if (context.mounted) {
        Navigator.of(context).pop();
        context.go('/');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đăng xuất')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đăng xuất thất bại: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _SectionTitle('Đơn mua'),
              SizedBox(height: 12),
              _OrderRow(),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _SectionTitle('Các lựa chọn'),
              SizedBox(height: 6),
              _OptionTile(
                iconUrl: '$_gsIconBase/library.png',
                title: 'Thư viện của bạn',
                routeName: '/library',
              ),
              _OptionTile(
                iconUrl: '$_gsIconBase/wallet.png',
                title: 'Ví tiền của bạn',
                routeName: '/wallet/money',
              ),
              _OptionTile(
                iconUrl: '$_gsIconBase/coin-bag.png',
                title: 'Túi xu của bạn',
                routeName: '/wallet/coin',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          child: ListTile(
            onTap: () => _handleLogout(context, ref),
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow();

  static const String _gsIconBase =
      'gs://sep490-fa25se182.firebasestorage.app/icon';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _OrderAction(
          title: 'Chờ xác nhận',
          iconUrl: '$_gsIconBase/pending.png',
          routeName: '/orders/pending',
        ),
        _OrderAction(
          title: 'Chờ lấy hàng',
          iconUrl: '$_gsIconBase/process.png',
          routeName: '/orders/processing',
        ),
        _OrderAction(
          title: 'Vận chuyển',
          iconUrl: '$_gsIconBase/shipping.png',
          routeName: '/orders/shipping',
        ),
        _OrderAction(
          title: 'Hoàn thành',
          iconUrl: '$_gsIconBase/done.png',
          routeName: '/orders/delivered',
        ),
      ],
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x1FFFFFFF), Color(0x10FFFFFF)],
        ),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800));
  }
}

class _OrderAction extends StatelessWidget {
  final String iconUrl;
  final String title;
  final String? routeName;

  const _OrderAction({
    required this.iconUrl,
    required this.title,
    this.routeName,
  });

  void _handleTap(BuildContext context) {
    final route = routeName;
    if (route == null || route.isEmpty) return;

    final go = GoRouter.maybeOf(context);
    if (go != null) {
      go.go(route);
    } else {
      Navigator.of(context).pushNamed(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _handleTap(context),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0x203F5BFF),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: GsImage(url: iconUrl, fit: BoxFit.contain),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String iconUrl; // gs://
  final String title;
  final String routeName;
  const _OptionTile({
    required this.iconUrl,
    required this.title,
    required this.routeName,
  });
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SizedBox(
        width: 28,
        height: 28,
        child: GsImage(url: iconUrl, fit: BoxFit.contain),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      onTap: () {
        final go = GoRouter.maybeOf(context);
        if (go != null) {
          go.go(routeName);
        } else {
          Navigator.of(context).pushNamed(routeName);
        }
      },
    );
  }
}
