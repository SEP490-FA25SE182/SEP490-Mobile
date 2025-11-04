import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../provider.dart';
import '../../model/order.dart';
import '../../screen/order_status_screen.dart';
import '../../style/button.dart';

enum _Situation { received, notReceived }

class ReturnPage extends ConsumerStatefulWidget {
  final String orderId;
  const ReturnPage({super.key, required this.orderId});

  @override
  ConsumerState<ReturnPage> createState() => _ReturnPageState();
}

class _ReturnPageState extends ConsumerState<ReturnPage> {
  _Situation _situation = _Situation.received;
  String? _reason;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderByIdProvider(widget.orderId));

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
                          onPressed: () => context.pop(),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Yêu cầu Trả hàng/Hoàn tiền',
                          style: TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: Colors.white.withOpacity(0.15)),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        // ======= Ô thông tin đơn: dùng OrderCard từ order_status_screen.dart =======
                        orderAsync.when(
                          loading: () => const LinearProgressIndicator(minHeight: 2),
                          error: (e, _) => Text('Lỗi tải đơn: $e',
                              style: const TextStyle(color: Colors.redAccent)),
                          data: (order) => OrderCard(
                            order: order,
                            actionLabel: 'Xem chi tiết',
                            onAction: () => context.push('/orders/detail/${order.orderId}'),
                            onSeeMore: () => context.push('/orders/detail/${order.orderId}'),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ======= Tình huống =======
                        const Text(
                          'Tình huống bạn đang gặp',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        _radioSituation('Tôi đã nhận hàng', _Situation.received),
                        _radioSituation('Tôi chưa nhận hàng/nhận thiếu hàng', _Situation.notReceived),

                        const SizedBox(height: 16),

                        // ======= Lý do =======
                        Row(
                          children: [
                            const Expanded(
                              child: Text('Lý do',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                            ),
                            SizedBox(
                              height: 36,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white38),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: _pickReason,
                                child: const Text('Chọn lý do >'),
                              ),
                            ),
                          ],
                        ),
                        if ((_reason ?? '').isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(_reason!, style: const TextStyle(color: Colors.white70)),
                        ],

                        const SizedBox(height: 24),

                        // ======= Gửi yêu cầu =======
                        ButtonSoft(
                          text: _busy ? 'Đang gửi...' : 'Gửi yêu cầu',
                          onTap: _busy ? null : () => _submit(orderAsync),
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

  // ==== Radios ====
  Widget _radioSituation(String text, _Situation value) {
    return InkWell(
      onTap: () => setState(() => _situation = value),
      child: Row(
        children: [
          Radio<_Situation>(
            value: value,
            groupValue: _situation,
            onChanged: (v) => setState(() => _situation = v ?? _situation),
            activeColor: const Color(0xFF5B6CF3),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70))),
        ],
      ),
    );
  }

  // ==== Lý do theo tình huống ====
  Future<void> _pickReason() async {
    final reasons = (_situation == _Situation.received)
        ? const [
      'Nền tảng gửi sai hàng',
      'Hàng hư hỏng, lỗi',
      'Hàng khác với mô tả',
      'Hàng đã qua sử dụng',
      'Hàng giả, nhái',
    ]
        : const [
      'Chưa nhận được hàng',
      'Thiếu hàng',
      'Thùng hàng rỗng',
    ];

    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF0F1B2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 10),
            const Text('Chọn lý do', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ...reasons.map((r) => ListTile(
              title: Text(r, style: const TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, r),
            )),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );

    if (chosen != null && chosen.isNotEmpty) {
      setState(() => _reason = chosen);
    }
  }

  // ==== Submit update RETURNED + reason ====
  Future<void> _submit(AsyncValue<Order> orderAsync) async {
    if ((_reason ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn lý do')),
      );
      return;
    }

    final order = orderAsync.value;
    if (order == null) return;

    final group = (_situation == _Situation.received)
        ? 'Tôi đã nhận hàng'
        : 'Tôi chưa nhận hàng/nhận thiếu hàng';
    final reasonText = '$group: ${_reason!}';

    setState(() => _busy = true);
    try {
      await ref.read(orderRepoProvider).update(
        order.orderId,
        status: 6,
        reason: reasonText,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi yêu cầu')),
      );
      // Điều hướng sau khi gửi:
      context.go('/orders/return');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gửi yêu cầu thất bại: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
