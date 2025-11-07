import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../model/order.dart';
import '../../model/order_detail.dart';
import '../../model/user_address.dart';
import '../../provider.dart';
import '../../screen/order_detail_screen.dart';

/// ---------- Helpers ----------
String _fmtVnd(num v) {
  final s = v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  return '$s VND';
}

String _fmtDate(DateTime dt) {
  String two(int x) => x < 10 ? '0$x' : '$x';
  return '${two(dt.hour)}:${two(dt.minute)}, ${two(dt.day)}/${two(dt.month)}/${dt.year}';
}

/// ---------- Page ----------
class OrderDetailPage extends ConsumerWidget {
  final String orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oAsync = ref.watch(orderByIdProvider(orderId));
    final dAsync = ref.watch(orderDetailsByOrderProvider(orderId));

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
                          'Chi tiết đơn hàng',
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
                    child: oAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Lỗi tải đơn: $e',
                            style: const TextStyle(color: Colors.redAccent)),
                      ),
                      data: (order) {
                        // provider để lấy địa chỉ theo userAddressId
                        final addrAsync = (order.userAddressId == null)
                            ? const AsyncValue<UserAddress?>.data(null)
                            : ref.watch(addressByIdProvider(order.userAddressId!));

                        return ListView(
                          padding: const EdgeInsets.all(12),
                          children: [
                            // ========== Mã đơn ==========
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white24, width: 1),
                                color: const Color(0x10FFFFFF),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Đơn hàng',
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  SelectableText(
                                    order.orderId,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ========== Địa chỉ nhận hàng ==========
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white24, width: 1),
                                color: const Color(0x10FFFFFF),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Địa chỉ nhận hàng',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        addrAsync.when(
                                          loading: () => const LinearProgressIndicator(minHeight: 2),
                                          error: (e, _) => Text(
                                            'Lỗi địa chỉ: $e',
                                            style: const TextStyle(color: Colors.redAccent),
                                          ),
                                          data: (addr) {
                                            if (addr == null) {
                                              return const Text(
                                                '(Chưa có địa chỉ cho đơn này)',
                                                style: TextStyle(color: Colors.white70),
                                              );
                                            }
                                            final phone = (addr.phoneNumber ?? '').trim();
                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${addr.fullName}${phone.isNotEmpty ? ' (${addr.phoneNumber})' : ''}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  addr.addressInfor,
                                                  style: const TextStyle(color: Colors.white70),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ========== Sản phẩm + thời điểm ==========
                            Container(
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white24, width: 1),
                                color: const Color(0x10FFFFFF),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (order.createdAt != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Text(
                                        'Đặt lúc: ${_fmtDate(order.createdAt!.toLocal())}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  OrderDetailSection(orderId: order.orderId),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ========== Thông tin thanh toán ==========
                            _PaymentSummary(
                              order: order,
                              detailsAsync: dAsync,
                            ),

                            const SizedBox(height: 16),
                            // ========== Phương thức thanh toán ==========
                            _PaymentMethodBox(order: order),
                          ],
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

/// Box “Thông tin thanh toán”
class _PaymentSummary extends ConsumerWidget {
  final Order order;
  final AsyncValue<List<OrderDetail>> detailsAsync;
  const _PaymentSummary({required this.order, required this.detailsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24, width: 1),
        color: const Color(0x10FFFFFF),
      ),
      child: detailsAsync.when(
        loading: () => const LinearProgressIndicator(minHeight: 2),
        error: (e, _) => Text('Lỗi chi tiết: $e', style: const TextStyle(color: Colors.redAccent)),
        data: (list) {
          final subtotal = list.fold<num>(0, (sum, d) => sum + d.quantity * d.price);
          final save = subtotal - order.totalPrice;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Thông tin thanh toán',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              _RowKV(left: 'Tiền hàng', right: _fmtVnd(subtotal)),
              if (save > 0.0001) _RowKV(left: 'Tiết kiệm', right: _fmtVnd(save)),
              const SizedBox(height: 10),
              const Divider(color: Colors.white24, height: 16),
              _RowKV(
                left: 'Tổng thanh toán',
                right: _fmtVnd(order.totalPrice),
                bold: true,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RowKV extends StatelessWidget {
  final String left;
  final String right;
  final bool bold;
  const _RowKV({required this.left, required this.right, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(left, style: TextStyle(color: Colors.white70, fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
        const Spacer(),
        Text(right, style: TextStyle(color: Colors.white, fontWeight: bold ? FontWeight.w900 : FontWeight.w800)),
      ],
    );
  }
}

String _statusText(int s) {
  switch (s) {
    case 0: return 'Chưa thanh toán';
    case 1: return 'Đang xử lý';
    case 2: return 'Đã hủy';
    case 3: return 'Đã thanh toán';
    default: return 'Không rõ';
  }
}

class _PaymentMethodBox extends ConsumerWidget {
  final Order order;
  const _PaymentMethodBox({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tAsync = ref.watch(transactionByOrderProvider(order.orderId));

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24, width: 1),
        color: const Color(0x10FFFFFF),
      ),
      child: tAsync.when(
        loading: () => const LinearProgressIndicator(minHeight: 2),
        error: (e, _) => Text('Lỗi phương thức thanh toán: $e',
            style: const TextStyle(color: Colors.redAccent)),
        data: (tran) {
          final pmAsync = ref.watch(
            paymentMethodByIdProvider(tran?.paymentMethodId),
          );

          Widget _timeRow(String label, DateTime? dt) => _RowKV(
            left: label,
            right: dt == null ? '-' : _fmtDate(dt.toLocal()),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Phương thức thanh toán',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),

              // Phương thức (decription)
              pmAsync.when(
                loading: () => const _RowKV(left: 'Phương thức', right: '...'),
                error: (e, _) => _RowKV(left: 'Phương thức', right: 'Lỗi: $e'),
                data: (pm) => _RowKV(
                  left: 'Phương thức',
                  right: (pm?.decription?.trim().isNotEmpty ?? false)
                      ? pm!.decription!
                      : '-',
                ),
              ),

              // Trạng thái từ Transaction.status
              _RowKV(
                left: 'Trạng thái',
                right: tran == null ? '-' : _statusText(tran.status),
              ),

              const SizedBox(height: 10),
              const Divider(color: Colors.white24, height: 16),

              _timeRow('Thời gian đặt hàng', order.createdAt),
              _timeRow('Thời gian thanh toán', tran?.updatedAt),
            ],
          );
        },
      ),
    );
  }
}

