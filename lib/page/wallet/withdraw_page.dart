import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../provider.dart';
import '../../model/wallet.dart';
import '../../style/button.dart';
import '../../util/trans_type.dart';
import '../../widget/gs_image.dart';
import '../../style/input_text.dart';
import '../../style/button.dart';

class WithdrawPage extends ConsumerStatefulWidget {
  final String walletId;
  const WithdrawPage({super.key, required this.walletId});

  @override
  ConsumerState<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends ConsumerState<WithdrawPage> {
  static const _iconMoney =
      'gs://sep490-fa25se182.firebasestorage.app/icon/money.png';

  // controllers
  final _amountCtl = TextEditingController(text: '0');
  final _accNameCtl = TextEditingController();
  final _accNoCtl   = TextEditingController();

  int _amount = 0; // đồng
  String? _bankName;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _amountCtl.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountCtl.removeListener(_onAmountChanged);
    _amountCtl.dispose();
    _accNameCtl.dispose();
    _accNoCtl.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    final digits = _amountCtl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final parsed = int.tryParse(digits) ?? 0;
    final formatted = _fmtInt(parsed);
    if (_amountCtl.text != formatted) {
      _amountCtl.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    setState(() => _amount = parsed);
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletByIdProvider(widget.walletId));

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
                          onPressed: () => context.go('/wallet/money'),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Rút tiền',
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
                        // ===== Số dư =====
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft, end: Alignment.centerRight,
                              colors: [Color(0xFF6A78FF), Color(0xFF7E50B5)],
                            ),
                          ),
                          child: Center(
                            child: walletAsync.when(
                              loading: () => const SizedBox(
                                height: 36,
                                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              ),
                              error: (e, _) => Text('Lỗi tải ví: $e', style: const TextStyle(color: Colors.redAccent)),
                              data: (w) => Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      GsImage(
                                          url: _iconMoney, width: 22, height: 22, fit: BoxFit.contain),
                                      SizedBox(width: 8),
                                      Text('Số tiền bạn đang có',
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _fmtVnd((w?.balance ?? 0).toDouble()),
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ===== Nhập tiền =====
                        const Text('Nhập số tiền rút (đ)',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        InputFieldBox(
                          height: 56,
                          child: TextField(
                            controller: _amountCtl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                            decoration: const InputDecoration(
                              hintText: '0',
                              hintStyle: TextStyle(color: Colors.white38, fontWeight: FontWeight.w700),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            QuickAmountButton(amount: 100000, onTap: _setAmount),
                            QuickAmountButton(amount: 200000, onTap: _setAmount),
                            QuickAmountButton(amount: 500000, onTap: _setAmount),
                          ],
                        ),

                        const SizedBox(height: 8),
                        // cảnh báo
                        walletAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (w) {
                            final bal = w?.balance ?? 0.0;
                            final tooSmall = _amount > 0 && _amount < 10000;
                            final tooBig   = _amount > bal.round();
                            final text = tooSmall
                                ? 'Số tiền không được nhỏ hơn 10.000 VND'
                                : (tooBig ? 'Số tiền không được lớn hơn số dư hiện có' : null);
                            return text == null
                                ? const SizedBox.shrink()
                                : Text(text, style: const TextStyle(color: Colors.pinkAccent));
                          },
                        ),

                        const SizedBox(height: 16),

                        // ===== Chủ TK =====
                        const Text('Tên chủ tài khoản',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        InputFieldBox(
                          child: TextField(
                            controller: _accNameCtl,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            decoration: const InputDecoration(
                              hintText: 'Nhập tên chủ tài khoản',
                              hintStyle: TextStyle(color: Colors.white54),
                              border: InputBorder.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ===== Ngân hàng =====
                        const Text('Tên ngân hàng',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickBank,
                          child: InputFieldBox(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _bankName ?? 'Chọn ngân hàng  >>',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ===== Số TK =====
                        const Text('Số tài khoản',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        InputFieldBox(
                          child: TextField(
                            controller: _accNoCtl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            decoration: const InputDecoration(
                              hintText: 'Nhập số tài khoản',
                              hintStyle: TextStyle(color: Colors.white54),
                              border: InputBorder.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        const Text(
                          '“Rút tiền” có thể mất 3 - 5 ngày để xử lý. Để biết chi tiết vui lòng đọc kỹ điều khoản bên dưới.',
                          style: TextStyle(color: Colors.white60),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Nhấn "Rút tiền ngay" đồng nghĩa với việc bạn đồng ý tuân theo Điều khoản Rookies',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        const SizedBox(height: 14),

                        // ===== Nút rút =====
                        walletAsync.when(
                          loading: () => const SizedBox(height: 48),
                          error: (_, __) => const SizedBox(height: 48),
                          data: (w) {
                            final bal = w?.balance ?? 0.0;
                            final disabled = _busy ||
                                _amount <= 0 ||
                                _amount < 10000 ||
                                _amount > bal.round() ||
                                _bankName == null ||
                                _accNameCtl.text.trim().isEmpty ||
                                _accNoCtl.text.trim().isEmpty;

                            return ButtonPrimary(
                              text: _busy ? 'Đang xử lý...' : 'Rút tiền ngay',
                              onTap: disabled ? null : () => _submit(w!),
                              height: 48,
                            );
                          },
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

  void _setAmount(int v) {
    final formatted = _fmtInt(v);
    _amountCtl.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    setState(() => _amount = v);
  }

  Future<void> _pickBank() async {
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
            const Text('Chọn ngân hàng',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: _vnBanks.map((b) => ListTile(
                  title: Text(b, style: const TextStyle(color: Colors.white)),
                  onTap: () => Navigator.pop(ctx, b),
                )).toList(),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
    if (chosen != null && chosen.isNotEmpty) {
      setState(() => _bankName = chosen);
    }
  }

  Future<void> _submit(Wallet wallet) async {
    setState(() => _busy = true);
    try {
      final accName = _accNameCtl.text.trim();
      final accNo   = _accNoCtl.text.trim();
      final bank    = _bankName ?? '';

      // Gọi API rút tiền
      await ref.read(paymentRepoProvider).withdraw(
        wallet.walletId,
        amount: _amount,
        accountName: accName,
        bankName: bank,
        accountNumber: accNo,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn đã rút tiền thành công')),
      );
      context.go('/wallet/money');
    } on DioException catch (e) {
      if (!mounted) return;
      final sc = e.response?.statusCode;
      final msg = e.response?.data is Map && (e.response!.data['message'] is String)
          ? e.response!.data['message'] as String
          : e.message ?? 'Lỗi không xác định';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rút tiền thất bại ($sc): $msg')),
      );
      context.go('/wallet/money');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rút tiền thất bại: $e')),
      );
      context.go('/wallet/money');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

// ===== Helpers =====
String _fmtVnd(double v) =>
    v.round().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.') + ' VND';

String _fmtInt(int v) =>
    v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

// Danh sách ngân hàng VN
const List<String> _vnBanks = [
  'Vietcombank',
  'VietinBank',
  'TPbank',
  'BIDV',
  'Agribank',
  'Techcombank',
  'MBbank',
  'ACB',
  'Sacombank',
];
