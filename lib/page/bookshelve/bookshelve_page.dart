import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../model/bookshelve.dart';
import '../../provider.dart';
import '../../widget/gs_image.dart';

class BookshelvePage extends ConsumerWidget {
  const BookshelvePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);

    if (userId == null || userId.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF09121F),
        appBar: AppBar(
          title: const Text('Thư viện'),
          centerTitle: true,
          backgroundColor: const Color(0xFF0E2A47),
        ),
        body: Center(
          child: GestureDetector(
            onTap: () => context.push('/login'),
            child: const Text(
              'Vui lòng đăng nhập trước',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      );
    }

    final bookshelvesAsync = ref.watch(bookshelvesProvider(userId));

    return Scaffold(
      backgroundColor: const Color(0xFF09121F),
      appBar: AppBar(
        title: const Text('Thư viện'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0E2A47),
      ),
      body: bookshelvesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (e, _) => Center(
          child: Text(
            'Lỗi: $e',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
        data: (bookshelves) {
          if (bookshelves.isEmpty) {
            return const Center(
              child: Text(
                'Không có kệ sách nào.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookshelves.length,
            itemBuilder: (context, i) {
              final shelf = bookshelves[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF13294B), Color(0xFF0B162A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// --- HEADER ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          shelf.bookshelveName ?? 'Kệ chưa đặt tên',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.more_vert, color: Colors.white70),
                        ),
                      ],
                    ),
                    if (shelf.decription?.isNotEmpty == true)
                      Text(
                        shelf.decription!,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    const SizedBox(height: 12),

                    /// --- BOOK LIST (horizontal scroll) ---
                    if (shelf.books.isEmpty)
                      const Text(
                        'Chưa có sách trong kệ này.',
                        style: TextStyle(color: Colors.white54),
                      )
                    else
                      SizedBox(
                        height: 180,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: shelf.books.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (_, index) {
                            final book = shelf.books[index];
                            return GestureDetector(
                              onTap: () => context.push('/books/${book.bookId}'),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: GsImage(
                                      url: book.coverUrl,
                                      width: 100,
                                      height: 140,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      book.bookName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
