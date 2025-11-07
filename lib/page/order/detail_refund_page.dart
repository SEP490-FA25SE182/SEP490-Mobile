import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../model/order.dart';
import '../../model/transaction.dart';
import '../../provider.dart';
import '../../style/button.dart';
import '../../widget/gs_image.dart';

/// ---------- Helpers ----------
String _fmtVnd(num v) {
  final s = v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  return '$s VND';
}

String _fmtDate(DateTime dt) {
  String two(int x) => x < 10 ? '0$x' : '$x';
  return '${two(dt.day)}-${two(dt.month)}-${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
}

/// Trang chi tiết hoàn tiền
class DetailRefundPage extends ConsumerWidget {
  final String orderId;
  const DetailRefundPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oAsync = ref.watch(orderByIdProvider(orderId));
    final tAsync = ref.watch(transactionRefundByOrderProvider(orderId));

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
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
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
                          onPressed: () => context.pop(),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Chi tiết hoàn tiền',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: Colors.white.withOpacity(0.15)),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      children: [
                        // Progress icons + lines
                        _RefundProgress(tranAsync: tAsync),

                        const SizedBox(height: 18),
                        const Text(
                          'Yêu cầu huỷ đơn hàng/ hoàn tiền của bạn đã được Rookies xử lý. '
                              'Với đơn hàng hoàn tiền sẽ cần thời gian xử lý từ 3 - 14 ngày để ngân hàng cập nhật tiến hoàn. '
                              'Bạn có thể liên hệ ngân hàng để kiểm tra ngày cập nhật cụ thể nhé.',
                          style: TextStyle(color: Colors.white70, height: 1.35),
                        ),

                        const SizedBox(height: 18),

                        // Box Thông tin hoàn tiền
                        oAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          error: (e, _) => Text('Lỗi tải đơn: $e',
                              style: const TextStyle(color: Colors.redAccent)),
                          data: (order) => _RefundInfoBox(order: order, tranAsync: tAsync),
                        ),

                        const SizedBox(height: 20),

                        // Button: Chi tiết đơn hàng
                        ButtonPrimary(
                          text: 'Chi tiết đơn hàng',
                          height: 54,
                          borderRadius: 14,
                          onTap: () => context.push('/orders/detail/$orderId'),
                        ),
                      ],
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

/// Hiển thị tiến trình bằng icon & gạch
class _RefundProgress extends StatelessWidget {
  final AsyncValue<Transaction?> tranAsync;
  const _RefundProgress({required this.tranAsync});

  static const _rookie = 'gs://sep490-fa25se182.firebasestorage.app/icon/rookie.jpg';
  static const _bank   = 'gs://sep490-fa25se182.firebasestorage.app/icon/bank.png';
  static const _card   = 'gs://sep490-fa25se182.firebasestorage.app/icon/credit-card.png';

  // Map status -> số icon hiển thị
  int _iconsCount(int? status) {
    if (status == 3) return 3; // PAID
    if (status == 1) return 2; // PROCESSING
    return 1;                  // NOT_PAID
  }

  @override
  Widget build(BuildContext context) {
    return tranAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Text('Lỗi trạng thái: $e',
          style: const TextStyle(color: Colors.redAccent)),
      data: (tran) {
        final n = _iconsCount(tran?.status);

        Widget dot(String url) => Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0x1FFFFFFF),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24),
          ),
          padding: const EdgeInsets.all(10),
          child: ClipOval(child: GsImage(url: url, fit: BoxFit.cover)),
        );

        Widget line() => Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF29D17F),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (n >= 1) dot(_rookie),
                if (n >= 2) line(),
                if (n >= 2) dot(_bank),
                if (n >= 3) line(),
                if (n >= 3) dot(_card),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: const [
                Expanded(child: Text('Gửi yêu cầu',   textAlign: TextAlign.center, style: TextStyle(color: Colors.white70))),
                Expanded(child: Text('Đang hoàn tiền', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70))),
                Expanded(child: Text('Đã hoàn tiền',   textAlign: TextAlign.center, style: TextStyle(color: Colors.white70))),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Box “Thông tin hoàn tiền”
class _RefundInfoBox extends StatelessWidget {
  final Order order;
  final AsyncValue<Transaction?> tranAsync;
  const _RefundInfoBox({required this.order, required this.tranAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 1),
        color: const Color(0x10FFFFFF),
      ),
      child: tranAsync.when(
        loading: () => const LinearProgressIndicator(minHeight: 2),
        error: (e, _) => Text('Lỗi chi tiết hoàn tiền: $e',
            style: const TextStyle(color: Colors.redAccent)),
        data: (tran) {
          final reason = (order.reason?.trim().isNotEmpty ?? false) ? order.reason! : '-';
          final timeRefund = tran?.updatedAt == null
              ? '-'
              : _fmtDate(tran!.updatedAt!.toLocal());

          Widget row(String k, String v) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                    child: Text(k,
                        style: const TextStyle(
                            color: Colors.white70, fontWeight: FontWeight.w600))),
                const SizedBox(width: 12),
                Text(v,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800)),
              ],
            ),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Thông tin hoàn tiền',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              row('Tổng tiền hoàn', _fmtVnd(order.totalPrice)),
              row('Hoàn tiền vào', 'Ví tiền Rookies'),
              row('Yêu cầu bởi', 'Người mua'),
              row('Lý do', reason),
              row('Thời gian hoàn tiền', timeRefund),
            ],
          );
        },
      ),
    );
  }
}
