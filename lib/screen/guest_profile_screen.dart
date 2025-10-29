import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../style/button.dart';
import '../widget/gs_image.dart';

/// Khu vực **dành cho khách (chưa đăng nhập)** ở trang hồ sơ.
/// ĐÃ BỎ hai nút Đăng nhập / Đăng ký theo yêu cầu.
class GuestProfileSection extends StatelessWidget {
  const GuestProfileSection({super.key});

  static const String _bannerGs =
      'gs://sep490-fa25se182.firebasestorage.app/banner/banner.png';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Xin chào!'),
              const SizedBox(height: 8),
              const Text(
                'Đăng nhập để đồng bộ thư viện, theo dõi đơn hàng,\n'
                    'nhận gợi ý truyện hay và nhiều ưu đãi dành riêng cho bạn.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: GsImage(url: _bannerGs, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 16),

              // Nút Scan
              ButtonSoft(
                text: 'Scan',
                onTap: () async {
                  final result = await context.push<String>('/scan'); 
                  if (result != null && result.isNotEmpty && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã quét: $result')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x1FFFFFFF), Color(0x10FFFFFF)],
        ),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
          color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
    );
  }
}
