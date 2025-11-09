import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WalletHelpPage extends StatelessWidget {
  const WalletHelpPage({super.key});

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
                          onPressed: () => context.go('/wallet/money'),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Trợ giúp Ví Rookies',
                          style: TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: Colors.white.withOpacity(0.15)),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: const [
                        _SectionTitle('Giới thiệu'),
                        Text(
                          'Ví Rookies giúp bạn nạp/rút tiền và thanh toán đơn hàng nhanh chóng. '
                              'Số dư ví hiển thị theo thời gian thực sau khi giao dịch được xử lý thành công.',
                          style: TextStyle(color: Colors.white70),
                        ),
                        SizedBox(height: 16),

                        _SectionTitle('Hướng dẫn nhanh'),
                        _Bullet('Nạp tiền: Ví Rookies → Nạp tiền → nhập số tiền → chọn thanh toán PayOS.'),
                        _Bullet('Rút tiền: Ví Rookies → Rút tiền → nhập số tiền → điền thông tin ngân hàng.'),
                        _Bullet('Lịch sử: Kéo xuống cuối màn hình để xem giao dịch gần đây.'),
                        SizedBox(height: 16),

                        _SectionTitle('Câu hỏi thường gặp'),
                        _FaqItem(
                          q: 'Nạp tiền mất bao lâu?',
                          a: 'Thanh toán qua PayOS thường ghi nhận ngay. '
                              'Trong một số trường hợp, ngân hàng cần 3–10 phút để xác nhận.',
                        ),
                        _FaqItem(
                          q: 'Rút tiền bao lâu nhận được?',
                          a: 'Trong vòng 3–5 ngày làm việc tùy ngân hàng. '
                              'Bạn sẽ thấy giao dịch “Rút tiền” ở lịch sử ngay khi yêu cầu được ghi nhận.',
                        ),
                        _FaqItem(
                          q: 'Tôi không thấy số dư cập nhật?',
                          a: 'Hãy kéo xuống trang Ví và nhấn vào biểu tượng làm mới ở góc phải. '
                              'Nếu vẫn chưa đúng sau 15 phút, vui lòng liên hệ hỗ trợ.',
                        ),
                        _FaqItem(
                          q: 'Ví có thu phí không?',
                          a: 'Hiện tại Rookies không thu phí nạp. Rút tiền có thể phát sinh phí ngân hàng (nếu có).',
                        ),
                        SizedBox(height: 16),

                        _SectionTitle('Liên hệ hỗ trợ'),
                        Text(
                          'Nếu bạn cần thêm trợ giúp, hãy gửi email tới support@rookies.app '
                              'hoặc nhắn “Liên hệ hỗ trợ” trong ứng dụng.',
                          style: TextStyle(color: Colors.white70),
                        ),
                        SizedBox(height: 12),
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
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.white70)),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70))),
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String q;
  final String a;
  const _FaqItem({required this.q, required this.a});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0x10FFFFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          collapsedIconColor: Colors.white,
          iconColor: Colors.white,
          title: Text(q, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          children: [
            Text(a, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
