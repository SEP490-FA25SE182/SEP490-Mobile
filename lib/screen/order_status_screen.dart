import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/order.dart';
import '../../model/order_detail.dart';
import '../../widget/gs_image.dart';
import '../../provider.dart';

/// ===== Helpers =====
String _fmtVnd(num v) {
  final s = v.toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  return '$s VND';
}

/// ====== OrderList  ======
class OrderList extends StatelessWidget {
  final List<Order> orders;
  final String actionLabel;
  final void Function(Order order) onAction;
  final void Function(Order order)? onSeeMore;

  const OrderList({
    super.key,
    required this.orders,
    required this.actionLabel,
    required this.onAction,
    this.onSeeMore,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(18),
        child: Center(
          child: Text('Không có đơn nào', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    return ListView.separated(
      itemCount: orders.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => OrderCard(
        order: orders[i],
        actionLabel: actionLabel,
        onAction: () => onAction(orders[i]),
        onSeeMore: onSeeMore == null ? null : () => onSeeMore!(orders[i]),
      ),
    );
  }
}

/// ====== OrderCard ======
class OrderCard extends ConsumerWidget {
  final Order order;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback? onSeeMore;

  const OrderCard({
    super.key,
    required this.order,
    required this.actionLabel,
    required this.onAction,
    this.onSeeMore,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(orderDetailsByOrderProvider(order.orderId));

    return Container(
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        children: [
          // Header: mã đơn
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0x332E3350), Color(0x00123456)],
              ),
              border: Border(
                bottom: BorderSide(color: Colors.white24, width: 1),
              ),
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
                final OrderDetail d0 = details.first;
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
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text('x${d0.quantity}', style: const TextStyle(color: Colors.white54)),
                            const SizedBox(height: 6),
                            Text(_fmtVnd(d0.price),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
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
          // Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (order.orderDetails.length > 1 || onSeeMore != null)
                  Center(
                    child: InkWell(
                      onTap: onSeeMore,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          'Xem thêm >>',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text('Tổng:', style: TextStyle(color: Colors.white70)),
                    const SizedBox(width: 6),
                    Text(
                      _fmtVnd(order.totalPrice),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(actionLabel),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
