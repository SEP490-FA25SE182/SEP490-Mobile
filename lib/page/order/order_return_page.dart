import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../provider.dart';
import '../../model/order.dart';
import '../../screen/nav_order_screen.dart';
import '../../screen/order_status_screen.dart';

class OrderReturnPage extends ConsumerWidget {
  const OrderReturnPage({super.key});

  Future<List<Order>> _fetch(WidgetRef ref, String userId) {
    return ref.read(orderRepoProvider).search(userId: userId, status: 'RETURNED');
  }

  void _goTab(BuildContext ctx, OrderTab t) {
    switch (t) {
      case OrderTab.pending:    ctx.go('/orders/pending');    break;
      case OrderTab.processing: ctx.go('/orders/processing'); break;
      case OrderTab.shipping:   ctx.go('/orders/shipping');   break;
      case OrderTab.delivered:  ctx.go('/orders/delivered');  break;
      case OrderTab.cancelled:  ctx.go('/orders/cancel');  break;
      case OrderTab.returned:   break;
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
                  // Header
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
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: Colors.white.withOpacity(0.15)),

                  // Tabs
                  NavOrderScreen(
                    current: OrderTab.returned,
                    onChanged: (t) => _goTab(context, t),
                  ),

                  // Content
                  Expanded(
                    child: (uid == null || uid.isEmpty)
                        ? const Center(child: Text('Bạn chưa đăng nhập', style: TextStyle(color: Colors.white70)))
                        : FutureBuilder<List<Order>>(
                      future: _fetch(ref, uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Lỗi tải đơn: ${snapshot.error}',
                                style: const TextStyle(color: Colors.redAccent)),
                          );
                        }
                        final orders = snapshot.data ?? <Order>[];
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: OrderList(
                            orders: orders,
                            actionLabel: null,
                            onAction: (o) => context.push('/orders/detail/${o.orderId}'),
                            onSeeMore: (o) => context.push('/orders/refund/${o.orderId}'),
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
