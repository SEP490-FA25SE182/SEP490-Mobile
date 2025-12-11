import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../provider.dart';
import '../../model/order.dart';
import '../../screen/nav_order_screen.dart';
import '../../screen/order_status_screen.dart';

class OrderPendingPage extends ConsumerStatefulWidget {
  const OrderPendingPage({super.key});

  @override
  ConsumerState<OrderPendingPage> createState() => _OrderPendingPageState();
}

class _OrderPendingPageState extends ConsumerState<OrderPendingPage> {
  OrderTab _tab = OrderTab.pending;

  Future<List<Order>> _fetchOrders(WidgetRef ref, String userId, OrderTab tab) async {
    // Map tab
    String? status;
    switch (tab) {
      case OrderTab.pending:   status = 'PENDING';   break;
      case OrderTab.processing:status = 'PROCESSING';break;
      case OrderTab.shipping:  status = 'SHIPPING';  break;
      case OrderTab.delivered: status = 'DELIVERED'; break;
      case OrderTab.received: status = 'RECEIVED'; break;
      case OrderTab.cancelled: status = 'CANCELLED'; break;
      case OrderTab.returned:  status = 'RETURNED';  break;
    }
    return ref.read(orderRepoProvider).search(userId: userId, status: status);
  }

  Future<void> _cancelOrder(Order o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Huỷ đơn hàng'),
        content: const Text('Bạn chắc chắn muốn huỷ đơn này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Không')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Huỷ')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ref.read(orderRepoProvider).update(o.orderId, status: 5);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã huỷ đơn hàng')),
        );
      }
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Huỷ thất bại: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        const Text(
                          'Đơn đã mua',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: Colors.white.withOpacity(0.15)),

                  // Tabs
                  NavOrderScreen(
                    current: OrderTab.pending,
                    onChanged: (t) {
                      switch (t) {
                        case OrderTab.pending:    break;
                        case OrderTab.processing: context.go('/orders/processing'); break;
                        case OrderTab.shipping:   context.go('/orders/shipping');   break;
                        case OrderTab.delivered:  context.go('/orders/delivered');  break;
                        case OrderTab.received:  context.go('/orders/received');  break;
                        case OrderTab.cancelled:  context.go('/orders/cancel');  break;
                        case OrderTab.returned:   context.go('/orders/return');   break;
                      }
                    },
                  ),

                  // Content
                  Expanded(
                    child: uid == null || uid.isEmpty
                        ? const Center(child: Text('Bạn chưa đăng nhập', style: TextStyle(color: Colors.white70)))
                        : FutureBuilder<List<Order>>(
                      future: _fetchOrders(ref, uid, _tab),
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
                            actionLabel: 'Hủy đơn hàng',
                            onAction: (o) => _cancelOrder(o),
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
