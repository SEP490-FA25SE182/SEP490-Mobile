import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widget/gs_video.dart';
import '../../style/button.dart';

class PaymentCancelPage extends StatefulWidget {
  final String? orderId;
  const PaymentCancelPage({super.key, this.orderId});

  @override
  State<PaymentCancelPage> createState() => _PaymentCancelPageState();
}

class _PaymentCancelPageState extends State<PaymentCancelPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 10), () {
      if (mounted) context.go('/orders/pending');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                          onPressed: () => context.go('/'),
                        ),
                        const SizedBox(width: 6),
                        const Text('Thanh toán thất bại',
                          style: TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: Colors.white.withOpacity(0.15)),

                  const SizedBox(height: 28),
                  Center(
                    child: GsVideo(
                      url: 'gs://sep490-fa25se182.firebasestorage.app/animation_icon/failed.mp4',
                      width: 200, height: 200,
                      borderRadius: BorderRadius.circular(120),
                    ),
                  ),
                  const SizedBox(height: 28),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Đơn hàng của bạn bị thanh toán thất bại.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Bạn sẽ được đưa đến xem trạng thái đơn hàng sau 5 giây.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  if ((widget.orderId ?? '').isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Mã đơn: ${widget.orderId}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],

                  const Spacer(),
                  ButtonSoft(
                    text: 'Mua sắm vui vẻ tại đây',
                    onTap: () => context.go('/'),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    borderRadius: 12,
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
