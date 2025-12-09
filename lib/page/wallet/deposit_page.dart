import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../provider.dart';
import '../../style/button.dart';
import '../../widget/gs_image.dart';

class DepositPage extends ConsumerStatefulWidget {
  final String walletId;
  const DepositPage({super.key, required this.walletId});

  @override
  ConsumerState<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends ConsumerState<DepositPage> {
  final _ctrl = TextEditingController(text: '0');
  bool _formatting = false;
  bool _busy = false;

  void _refresh() {
    // ép Riverpod load lại ví từ server
    ref.invalidate(walletByIdProvider(widget.walletId));
  }

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refresh();
    });
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onChanged);
    _ctrl.dispose();
    super.dispose();
  }

  // parse số từ ô nhập (bỏ dấu .)
  int get _amount {
    final raw = _ctrl.text.replaceAll('.', '').trim();
    final n = int.tryParse(raw) ?? 0;
    return n;
  }

  void _onChanged() {
    if (_formatting) return;
    _formatting = true;

    // chỉ giữ chữ số
    final digits = _ctrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final n = int.tryParse(digits) ?? 0;
    final formatted = _fmtVndInt(n, withSuffix: false);

    final sel = TextSelection.collapsed(offset: formatted.length);
    _ctrl.value = TextEditingValue(text: formatted, selection: sel);

    _formatting = false;
    setState(() {}); // cập nhật lỗi / tổng tiền
  }

  bool get _isValid => _amount >= 10000;

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
                          'Nạp tiền',
                          style: TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: Colors.white.withOpacity(0.15)),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        // Thẻ số dư
                        walletAsync.when(
                          loading: () => const _BalanceCard(loading: true),
                          error: (e, _) => _BalanceCard(error: '$e'),
                          data: (w) => _BalanceCard(balance: w?.balance ?? 0),
                        ),
                        const SizedBox(height: 16),

                        // Nhập số tiền nạp
                        const Text('Nhập số tiền nạp (đ)',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _ctrl,
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            prefixText: 'đ ',
                            prefixStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 18),
                            hintText: '0',
                            hintStyle: const TextStyle(color: Colors.white24),
                            filled: true,
                            fillColor: const Color(0x10FFFFFF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.white24),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.white54),
                            ),
                          ),
                        ),
                        if (!_isValid)
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text(
                              'Số tiền không được nhỏ hơn 10.000 VND',
                              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                            ),
                          ),

                        const SizedBox(height: 12),
                        Row(
                          children: [
                            QuickAmountButton(amount: 100000, onTap: _setAmount),
                            const SizedBox(width: 12),
                            QuickAmountButton(amount: 200000, onTap: _setAmount),
                            const SizedBox(width: 12),
                            QuickAmountButton(amount: 500000, onTap: _setAmount),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Phương thức thanh toán
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
                              const Text('Phương thức thanh toán',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 10),
                              _RowKV(left: 'Phương thức', right: 'Thanh toán qua PayOS VietQR'),
                              _RowKV(left: 'Nạp tiền', right: _fmtVndInt(_amount)),
                              const SizedBox(height: 10),
                              const Divider(color: Colors.white24, height: 16),
                              _RowKV(left: 'Tổng thanh toán', right: _fmtVndInt(_amount), bold: true),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        const Text(
                          'Nhấn "Nạp tiền ngay" đồng nghĩa với việc bạn đồng ý tuân theo Điều khoản Rookies',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        const SizedBox(height: 16),

                        ButtonPrimary(
                          text: _busy ? 'Đang tạo liên kết...' : 'Nạp tiền ngay',
                          onTap: (!_isValid || _busy) ? null : () => _onDeposit(widget.walletId),
                          height: 48,
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
    _ctrl.text = _fmtVndInt(v, withSuffix: false);
  }

  Future<void> _onDeposit(String walletId) async {
    setState(() => _busy = true);
    try {
      final amount = _amount;
      final returnUrl = 'rookies://payment/success?type=DEPOSIT&walletId=$walletId';
      final cancelUrl  = 'rookies://payment/cancel?type=DEPOSIT&walletId=$walletId';

      final res = await ref.read(paymentRepoProvider).deposit(
        walletId,
        amount: amount,
        returnUrl: returnUrl,
        cancelUrl: cancelUrl,
      );

      // mở PayOS
      if (!mounted) return;
      final ok = await launchUrl(
        Uri.parse(res.checkoutUrl),
        mode: LaunchMode.externalApplication,
      );

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không mở được trình duyệt. Link: ${res.checkoutUrl}')),
        );
      }
    } on DioException catch (e) {
      final sc = e.response?.statusCode;
      final msg = e.response?.data is Map && (e.response!.data['message'] is String)
          ? e.response!.data['message'] as String
          : e.message ?? 'Unknown error';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nạp tiền thất bại ($sc): $msg')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nạp tiền thất bại: $e')),
        );
      }
    } finally {
      if (!mounted) return;
      setState(() => _busy = false);
      context.go('/wallet/money');
    }
  }
}

// ================== Widgets & Helpers ==================

class _BalanceCard extends StatelessWidget {
  final double? balance;
  final bool loading;
  final String? error;

  const _BalanceCard({this.balance, this.loading = false, this.error});

  static const _iconMoney = 'gs://sep490-fa25se182.firebasestorage.app/icon/money.png';

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (loading) {
      child = const SizedBox(
        height: 36,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    } else if (error != null) {
      child = Text('Lỗi tải ví: $error',
          style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center);
    } else {
      child = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              GsImage(url: _iconMoney, width: 22, height: 22, fit: BoxFit.contain),
              SizedBox(width: 8),
              Text('Số tiền bạn đang có',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _fmtVnd((balance ?? 0).toDouble()),
            style: const TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.w900),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft, end: Alignment.centerRight,
          colors: [Color(0xFF6A78FF), Color(0xFF7E50B5)],
        ),
      ),
      child: Center(child: child),
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

// format VND double -> "1.234.567 VND"
String _fmtVnd(double v) => _fmtVndInt(v.round());

// format int với dấu chấm; có/không hậu tố
String _fmtVndInt(int v, {bool withSuffix = true}) {
  final s = v
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  return withSuffix ? '$s VND' : s;
}
