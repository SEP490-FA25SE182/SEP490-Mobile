import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/order_detail.dart';
import '../../provider.dart';
import '../../widget/gs_image.dart';

/// ---- Helper ----
String _fmtVnd(num v) {
  final s = v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  return '$s VND';
}

/// Section hiển thị danh sách OrderDetail của 1 đơn
class OrderDetailSection extends ConsumerWidget {
  final String orderId;
  const OrderDetailSection({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (orderId.isEmpty) {
      return const SizedBox.shrink();
    }

    final detailsAsync = ref.watch(orderDetailsByOrderProvider(orderId));

    return detailsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Lỗi tải chi tiết đơn: $e',
          style: const TextStyle(color: Colors.redAccent),
        ),
      ),
      data: (list) => Column(
        children: [
          ...list.map((d) => _OrderItemRow(detail: d)),
          const SizedBox(height: 8),
          Container(height: 1, color: Colors.white24),
        ],
      ),
    );
  }
}

/// 1 dòng sản phẩm trong đơn
class _OrderItemRow extends ConsumerWidget {
  final OrderDetail detail;
  const _OrderItemRow({required this.detail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bAsync = ref.watch(bookByIdProvider(detail.bookId));
    final priceStr = _fmtVnd(detail.price);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 54,
              height: 70,
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
                  Text('x${detail.quantity}', style: const TextStyle(color: Colors.white54)),
                  const SizedBox(height: 6),
                  Text(priceStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ],
              ),
              loading: () => const SizedBox(height: 20),
              error: (_, __) =>
              const Text('(Lỗi tên sách)', style: TextStyle(color: Colors.white70)),
            ),
          ),
        ],
      ),
    );
  }
}
