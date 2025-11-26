import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../provider.dart';
import '../../model/order.dart';
import '../../model/order_detail.dart';
import '../../model/user_address.dart';
import '../../model/book.dart';
import '../../widget/gs_image.dart';
import '../../screen/order_detail_screen.dart';

// Icon
const _iconEdit = 'gs://sep490-fa25se182.firebasestorage.app/icon/edit.png';

class CheckoutArgs {
  final String orderId;
  const CheckoutArgs({required this.orderId});
}

enum _PayMethod { payos, cod, wallet }

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

    final walletAsync = (userId == null || userId.isEmpty)
        ? const AsyncValue<dynamic>.data(null)
        : ref.watch(walletByUserProvider(userId));

    final shippingFeeAsync = ref.watch(shippingFeeProvider(orderId));

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
                        OrderDetailSection(orderId: orderId),
                        const SizedBox(height: 12),

                        // ==== Phương thức thanh toán ====
                        const Text(
                          'Phương thức thanh toán',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Container(height: 1, color: Colors.white24),
                        const SizedBox(height: 10),

                        orderAsync.when(
                          loading: () => const LinearProgressIndicator(minHeight: 2),
                          error: (e, _) => Text(
                            'Lỗi tải đơn: $e',
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                          data: (order) {
                            final total = order.totalPrice;

                            final basicRows = Row(
                              children: [
                                Expanded(
                                  child: _RadioRow(
                                    label: 'Ví PayOS',
                                    value: _PayMethod.payos,
                                    group: _method,
                                    onChanged: (v) => setState(() => _method = v),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _RadioRow(
                                    label: 'Thanh toán khi nhận hàng',
                                    value: _PayMethod.cod,
                                    group: _method,
                                    onChanged: (v) => setState(() => _method = v),
                                  ),
                                ),
                              ],
                            );

                            final walletRow = walletAsync.when<Widget>(
                              loading: () => const SizedBox(height: 26),
                              error: (e, _) => Text('Lỗi ví: $e', style: const TextStyle(color: Colors.redAccent)),
                              data: (wallet) {
                                final balance = (wallet?.balance ?? 0.0) as double;
                                final canUse = balance >= total;
                                final label = 'Ví Rookies, số dư: ${_fmtVnd(balance)}';

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _RadioRow(
                                      label: label,
                                      value: _PayMethod.wallet,
                                      group: _method,
                                      onChanged: (v) {
                                        if (!canUse) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Số dư không đủ')),
                                          );
                                          return;
                                        }
                                        setState(() => _method = v);
                                      },
                                      disabled: !canUse,
                                    ),
                                    if (!canUse)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 44),
                                        child: Text('Số dư không đủ', style: TextStyle(color: Colors.redAccent)),
                                      ),
                                  ],
                                );
                              },
                            );

                            return Column(
                              children: [
                                basicRows,
                                const SizedBox(height: 6),
                                walletRow,
                              ],
                            );
                          },
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

                        detailsAsync.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: LinearProgressIndicator(minHeight: 2),
                          ),
                          error: (e, _) => Text('Lỗi chi tiết: $e',
                              style: const TextStyle(color: Colors.redAccent)),
                          data: (details) {
                            final subtotal = details.fold<num>(
                              0,
                                  (sum, d) => sum + d.quantity * d.price,
                            );

                            return orderAsync.when(
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                              data: (order) {
                                final save = subtotal - order.totalPrice;

                                final shippingFee = shippingFeeAsync.value?.total ?? 30000;
                                final isFreeShipping = order.totalPrice >= 300000;
                                final finalShippingFee = isFreeShipping ? 0 : shippingFee;
                                final finalTotal = order.totalPrice + finalShippingFee;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _RowKV(left: 'Tiền hàng', right: _fmtVnd(subtotal.toDouble())),
                                    if (save > 0.0001)
                                      _RowKV(left: 'Tiết kiệm', right: _fmtVnd(save.toDouble())),

                                    const SizedBox(height: 10),
                                    const Divider(color: Colors.white24, height: 16),

                                    _RowKV(
                                      left: 'Phí vận chuyển',
                                      rightWidget: shippingFeeAsync.when(
                                        loading: () => const Text(
                                          'Đang tính phí...',
                                          style: TextStyle(fontSize: 13, color: Colors.white70),
                                        ),
                                        error: (_, __) => const Text(
                                          '30.000 VND',
                                          style: TextStyle(color: Colors.orange),
                                        ),
                                        data: (_) => Text(
                                          isFreeShipping
                                              ? 'Miễn phí (đơn ≥ 300.000đ)'
                                              : _fmtVnd(finalShippingFee.toDouble()),
                                          style: TextStyle(
                                            color: isFreeShipping ? Colors.green : Colors.white,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    _RowKV(
                                      left: 'Tổng thanh toán',
                                      right: _fmtVnd(finalTotal.toDouble()),
                                      rightStyle: const TextStyle(
                                        color: Colors.orangeAccent,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
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

                  // ==== Bottom bar with correct final total ====
                  orderAsync.when(
                    data: (order) {
                      final shippingFee = shippingFeeAsync.value?.total ?? 30000;
                      final isFreeShipping = order.totalPrice >= 300000;
                      final finalTotal = isFreeShipping ? order.totalPrice : order.totalPrice + shippingFee;

                      return _BottomBar(
                        total: finalTotal.toDouble(),
                        busy: _placing,
                        onPlace: () => _onPlaceOrder(order, finalTotal, shippingFeeAsync),
                      );
                    },
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

  String? _resolveAddressId(String? userId) {
    if (_selectedAddress != null) return _selectedAddress!.userAddressId;
    if (userId == null || userId.isEmpty) return null;
    final list = ref.read(addressesByUserProvider(userId)).value;
    if (list == null || list.isEmpty) return null;
    final def = list.where((e) => e.isDefault).toList();
    return (def.isNotEmpty ? def.first : list.first).userAddressId;
  }

  Widget _buildAddressSection(AsyncValue<List<UserAddress>> addrAsync, String? userId) {
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
                    ref.read(checkoutSelectedAddressProvider.notifier).state = result;
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
              final defaults = list.where((e) => e.isDefault).toList();
              final preferred = defaults.isNotEmpty ? defaults.first : (list.isNotEmpty ? list.first : null);
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

  // ← Updated to accept final total
  Future<void> _onPlaceOrder(Order order, double finalTotal, AsyncValue<dynamic> shippingFeeAsync) async {
    if (_method == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy chọn phương thức thanh toán đi nà')),
      );
      return;
    }

    final uid = ref.read(currentUserIdProvider);
    final addressId = _resolveAddressId(uid);
    if (addressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn địa chỉ nhận hàng')),
      );
      return;
    }

    setState(() => _placing = true);
    try {
      if (_method == _PayMethod.payos) {
        // Calculate real total (same as UI)
        final shippingFee = shippingFeeAsync.value?.total ?? 30000;
        final isFreeShipping = order.totalPrice >= 300000;
        final realTotal = isFreeShipping ? order.totalPrice : order.totalPrice + shippingFee;

        // Step 1: Update order with correct totalPrice + address
        await ref.read(orderRepoProvider).update(
          order.orderId,
          userAddressId: addressId,
          totalPrice: realTotal,  // This makes PayOS charge correct amount
          status: order.status,
        );

        // Step 2: Create PayOS link (backend will read updated totalPrice)
        final returnUrl = 'rookies://payment/success?orderId=${order.orderId}';
        final cancelUrl = 'rookies://payment/cancel?orderId=${order.orderId}';

        final res = await ref.read(paymentRepoProvider).createCheckout(
          order.orderId,
          returnUrl: returnUrl,
          cancelUrl: cancelUrl,
        );

        if (!mounted) return;
        final ok = await launchUrl(Uri.parse(res.checkoutUrl), mode: LaunchMode.externalApplication);
        if (!ok) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không mở được link thanh toán')));
        }
      } else if (_method == _PayMethod.cod) {
        await ref.read(orderRepoProvider).update(
          order.orderId,
          userAddressId: addressId,
          status: order.status,
        );

        await ref.read(transactionRepoProvider).createCOD(
          totalPrice: finalTotal,
          status: 0,
          orderId: order.orderId,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đặt hàng thành công')),
        );
        context.go('/orders/pending');
      } else if (_PayMethod.wallet == _method) {
        final me = ref.read(currentUserIdProvider);
        if (me == null || me.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bạn cần đăng nhập để dùng ví Rookies')),
          );
          return;
        }

        final wallet = await ref.read(walletRepoProvider).getByUserId(me);
        final balance = wallet?.balance ?? 0.0;
        if (wallet == null || balance < finalTotal) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Số dư ví không đủ')),
          );
          return;
        }

        await ref.read(orderRepoProvider).update(
          order.orderId,
          userAddressId: addressId,
          status: 2,
        );

        await ref.read(transactionRepoProvider).createWallet(
          totalPrice: finalTotal,
          status: 3,
          orderId: order.orderId,
          walletId: wallet.walletId,
        );

        final newBalance = balance - finalTotal;
        await ref.read(walletRepoProvider).update(
          wallet.walletId,
          balance: newBalance,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanh toán bằng Ví Rookies thành công')),
        );
        context.go('/orders/processing');
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

class _RowKV extends StatelessWidget {
  final String left;
  final String? right;
  final Widget? rightWidget;
  final TextStyle? rightStyle;

  const _RowKV({
    required this.left,
    this.right,
    this.rightWidget,
    this.rightStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(left, style: const TextStyle(color: Colors.white70)),
        const Spacer(),
        if (rightWidget != null) rightWidget!,
        if (right != null)
          Text(
            right!,
            style: rightStyle ?? const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
      ],
    );
  }
}

class _RadioRow extends StatelessWidget {
  final String label;
  final _PayMethod value;
  final _PayMethod? group;
  final ValueChanged<_PayMethod?> onChanged;
  final bool disabled;

  const _RadioRow({
    required this.label,
    required this.value,
    required this.group,
    required this.onChanged,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnChanged = disabled ? null : onChanged;

    return InkWell(
      onTap: disabled? null : () => effectiveOnChanged!(value),
      child: Row(
        children: [
          Radio<_PayMethod>(
            value: value,
            groupValue: group,
            onChanged: effectiveOnChanged,
            visualDensity: VisualDensity.compact,
            activeColor: const Color(0xFF5B6CF3),
          ),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: disabled ? Colors.white38 : Colors.white70,
              ),
            ),
          ),
        ],
      ),
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

String _fmtVnd(double v) {
  final s = v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  return '$s VND';
}