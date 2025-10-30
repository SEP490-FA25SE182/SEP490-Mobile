import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../model/book.dart';
import '../../provider.dart';
import '../../widget/gs_image.dart';

final bookByIdProvider = FutureProvider.family<Book, String>((ref, id) async {
  final repo = ref.read(bookRepoProvider);
  return repo.getById(id);
});

class BookDetailPage extends ConsumerWidget {
  final String bookId;

  const BookDetailPage({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(bookByIdProvider(bookId));

    return Scaffold(
      backgroundColor: const Color(0xFF09121F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E2A47),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Chi tiết sách'),
        centerTitle: true,
      ),
      body: bookAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (e, _) => Center(
          child: Text('Lỗi: $e',
              style: const TextStyle(color: Colors.redAccent)),
        ),
        data: (book) {
          final authorAsync = ref.watch(userByIdProvider(book.authorId ?? ''));
          final dateFormat = DateFormat('dd/MM/yyyy');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// --- ẢNH BÌA SÁCH + NÚT YÊU THÍCH ---
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: GsImage(url: book.coverUrl, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Gọi API thêm vào danh sách yêu thích
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.black38,
                          side: const BorderSide(color: Color(0xFF5B6CF3)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.favorite_border,
                            color: Color(0xFF5B6CF3), size: 16),
                        label: const Text(
                          'Yêu thích',
                          style: TextStyle(
                              color: Color(0xFF5B6CF3), fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                /// --- TÊN SÁCH ---
                Text(
                  book.bookName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                /// --- TÁC GIẢ ---
                authorAsync.when(
                  data: (author) => Text(
                    author.fullName,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  loading: () => const Text('Đang tải tác giả...',
                      style: TextStyle(color: Colors.white54)),
                  error: (_, __) => const Text('Không rõ tác giả',
                      style: TextStyle(color: Colors.white54)),
                ),
                const SizedBox(height: 16),

                /// --- GIÁ ---
                if (book.price != null)
                  Text(
                    'Giá: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(book.price)}',
                    style: const TextStyle(
                      color: Color(0xFF5B6CF3),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 16),

                /// --- SỐ LƯỢNG ---
                if (book.quantity != null)
                  Text(
                    'Số lượng trong kho: ${book.quantity}',
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                const SizedBox(height: 20),

                /// --- THỂ LOẠI ---
                if (book.genres.isNotEmpty) ...[
                  const Text(
                    'Thể loại:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: book.genres
                        .map((g) => Chip(
                      label: Text(
                        g.genreName,
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: const Color(0xFF18223A),
                    ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                /// --- MÔ TẢ ---
                const Text(
                  'Giới thiệu:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  book.description?.isNotEmpty == true
                      ? book.description!
                      : 'Chưa có mô tả cho cuốn sách này.',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),

                /// --- THÔNG TIN KHÁC ---
                _infoRow(
                  'Ngày phát hành',
                  book.publishedDate != null
                      ? dateFormat.format(book.publishedDate!)
                      : 'Không có thông tin',
                ),
                _infoRow(
                  'Trạng thái',
                  book.isActived == 'ACTIVE'
                      ? 'Đang phát hành'
                      : 'Ngưng phát hành',
                ),

                const SizedBox(height: 36),

                /// --- NÚT HÀNH ĐỘNG DƯỚI ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Gọi API thêm vào giỏ hàng
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B6CF3),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.shopping_cart_outlined),
                        label: const Text(
                          'Thêm vào giỏ hàng',
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Gọi API mua ngay
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2ECC71),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.flash_on_outlined),
                        label: const Text(
                          'Mua ngay',
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 14)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
