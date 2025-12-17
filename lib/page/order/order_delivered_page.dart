import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../provider.dart';
import '../../model/order.dart';
import '../../widget/gs_image.dart';
import '../../screen/nav_order_screen.dart';

class OrderDeliveredPage extends ConsumerWidget {
  const OrderDeliveredPage({super.key});

  Future<List<Order>> _fetch(WidgetRef ref, String userId) {
    return ref.read(orderRepoProvider).search(userId: userId, status: 'DELIVERED');
  }

  void _goTab(BuildContext ctx, OrderTab t) {
    switch (t) {
      case OrderTab.pending:    ctx.go('/orders/pending');    break;
      case OrderTab.processing: ctx.go('/orders/processing'); break;
      case OrderTab.shipping:   ctx.go('/orders/shipping');   break;
      case OrderTab.delivered:  break;
      case OrderTab.received:   ctx.go('/orders/received');   break;
      case OrderTab.cancelled:  ctx.go('/orders/cancel');     break;
      case OrderTab.returned:   ctx.go('/orders/return');     break;
    }
  }

  Future<void> _markReceived(BuildContext ctx, WidgetRef ref, Order o) async {
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
      // RECEIVED = 5
      await ref.read(orderRepoProvider).update(o.orderId, status: 5);
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Cập nhật: Đơn đã nhận thành công')),
        );
        ctx.go('/orders/received');
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Cập nhật thất bại: $e')),
        );
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
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  Container(height: 1, color: Colors.white.withOpacity(0.15)),

                  NavOrderScreen(
                    current: OrderTab.delivered,
                    onChanged: (t) => _goTab(context, t),
                  ),

                  // Content
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
                          return Center(
                            child: Text('Lỗi tải đơn: ${snap.error}',
                                style: const TextStyle(color: Colors.redAccent)),
                          );
                        }
                        final orders = snap.data ?? <Order>[];

                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Column(
                            children: [
                              if (orders.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(18),
                                  child: Text('Không có đơn nào',
                                      style: TextStyle(color: Colors.white70)),
                                ),
                              ...orders.map(
                                    (o) => _DeliveredOrderCard(
                                  order: o,
                                  onMarkReceived: () => _markReceived(context, ref, o),
                                ),
                              ),
                            ],
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

/// ===== Helpers =====
String _fmtVnd(num v) {
  final s = v.toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  return '$s VND';
}

/// Card dùng cho trang DELIVERED – nút: "Đã nhận được hàng"
class _DeliveredOrderCard extends ConsumerWidget {
  final Order order;
  final VoidCallback onMarkReceived;

  const _DeliveredOrderCard({
    required this.order,
    required this.onMarkReceived,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(orderDetailsByOrderProvider(order.orderId));

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              gradient: const LinearGradient(
                begin: Alignment.centerLeft, end: Alignment.centerRight,
                colors: [Color(0x332E3350), Color(0x00123456)],
              ),
              border: const Border(bottom: BorderSide(color: Colors.white24, width: 1)),
            ),
            child: Text(
              'Đơn hàng: ${order.orderId.length > 8 ? order.orderId.substring(0, 8) + '…' : order.orderId}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: detailsAsync.when(
              loading: () => const SizedBox(
                height: 72,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              ),
              error: (e, _) => Text('Lỗi chi tiết: $e', style: const TextStyle(color: Colors.redAccent)),
              data: (details) {
                if (details.isEmpty) {
                  return const Text('(Không có sản phẩm)', style: TextStyle(color: Colors.white70));
                }
                final d0 = details.first;
                final bAsync = ref.watch(bookByIdProvider(d0.bookId));

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 54, height: 70,
                        child: bAsync.when(
                          data: (b) => (b.coverUrl != null && b.coverUrl!.isNotEmpty)
                              ? GsImage(url: b.coverUrl!, fit: BoxFit.cover)
                              : Container(color: const Color(0x225B6CF3)),
                          loading: () => Container(color: const Color(0x1FFFFFFF)),
                          error: (_, __) => Container(color: const Color(0x225B6CF3)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: bAsync.when(
                        data: (b) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.bookName ?? '(Không rõ tên sách)',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text('x${d0.quantity}', style: const TextStyle(color: Colors.white54)),
                            const SizedBox(height: 6),
                            Text(
                              _fmtVnd(d0.price),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        loading: () => const SizedBox(height: 20),
                        error: (_, __) =>
                        const Text('(Lỗi tên sách)', style: TextStyle(color: Colors.white70)),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: () => context.push('/orders/detail/${order.orderId}'),
                        child: const Text('Xem thêm >>', style: TextStyle(color: Colors.white70)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Tổng: ', style: TextStyle(color: Colors.white70)),
                          Text(
                            _fmtVnd(order.totalPrice),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton.tonal(
                      onPressed: onMarkReceived,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Đã nhận được hàng'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
