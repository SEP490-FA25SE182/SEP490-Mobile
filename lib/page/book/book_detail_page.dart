import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../model/book.dart';
import '../../model/cart.dart';
import '../../model/cart_item.dart';
import '../../provider.dart';
import '../../model/genre.dart';
import '../../repository/bookshelve_repository.dart';
import '../../repository/genre_repository.dart';
import '../../widget/gs_image.dart';

/// Provider: fetch book by ID
final bookByIdProvider = FutureProvider.family<Book, String>((ref, id) async {
  final repo = ref.read(bookRepoProvider);
  return repo.getById(id);
});

/// Provider: fetch genres for a book
final genresByBookProvider =
FutureProvider.family<List<Genre>, String>((ref, bookId) async {
  final repo = ref.read(genreRepoProvider);
  return repo.listByBook(bookId: bookId);
});

/// Provider: check if a book is in the newest bookshelf
final isBookInFavoriteProvider =
FutureProvider.family<bool, (String userId, String bookId)>((ref, args) async {
  final (userId, bookId) = args;
  final repo = ref.read(bookshelveRepoProvider);
  return repo.isBookInFavorite(userId, bookId);
});

class BookDetailPage extends ConsumerWidget {
  final String bookId;
  const BookDetailPage({super.key, required this.bookId});

  Future<void> _toggleFavorite({
    required WidgetRef ref,
    required BuildContext context,
    required String userId,
    required String bookId,
    required bool isFavorite,
  }) async {
    final repo = ref.read(bookshelveRepoProvider);
    try {
      final newestShelf = await repo.getNewestByUser(userId);
      if (newestShelf == null || newestShelf.bookshelveId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy kệ sách của bạn')),
        );
        return;
      }

      final shelfId = newestShelf.bookshelveId!;

      if (isFavorite) {
        await repo.removeBookFromShelf(bookId: bookId, bookshelfId: shelfId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa khỏi kệ sách của bạn')),
        );
      } else {
        await repo.addBookToShelf(bookId: bookId, bookshelfId: shelfId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm vào kệ sách mới nhất')),
        );
      }

      // Refresh the favorite state
      ref.invalidate(isBookInFavoriteProvider((userId, bookId)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật kệ sách: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(bookByIdProvider(bookId));

    return Scaffold(
      backgroundColor: const Color(0xFF09121F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E2A47),
        title: const Text('Chi tiết sách'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final userId = ref.watch(currentUserIdProvider);
              if (userId == null || userId.isEmpty) {
                return const SizedBox();
              }

              final favAsync =
              ref.watch(isBookInFavoriteProvider((userId, bookId)));
              return favAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                error: (e, _) => const SizedBox(),
                data: (isFavorite) => IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: Colors.pinkAccent,
                  ),
                  onPressed: () => _toggleFavorite(
                    ref: ref,
                    context: context,
                    userId: userId,
                    bookId: bookId,
                    isFavorite: isFavorite,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: bookAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (e, _) => Center(
          child: Text(
            'Lỗi: $e',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
        data: (book) {
          final authorAsync = ref.watch(userByIdProvider(book.authorId ?? ''));
          final userId = ref.watch(currentUserIdProvider);
          final dateFormat = DateFormat('dd/MM/yyyy');

          if (userId == null || userId.isEmpty) {
            return const Center(
              child: Text(
                'Vui lòng đăng nhập để xem chi tiết.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final genresAsync = ref.watch(genresByBookProvider(book.bookId));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 16),
                Text(
                  book.bookName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                authorAsync.when(
                  data: (author) => Text(
                    author.fullName,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  loading: () => const Text(
                    'Đang tải tác giả...',
                    style: TextStyle(color: Colors.white54),
                  ),
                  error: (_, __) => const Text(
                    'Không rõ tác giả',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                const SizedBox(height: 16),
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
                const Text(
                  'Thể loại:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                genresAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  error: (e, _) => Text(
                    'Lỗi tải thể loại: $e',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  data: (genres) {
                    if (genres.isEmpty) {
                      return const Text(
                        'Chưa có thể loại.',
                        style: TextStyle(color: Colors.white54),
                      );
                    }
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: genres
                          .map(
                            (g) => Chip(
                          label: Text(
                            g.genreName,
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: const Color(0xFF18223A),
                        ),
                      )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 20),
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
                _bottomActionButtons(context, ref, book),
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

  Widget _bottomActionButtons(BuildContext context, WidgetRef ref, Book book) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              final userId = ref.read(currentUserIdProvider);
              if (userId == null || userId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Vui lòng đăng nhập để thêm vào giỏ hàng')),
                );
                return;
              }
              try {
                final cartRepo = ref.read(cartRepoProvider);
                final cartItemRepo = ref.read(cartItemRepoProvider);
                Cart? cart = await cartRepo.getByUserId(userId);
                cart ??= await cartRepo.createOne(userId: userId);

                final items = await cartItemRepo.listByCart(cart.cartId);
                final existed =
                items.where((it) => it.bookId == book.bookId).toList();

                if (existed.isNotEmpty) {
                  await cartItemRepo.update(
                    existed.first.cartItemId,
                    quantity: existed.first.quantity + 1,
                  );
                } else {
                  await cartItemRepo.create(
                    cartId: cart.cartId,
                    bookId: book.bookId,
                    quantity: 1,
                    price: (book.price ?? 0).toDouble(),
                  );
                }

                ref.invalidate(cartByUserProvider(userId));
                ref.invalidate(cartItemsByCartProvider(cart.cartId));

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã thêm vào giỏ hàng')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi thêm giỏ hàng: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B6CF3),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.shopping_cart_outlined),
            label:
            const Text('Thêm vào giỏ hàng', style: TextStyle(fontSize: 15)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2ECC71),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.flash_on_outlined),
            label: const Text('Mua ngay', style: TextStyle(fontSize: 15)),
          ),
        ),
      ],
    );
  }
}
