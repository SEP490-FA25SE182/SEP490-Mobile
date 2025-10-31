import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../provider.dart';
import '../../model/order.dart';
import '../../model/order_detail.dart';
import '../../model/user_address.dart';
import '../../widget/gs_image.dart';

// Icon
const _iconEdit = 'gs://sep490-fa25se182.firebasestorage.app/icon/edit.png';

class CheckoutArgs {
  final String orderId;
  const CheckoutArgs({required this.orderId});
}

enum _PayMethod { payos, cod }

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  _PayMethod? _method;
  UserAddress? _selectedAddress;
  bool _placing = false;

  @override
  Widget build(BuildContext context) {
    final args = GoRouterState.of(context).extra as CheckoutArgs?;
    final orderId = args?.orderId ?? '';

    final userId = ref.watch(currentUserIdProvider);
    final addrAsync = (userId == null || userId.isEmpty)
        ? const AsyncValue<List<UserAddress>>.data(<UserAddress>[])
        : ref.watch(addressesByUserProvider(userId));

    final orderAsync = (orderId.isEmpty)
        ? AsyncValue<Order>.error('Thiếu orderId', StackTrace.current)
        : ref.watch(orderByIdProvider(orderId));

    final detailsAsync = (orderId.isEmpty)
        ? const AsyncValue<List<OrderDetail>>.data(<OrderDetail>[])
        : ref.watch(orderDetailsByOrderProvider(orderId));

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
                          'Thanh toán',
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
                      padding: const EdgeInsets.all(12),
                      children: [
                        // ==== Địa chỉ nhận hàng ====
                        _buildAddressSection(addrAsync, userId),

                        const SizedBox(height: 16),

                        // ==== Danh sách sản phẩm ====
                        detailsAsync.when(
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (e, _) => Text(
                            'Lỗi tải chi tiết đơn: $e',
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                          data: (list) => Column(
                            children: [
                              ...list.map((d) => _OrderItemRow(detail: d)),
                              const SizedBox(height: 8),
                              Container(height: 1, color: Colors.white24),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ==== Phương thức thanh toán ====
                        const Text(
                          'Phương thức thanh toán',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _RadioRow(
                              label: 'Ví PayOS',
                              value: _PayMethod.payos,
                              group: _method,
                              onChanged: (v) => setState(() => _method = v),
                            ),
                            const SizedBox(width: 12),
                            _RadioRow(
                              label: 'Thanh toán khi nhận hàng',
                              value: _PayMethod.cod,
                              group: _method,
                              onChanged: (v) => setState(() => _method = v),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        Container(height: 1, color: Colors.white24),
                        const SizedBox(height: 12),

                        // ==== Chi tiết thanh toán ====
                        const Text(
                          'Chi tiết thanh toán',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        orderAsync.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: LinearProgressIndicator(minHeight: 2),
                          ),
                          error: (e, _) => Text(
                            'Lỗi tải đơn: $e',
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                          data: (order) => _RowKV(
                            left: 'Tổng thanh toán',
                            right: _fmtVnd(order.totalPrice),
                          ),
                        ),

                        const SizedBox(height: 20),
                        const Text(
                          'Nhấn "Đặt hàng" đồng nghĩa với việc bạn đồng ý tuân theo Điều khoản Rookies',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  // ==== Bottom bar ====
                  orderAsync.when(
                    data: (order) => _BottomBar(
                      total: order.totalPrice,
                      busy: _placing,
                      onPlace: () => _onPlaceOrder(order.orderId),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Address section ---
  Widget _buildAddressSection(
      AsyncValue<List<UserAddress>> addrAsync,
      String? userId,
      ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x10FFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Địa chỉ nhận hàng',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
              InkWell(
                onTap: () async {
                  if (userId == null || userId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bạn cần đăng nhập để chọn địa chỉ')),
                    );
                    return;
                  }
                  final result = await context.push('/location', extra: userId);
                  if (result is UserAddress) {
                    setState(() => _selectedAddress = result);
                  }
                },
                child: const SizedBox(
                  width: 22,
                  height: 22,
                  child: GsImage(url: _iconEdit, fit: BoxFit.contain),
                ),
              )
            ],
          ),
          const SizedBox(height: 10),

          addrAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(minHeight: 2),
            ),
            error: (e, _) => Text(
              'Lỗi tải địa chỉ: $e',
              style: const TextStyle(color: Colors.redAccent),
            ),
            data: (list) {
              // Ưu tiên default
              final defaults = list.where((e) => e.isDefault).toList();
              final preferred = defaults.isNotEmpty ? defaults.first : (list.isNotEmpty ? list.first : null);

              // Nếu chưa chọn thủ công, hiển thị mặc định
              final show = _selectedAddress ?? preferred;

              if (show == null) {
                return const Text(
                  'Bạn chưa có địa chỉ nhận hàng',
                  style: TextStyle(color: Colors.white70),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${show.fullName} ${(show.phoneNumber ?? '').isNotEmpty ? '(${show.phoneNumber})' : ''}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(show.addressInfor, style: const TextStyle(color: Colors.white70)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Đặt hàng ---
  Future<void> _onPlaceOrder(String orderId) async {
    if (_method == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy chọn phương thức thanh toán đi nà')),
      );
      return;
    }

    setState(() => _placing = true);
    try {
      if (_method == _PayMethod.payos) {
        final res = await ref.read(paymentRepoProvider).createCheckout(orderId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tạo thanh toán thành công! Mã: ${res.orderCode}')),
        );
        // TODO: mở WebView/Browser tới res.checkoutUrl
      } else {
        // TODO: Gọi API xác nhận COD sau
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đặt hàng COD — sẽ bổ sung API sau!')),
        );
      }
    } on DioException catch (e) {
      final sc = e.response?.statusCode;
      final data = e.response?.data;
      final msg = (data is Map && data['message'] is String)
          ? data['message'] as String
          : e.message ?? 'Unknown error';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đặt hàng thất bại ($sc): $msg')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đặt hàng thất bại: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }
}

class _RadioRow extends StatelessWidget {
  final String label;
  final _PayMethod value;
  final _PayMethod? group;
  final ValueChanged<_PayMethod?> onChanged;

  const _RadioRow({
    required this.label,
    required this.value,
    required this.group,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(value),
        child: Row(
          children: [
            Radio<_PayMethod>(
              value: value,
              groupValue: group,
              onChanged: onChanged,
              visualDensity: VisualDensity.compact,
              activeColor: const Color(0xFF5B6CF3),
            ),
            Flexible(
              child: Text(label, style: const TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RowKV extends StatelessWidget {
  final String left;
  final String right;
  const _RowKV({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(left, style: const TextStyle(color: Colors.white70)),
        const Spacer(),
        Text(right, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final double total;
  final bool busy;
  final VoidCallback onPlace;

  const _BottomBar({required this.total, required this.busy, required this.onPlace});

  @override
  Widget build(BuildContext context) {
    final totalStr = _fmtVnd(total);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF6A78FF), Color(0xFF7E50B5)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Tổng cộng  $totalStr',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: busy ? null : onPlace,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E3350),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              child: busy
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('ĐẶT HÀNG', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

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
              error: (_, __) => const Text('(Lỗi tên sách)', style: TextStyle(color: Colors.white70)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Helpers ----
String _fmtVnd(double v) {
  final s = v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  return '$s VND';
}
