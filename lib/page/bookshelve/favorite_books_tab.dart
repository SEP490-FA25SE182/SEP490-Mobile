import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider.dart';
import '../../widget/gs_image.dart';
import 'package:go_router/go_router.dart';

class FavoriteBooksTab extends ConsumerWidget {
  final void Function(int delta)? onPageChange;
  const FavoriteBooksTab({super.key, this.onPageChange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null || userId.isEmpty) {
      return const Center(
        child: Text('Vui lòng đăng nhập để xem sách yêu thích',
            style: TextStyle(color: Colors.white70)),
      );
    }

    final shelvesAsync = ref.watch(bookshelvesProvider(userId));

    return shelvesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi tải kệ sách: $e')),
      data: (shelves) {
        if (shelves.isEmpty) {
          return const Center(
            child: Text('Không có kệ sách yêu thích.', style: TextStyle(color: Colors.white70)),
          );
        }

        final shelf = shelves.firstWhere(
              (s) => s.bookshelveName?.toLowerCase().contains('yêu thích') ?? false,
          orElse: () => shelves.first,
        );

        final shelfId = shelf.bookshelveId ?? '';
        final booksAsync = ref.watch(booksByShelfProvider(shelfId));

        return booksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Lỗi tải sách: $e')),
          data: (books) {
            if (books.isEmpty) {
              return const Center(child: Text('Chưa có sách yêu thích nào'));
            }

            return RefreshIndicator(
              color: Colors.white,
              backgroundColor: const Color(0xFF0E2A47),
              onRefresh: () async {
                ref.invalidate(booksByShelfProvider(shelfId));
              },
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.6,
                ),
                itemCount: books.length,
                itemBuilder: (_, i) {
                  final book = books[i];
                  return GestureDetector(
                    onTap: () => context.push('/books/${book.bookId}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: GsImage(url: book.coverUrl, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          book.bookName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
