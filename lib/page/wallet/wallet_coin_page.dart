import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../widget/gs_image.dart';
import '../../provider.dart';
import '../../model/wallet.dart';
import 'package:intl/intl.dart';

class WalletCoinPage extends ConsumerStatefulWidget {
  const WalletCoinPage({super.key});

  @override
  ConsumerState<WalletCoinPage> createState() => _WalletCoinPageState();
}

class _WalletCoinPageState extends ConsumerState<WalletCoinPage> {

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final asyncWallet = (userId == null || userId.isEmpty)
        ? const AsyncValue<Wallet?>.data(null)
        : ref.watch(ensuredWalletByUserProvider(userId)).whenData((w) => w);

    const iconGs = 'gs://sep490-fa25se182.firebasestorage.app/icon/coin-bag.png';
    const yellow = Color(0xFFFFD54F);

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
                          'Túi xu của tôi',
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

                  // Card trung tâm
                  if (userId == null || userId.isEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Vui lòng đăng nhập để xem túi xu.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ] else
                    asyncWallet.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(16),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Lỗi tải ví: $e',
                            style: const TextStyle(color: Colors.redAccent)),
                      ),
                      data: (wallet) {
                        final coins = wallet?.coin ?? 0;
                        final coinText = NumberFormat.decimalPattern('vi_VN').format(coins);

                        return Column(
                          children: [
                            const SizedBox(height: 12),
                            Container(
                              height: 120,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                gradient: const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [Color(0xFF6A78FF), Color(0xFF7E50B5)],
                                ),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const GsImage(
                                      url: iconGs,
                                      width: 72,
                                      height: 72,
                                      fit: BoxFit.contain,
                                    ),
                                    const SizedBox(width: 14),
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: coinText,
                                            style: const TextStyle(
                                              color: yellow,
                                              fontSize: 30,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const TextSpan(
                                            text: '  Xu khả dụng',
                                            style: TextStyle(
                                              color: yellow,
                                              fontSize: 16.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
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
