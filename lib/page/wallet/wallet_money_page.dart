import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../provider.dart';
import '../../model/wallet.dart';
import '../../widget/gs_image.dart';

class WalletMoneyPage extends ConsumerWidget {
  const WalletMoneyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);

    final asyncWallet = (userId == null || userId.isEmpty)
        ? const AsyncValue<Wallet?>.data(null)
        : ref.watch(walletByUserProvider(userId));

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
                  colors: [
                    Color(0xFF1B3B68),
                    Color(0xFF0F1B2E),
                    Color(0xFF123C6B),
                  ],
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
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        // Nút refresh nhanh
                        IconButton(
                          icon: const Icon(Icons.check_box_outlined, color: Colors.white),
                          onPressed: () {
                            if (userId != null && userId.isNotEmpty) {
                              ref.invalidate(walletByUserProvider(userId));
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: Colors.white.withOpacity(0.15)),

                  // Thẻ số dư trung tâm
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
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          error: (e, _) => Text(
                            'Lỗi tải ví: $e',
                            style: const TextStyle(color: Colors.redAccent),
                            textAlign: TextAlign.center,
                          ),
                          data: (wallet) {
                            if (userId == null || userId.isEmpty) {
                              return const Text(
                                'Vui lòng đăng nhập để xem số dư.',
                                style: TextStyle(color: Colors.white70),
                              );
                            }
                            if (wallet == null) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  SizedBox(height: 6),
                                  _HeaderRow(),
                                  SizedBox(height: 10),
                                  Text(
                                    '0 VND',
                                    style: TextStyle(
                                      color: Colors.limeAccent,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              );
                            }

                            final balanceStr = _fmtVnd(wallet.balance);
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const _HeaderRow(),
                                const SizedBox(height: 10),
                                Text(
                                  balanceStr,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const Expanded(child: SizedBox.shrink()),
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
        Text(
          'Số tiền bạn đang có',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

String _fmtVnd(double v) {
  final asInt = v.round();
  final s = asInt
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  return '$s VND';
}
