import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../provider.dart';
import '../../model/order.dart';
import '../../screen/order_status_screen.dart';
import '../../style/button.dart';
import '../../util/trans_type.dart' show TransactionType;

import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as fstorage;

import '../../widget/gs_image.dart';

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

  // ==== Ảnh đã chọn ====
  Uint8List? _imgBytes;
  String? _imgName;

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
                        const Text('Yêu cầu Trả hàng/Hoàn tiền',
                            style: TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  Container(height: 1, color: Colors.white.withOpacity(0.15)),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        // ===== Thông tin đơn =====
                        orderAsync.when(
                          loading: () => const LinearProgressIndicator(minHeight: 2),
                          error: (e, _) => Text('Lỗi tải đơn: $e', style: const TextStyle(color: Colors.redAccent)),
                          data: (order) => OrderCard(
                            order: order,
                            actionLabel: 'Xem chi tiết',
                            onAction: () => context.push('/orders/detail/${order.orderId}'),
                            onSeeMore: () => context.push('/orders/detail/${order.orderId}'),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ===== Tình huống =====
                        const Text('Tình huống bạn đang gặp',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 10),
                        _radioSituation('Tôi đã nhận hàng', _Situation.received),
                        _radioSituation('Tôi chưa nhận hàng/nhận thiếu hàng', _Situation.notReceived),

                        const SizedBox(height: 16),

                        // ===== Lý do =====
                        Row(
                          children: [
                            const Expanded(
                              child: Text('Lý do',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                            ),
                            ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 36, minWidth: 160, maxWidth: 300),
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white38),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                onPressed: _pickReason,
                                child: Text(_reason ?? 'Chọn lý do >>',
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ===== Thêm hình ảnh =====
                        const Text('Thêm hình ảnh:',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _chooseImage,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24, width: 1),
                              color: const Color(0x12000000),
                            ),
                            child: Center(
                              child: _imgBytes == null
                                  ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  // Icon máy ảnh
                                  GsImage(
                                    url: 'gs://sep490-fa25se182.firebasestorage.app/icon/camera.png',
                                    width: 42, height: 42, fit: BoxFit.contain,
                                  ),
                                  SizedBox(height: 6),
                                  Text('Chạm để chọn ảnh',
                                      style: TextStyle(color: Colors.white70)),
                                ],
                              )
                                  : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(_imgBytes!, fit: BoxFit.cover, width: double.infinity),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (_imgBytes == null)
                          const Text('Bạn phải thêm hình ảnh trước khi gửi yêu cầu',
                              style: TextStyle(color: Colors.pinkAccent)),

                        const SizedBox(height: 24),

                        // ===== Gửi =====
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

  // ==== Chọn lý do ====
  Future<void> _pickReason() async {
    final reasons = (_situation == _Situation.received)
        ? const ['Nền tảng gửi sai hàng','Hàng hư hỏng, lỗi','Hàng khác với mô tả','Hàng đã qua sử dụng','Hàng giả, nhái']
        : const ['Chưa nhận được hàng','Thiếu hàng','Thùng hàng rỗng'];

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

  // ==== Chọn ảnh từ thư viện ====
  Future<void> _chooseImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null) return;

    final bytes = await x.readAsBytes();
    setState(() {
      _imgBytes = bytes;
      _imgName  = x.name;
    });
  }

  // ==== Upload ảnh lên Firebase Storage====
  Future<String> _uploadImageToGs(String orderId) async {
    if (_imgBytes == null) throw StateError('No image selected');

    final ts = DateTime.now().millisecondsSinceEpoch;
    final fileName = _imgName ?? 'evidence_$ts.jpg';
    final path = 'order/$orderId/$fileName';

    final storage = fstorage.FirebaseStorage.instance;
    final ref = storage.ref().child(path);

    final meta = fstorage.SettableMetadata(contentType: 'image/jpeg');
    await ref.putData(_imgBytes!, meta);

    final bucket = storage.bucket;
    final gsUrl = 'gs://$bucket/$path';
    return gsUrl;
  }

  // ==== Gửi yêu cầu (update Order + tạo REFUND transaction) ====
  Future<void> _submit(AsyncValue<Order> orderAsync) async {
    if ((_reason ?? '').isEmpty || _imgBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn phải thêm hình ảnh/lý do trước khi gửi yêu cầu')),
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
      // 1) Upload ảnh
      final gsUrl = await _uploadImageToGs(order.orderId);

      // 2) Cập nhật Order: status = 7 (RETURNED), reason + imageUrl
      await ref.read(orderRepoProvider).update(
        order.orderId,
        status: 7,
        reason: reasonText,
        imageUrl: gsUrl,
      );

      // 3) Tạo Transaction REFUND
      await ref.read(transactionRepoProvider).createWallet(
        totalPrice: order.totalPrice,
        status: 0,
        orderId: order.orderId,
        transType: TransactionType.REFUND,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi yêu cầu')),
      );
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
