import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../model/book.dart';
import '../../model/cart.dart';
import '../../model/genre.dart';
import '../../model/feedback.dart';
import '../../provider.dart';
import '../../repository/bookshelve_repository.dart';
import '../../repository/genre_repository.dart';
import '../../widget/gs_image.dart';
import '../feedback/feedback_dialog.dart';
import '../feedback/feedback_viewlist_page.dart';

/// Provider: fetch book by ID
final bookByIdProvider = FutureProvider.family<Book, String>((ref, id) async {
  final repo = ref.read(bookRepoProvider);
  return repo.getById(id);
});

/// Provider: fetch genres for a book
final genresByBookProvider = FutureProvider.family<List<Genre>, String>((ref, bookId) async {
  final repo = ref.read(genreRepoProvider);
  return repo.listByBook(bookId: bookId);
});

/// Provider: check if a book is in the newest bookshelf
final isBookInFavoriteProvider = FutureProvider.family<bool, (String userId, String bookId)>((ref, args) async {
  final (userId, bookId) = args;
  final repo = ref.read(bookshelveRepoProvider);
  return repo.isBookInFavorite(userId, bookId);
});

/// Provider: fetch average rating + count for a book
final feedbackStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, bookId) async {
  final repo = ref.read(feedbackRepoProvider);
  final feedbacks = await repo.search(
    bookId: bookId,
    isActived: IsActived.active,
    status: FeedbackStatus.published,
  );
  if (feedbacks.isEmpty) return {'avg': 0.0, 'count': 0};
  final total = feedbacks.fold(0, (sum, f) => sum + f.rating);
  final avg = total / feedbacks.length;
  return {'avg': avg, 'count': feedbacks.length};
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

      ref.invalidate(isBookInFavoriteProvider((userId, bookId)));
      ref.invalidate(booksByShelfProvider(shelfId));
      ref.invalidate(bookshelvesProvider(userId));
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
              if (userId == null || userId.isEmpty) return const SizedBox();

              final favAsync = ref.watch(isBookInFavoriteProvider((userId, bookId)));
              return favAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => Center(child: Text('Lỗi: $e', style: const TextStyle(color: Colors.redAccent))),
        data: (book) {
          final authorAsync = ref.watch(userByIdProvider(book.authorId ?? ''));
          final userId = ref.watch(currentUserIdProvider);
          final dateFormat = DateFormat('dd/MM/yyyy');
          final statsAsync = ref.watch(feedbackStatsProvider(bookId));

          if (userId == null || userId.isEmpty) {
            return const Center(
              child: Text('Vui lòng đăng nhập để xem chi tiết.', style: TextStyle(color: Colors.white70)),
            );
          }

          final genresAsync = ref.watch(genresByBookProvider(book.bookId));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover
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

                // Title
                Text(book.bookName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                // Author
                authorAsync.when(
                  data: (author) => Text(author.fullName, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                  loading: () => const Text('Đang tải tác giả...', style: TextStyle(color: Colors.white54)),
                  error: (_, __) => const Text('Không rõ tác giả', style: TextStyle(color: Colors.white54)),
                ),

                // Rating
                const SizedBox(height: 12),
                statsAsync.when(
                  data: (stats) {
                    final avg = stats['avg'] as double;
                    final count = stats['count'] as int;
                    return Row(
                      children: [
                        Text(avg > 0 ? avg.toStringAsFixed(1) : '-', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 18, fontWeight: FontWeight.bold)),
                        const Icon(Icons.star, color: Color(0xFFFFD700), size: 20),
                        const SizedBox(width: 8),
                        Text('($count đánh giá)', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    );
                  },
                  loading: () => const Text('Đang tải đánh giá...', style: TextStyle(color: Colors.white54)),
                  error: (_, __) => const SizedBox(),
                ),

                const SizedBox(height: 16),
                if (book.price != null)
                  Text(
                    'Giá: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(book.price)}',
                    style: const TextStyle(color: Color(0xFF5B6CF3), fontSize: 18, fontWeight: FontWeight.w600),
                  ),

                const SizedBox(height: 16),
                const Text('Thể loại:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 8),
                genresAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
                  error: (e, _) => Text('Lỗi tải thể loại: $e', style: const TextStyle(color: Colors.redAccent)),
                  data: (genres) => genres.isEmpty
                      ? const Text('Chưa có thể loại.', style: TextStyle(color: Colors.white54))
                      : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: genres
                        .map((g) => Chip(
                      label: Text(g.genreName, style: const TextStyle(color: Colors.white)),
                      backgroundColor: const Color(0xFF18223A),
                    ))
                        .toList(),
                  ),
                ),

                const SizedBox(height: 20),
                const Text('Giới thiệu:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  book.description?.isNotEmpty == true ? book.description! : 'Chưa có mô tả cho cuốn sách này.',
                  style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                ),

                const SizedBox(height: 20),
                _infoRow('Ngày phát hành', book.publishedDate != null ? dateFormat.format(book.publishedDate!) : 'Không có thông tin'),
                _infoRow('Trạng thái', book.isActived == 'ACTIVE' ? 'Đang phát hành' : 'Ngưng phát hành'),

                const SizedBox(height: 36),

                const SizedBox(height: 20),
                Consumer(
                  builder: (context, ref, _) {
                    final userId = ref.watch(currentUserIdProvider);
                    if (userId == null) return const SizedBox();

                    final statusAsync = ref.watch(userFeedbackStatusProvider((userId, bookId)));
                    final countAsync = ref.watch(publishedFeedbackCountProvider(bookId));

                    return statusAsync.when(
                      loading: () => const Center(
                        child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                      ),
                      error: (_, __) => const SizedBox(),
                      data: (statusData) {
                        final hasBought = statusData.orderDetailId != null;
                        final hasActive = statusData.hasActive;
                        final status = statusData.status;

                        String buttonText;
                        bool enabled;
                        Color color;

                        if (!hasBought) {
                          buttonText = 'Chưa mua';
                          enabled = false;
                          color = Colors.grey;
                        } else if (hasActive && status == FeedbackStatus.published) {
                          buttonText = 'Đã đánh giá';
                          enabled = false;
                          color = Colors.grey;
                        } else if (hasActive && status == FeedbackStatus.pending) {
                          buttonText = 'Đánh giá đang được duyệt';
                          enabled = false;
                          color = Colors.orange;
                        } else if (hasActive && status == FeedbackStatus.denied) {
                          buttonText = 'Viết đánh giá lại';
                          enabled = true;
                          color = const Color(0xFFFF6B6B);
                        } else {
                          buttonText = 'Viết đánh giá';
                          enabled = true;
                          color = const Color(0xFFFF6B6B);
                        }

                        return Column(
                          children: [
                            // REVIEW BUTTON
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: enabled && hasBought
                                    ? () async {
                                  final success = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => FeedbackDialog(
                                      bookId: bookId,
                                      orderDetailId: statusData.orderDetailId!,
                                      userId: userId,
                                    ),
                                  );
                                  if (success == true) {
                                    ref.invalidate(feedbackStatsProvider(bookId));
                                    ref.invalidate(userFeedbackStatusProvider((userId, bookId)));
                                    ref.invalidate(publishedFeedbackCountProvider(bookId));
                                  }
                                }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: color,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.rate_review, size: 18),
                                label: Text(buttonText, style: const TextStyle(fontSize: 14)),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // VIEW ALL BUTTON
                            countAsync.when(
                              data: (count) {
                                final hasFeedback = count > 0;
                                return Center(
                                  child: TextButton.icon(
                                    onPressed: hasFeedback
                                        ? () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => FeedbackViewListPage(
                                          bookId: bookId,
                                          bookName: book.bookName,
                                        ),
                                      ),
                                    )
                                        : null,
                                    icon: Icon(
                                      Icons.rate_review_outlined,
                                      color: hasFeedback ? const Color(0xFF5B6CF3) : Colors.grey,
                                    ),
                                    label: Text(
                                      hasFeedback ? 'Xem $count đánh giá' : 'Chưa có đánh giá',
                                      style: TextStyle(
                                        color: hasFeedback ? const Color(0xFF5B6CF3) : Colors.grey,
                                        fontWeight: hasFeedback ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              loading: () => const SizedBox(),
                              error: (_, __) => const SizedBox(),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Action Buttons
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
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 14)),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontSize: 14))),
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
                  const SnackBar(content: Text('Vui lòng đăng nhập để thêm vào giỏ hàng')),
                );
                return;
              }
              try {
                // Lấy hoặc tạo cart
                final cart = await ref.read(ensuredCartByUserProvider(userId).future);

                final cartItemRepo = ref.read(cartItemRepoProvider);

                // Lấy items trong cart
                final items = await cartItemRepo.listByCart(cart.cartId);
                final existed = items.where((it) => it.bookId == book.bookId).toList();

                if (existed.isNotEmpty) {
                  // Tăng số lượng nếu sách đã có trong giỏ
                  final current = existed.first;
                  await cartItemRepo.update(
                    current.cartItemId,
                    quantity: current.quantity + 1,
                  );
                } else {
                  // Thêm mới
                  await cartItemRepo.create(
                    cartId: cart.cartId,
                    bookId: book.bookId,
                    quantity: 1,
                    price: (book.price ?? 0).toDouble(),
                  );
                }

                // Refresh lại cart & items
                ref.invalidate(ensuredCartByUserProvider(userId));
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.shopping_cart_outlined),
            label: const Text('Thêm vào giỏ hàng', style: TextStyle(fontSize: 15)),
          ),
        ),
        const SizedBox(width: 12),
        // nút "Mua ngay" giữ nguyên
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2ECC71),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.flash_on_outlined),
            label: const Text('Mua ngay', style: TextStyle(fontSize: 15)),
          ),
        ),
      ],
    );
  }
}