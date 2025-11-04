import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../provider.dart';
import '../../model/order.dart';
import '../../screen/nav_order_screen.dart';
import '../../screen/order_status_screen.dart';

class OrderShippingPage extends ConsumerWidget {
  const OrderShippingPage({super.key});

  Future<List<Order>> _fetch(WidgetRef ref, String userId) {
    return ref.read(orderRepoProvider).search(userId: userId, status: 'SHIPPING');
  }

  void _goTab(BuildContext ctx, OrderTab t) {
    switch (t) {
      case OrderTab.pending:    ctx.go('/orders/pending');    break;
      case OrderTab.processing: ctx.go('/orders/processing'); break;
      case OrderTab.shipping:   break;
      case OrderTab.delivered:  ctx.go('/orders/delivered');  break;
      case OrderTab.cancelled:  ctx.go('/orders/cancel');  break;
      case OrderTab.returned:   ctx.go('/orders/return');   break;
    }
  }

  Future<void> _markDelivered(BuildContext ctx, WidgetRef ref, Order o) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận đã nhận hàng'),
        content: const Text('Bạn đã nhận được đơn hàng này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Chưa')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Đã nhận')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ref.read(orderRepoProvider).update(o.orderId, status: 4);
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Cập nhật: Đơn đã giao thành công')),
        );
        ctx.go('/orders/delivered');
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Cập nhật thất bại: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserIdProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF1B3B68), Color(0xFF0F1B2E), Color(0xFF123C6B)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 8, 8, 6),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => context.go('/profile'),
                        ),
                        const SizedBox(width: 6),
                        const Text('Đơn đã mua',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  Container(height: 1, color: Colors.white.withOpacity(0.15)),

                  // tabs: cố định current, đổi tab thì điều hướng
                  NavOrderScreen(
                    current: OrderTab.shipping,
                    onChanged: (t) => _goTab(context, t),
                  ),

                  Expanded(
                    child: (uid == null || uid.isEmpty)
                        ? const Center(child: Text('Bạn chưa đăng nhập', style: TextStyle(color: Colors.white70)))
                        : FutureBuilder<List<Order>>(
                      future: _fetch(ref, uid),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snap.hasError) {
                          return Center(child: Text('Lỗi tải đơn: ${snap.error}',
                              style: const TextStyle(color: Colors.redAccent)));
                        }
                        final orders = snap.data ?? <Order>[];
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: OrderList(
                            orders: orders,
                            actionLabel: 'Đã nhận được hàng',
                            onAction: (o) => _markDelivered(context, ref, o),
                            onSeeMore: (o) => context.push('/orders/detail/${o.orderId}'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
