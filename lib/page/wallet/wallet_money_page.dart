import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../provider.dart';
import '../../model/wallet.dart';
import '../../model/transaction.dart';
import '../../widget/gs_image.dart';
import '../../util/trans_type.dart';

class WalletMoneyPage extends ConsumerStatefulWidget {
  const WalletMoneyPage({super.key});

  @override
  ConsumerState<WalletMoneyPage> createState() => _WalletMoneyPageState();
}

class _WalletMoneyPageState extends ConsumerState<WalletMoneyPage> {
  bool _showAll = false;

  void _refresh() {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || userId.isEmpty) return;
    // reload ví (sẽ tự tạo nếu chưa có vì dùng ensuredWalletByUserProvider)
    ref.invalidate(ensuredWalletByUserProvider(userId));
  }

  @override
  void initState() {
    super.initState();
    // Mỗi lần mở trang -> reload
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);

    final asyncWallet = (userId == null || userId.isEmpty)
        ? const AsyncValue<Wallet?>.data(null)
        : ref.watch(ensuredWalletByUserProvider(userId)).whenData((w) => w);

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
                          onPressed: () => context.go('/profile'),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Ví tiền của tôi',
                          style: TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.check_box_outlined, color: Colors.white),
                          onPressed: _refresh,
                        ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: Colors.white.withOpacity(0.15)),

                  // Card số dư
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xFF6A78FF), Color(0xFF7E50B5)],
                        ),
                      ),
                      child: Center(
                        child: asyncWallet.when(
                          loading: () => const SizedBox(
                            height: 36,
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          error: (e, _) => Text('Lỗi tải ví: $e',
                              style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
                          data: (wallet) {
                            if (userId == null || userId.isEmpty) {
                              return const Text('Vui lòng đăng nhập để xem số dư.',
                                  style: TextStyle(color: Colors.white70));
                            }
                            if (wallet == null) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  SizedBox(height: 6),
                                  _HeaderRow(),
                                  SizedBox(height: 10),
                                  Text('0 VND',
                                      style: TextStyle(color: Colors.limeAccent, fontSize: 24, fontWeight: FontWeight.w900)),
                                ],
                              );
                            }
                            final balanceStr = _fmtVnd(wallet.balance);
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const _HeaderRow(),
                                const SizedBox(height: 10),
                                Text(balanceStr,
                                    style: const TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.w900)),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // --- 3 nút hành động ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: asyncWallet.when(
                      loading: () => const SizedBox(height: 84),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (wallet) {
                        final wid = wallet?.walletId;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white24, width: 1),
                            color: const Color(0x10FFFFFF),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _ActionButton(
                                icon: 'gs://sep490-fa25se182.firebasestorage.app/icon/wallet.png',
                                label: 'Nạp tiền',
                                onTap: () async {
                                  if (wid == null || wid.isEmpty) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(content: Text('Không tìm thấy ví.')));
                                    return;
                                  }
                                  await context.push('/wallet/deposit/$wid');
                                  if (!mounted) return;
                                  _refresh();
                                },
                              ),
                              _ActionButton(
                                icon: 'gs://sep490-fa25se182.firebasestorage.app/icon/withdraw.png',
                                label: 'Rút tiền',
                                onTap: () async {
                                  if (wid == null || wid.isEmpty) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(content: Text('Không tìm thấy ví.')));
                                    return;
                                  }
                                  await context.push('/wallet/withdraw/$wid');
                                  if (!mounted) return;
                                  _refresh();
                                },
                              ),
                              _ActionButton(
                                icon: 'gs://sep490-fa25se182.firebasestorage.app/icon/help.png',
                                label: 'Trợ giúp',
                                onTap: () => context.push('/wallet/help'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- Lịch sử giao dịch ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        const Text('Lịch sử giao dịch',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                        const Spacer(),
                        InkWell(
                          onTap: () => setState(() => _showAll = !_showAll),
                          child: Text(_showAll ? 'Thu gọn' : 'Xem tất cả',
                              style: const TextStyle(color: Colors.white70, decoration: TextDecoration.underline)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Danh sách
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: asyncWallet.when(
                        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        error: (e, _) => Center(
                            child: Text('Lỗi tải ví: $e', style: const TextStyle(color: Colors.redAccent))),
                        data: (wallet) {
                          final wid = wallet?.walletId;
                          if (wid == null || wid.isEmpty) {
                            return const Center(
                                child: Text('Chưa có ví để hiển thị giao dịch', style: TextStyle(color: Colors.white70)));
                          }
                          final txAsync = ref.watch(transactionsByWalletProvider(wid));
                          return txAsync.when(
                            loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            error: (e, _) => Center(
                                child: Text('Lỗi tải giao dịch: $e', style: const TextStyle(color: Colors.redAccent))),
                            data: (list) {
                              final show = _showAll ? list : list.take(5).toList();
                              if (show.isEmpty) {
                                return const Center(
                                    child: Text('Chưa có giao dịch', style: TextStyle(color: Colors.white70)));
                              }
                              return ListView.separated(
                                itemCount: show.length,
                                separatorBuilder: (_, __) => Container(
                                  height: 1,
                                  color: Colors.white24,
                                ),
                                itemBuilder: (ctx, i) => _TxRow(tx: show[i]),
                              );
                            },
                          );
                        },
                      ),
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

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  static const _iconMoney = 'gs://sep490-fa25se182.firebasestorage.app/icon/money.png';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        GsImage(url: _iconMoney, width: 22, height: 22, fit: BoxFit.contain),
        SizedBox(width: 8),
        Text('Số tiền bạn đang có', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 96,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0x15FFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              padding: const EdgeInsets.all(10),
              child: GsImage(url: icon, fit: BoxFit.contain),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  final Transaction tx;
  const _TxRow({required this.tx});

  // icon theo loại
  String get _icon {
    switch (tx.transType) {
      case TransactionType.DEPOSIT:
        return 'gs://sep490-fa25se182.firebasestorage.app/icon/add-money.png';
      case TransactionType.WITHDRAW:
        return 'gs://sep490-fa25se182.firebasestorage.app/icon/courthouse.png';
      case TransactionType.SETTLEMENT:
        return 'gs://sep490-fa25se182.firebasestorage.app/icon/royalty.png';
      case TransactionType.REFUND:
        return 'gs://sep490-fa25se182.firebasestorage.app/icon/money-back.png';
      case TransactionType.PAYMENT:
      default:
        return 'gs://sep490-fa25se182.firebasestorage.app/icon/open-book.png';
    }
  }

  // tiêu đề + màu số tiền (+/-)
  (String title, bool plus) get _label {
    switch (tx.transType) {
      case TransactionType.DEPOSIT:
        return ('Nạp tiền', true);
      case TransactionType.WITHDRAW:
        return ('Rút tiền', false);
      case TransactionType.SETTLEMENT:
        return ('Tất toán tác quyền', true);
      case TransactionType.REFUND:
        return ('Hoàn tiền đơn hàng', true);
      case TransactionType.PAYMENT:
      default:
        return ('Thanh toán đơn hàng', false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (title, plus) = _label;
    final price = _fmtVnd(tx.totalPrice);
    final amountText = '${plus ? '+' : '-'} $price';
    final color = plus ? const Color(0xFF00E676) : const Color(0xFFFF5252);

    final time = tx.updatedAt ?? tx.createdAt;
    String timeStr = '';
    if (time != null) {
      final t = time.toLocal();
      String two(int x) => x < 10 ? '0$x' : '$x';
      timeStr = '${two(t.day)}/${two(t.month)}/${t.year} at ${two(t.hour)}:${two(t.minute)}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0x15FFFFFF),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            padding: const EdgeInsets.all(8),
            child: GsImage(url: _icon, fit: BoxFit.contain),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                if (timeStr.isNotEmpty)
                  Text(timeStr, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Text(amountText, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

String _fmtVnd(double v) {
  final asInt = v.round();
  final s = asInt.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  return '$s VND';
}
