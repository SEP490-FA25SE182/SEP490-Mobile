import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../model/book.dart';
import '../../model/bookshelve.dart';
import '../../provider.dart';
import '../../widget/gs_image.dart';

class BookshelvePage extends ConsumerStatefulWidget {
  const BookshelvePage({super.key});

  @override
  ConsumerState<BookshelvePage> createState() => _BookshelvePageState();
}

class _BookshelvePageState extends ConsumerState<BookshelvePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: bookshelvesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          error: (e, _) => Center(
            child: Text('Lỗi: $e', style: const TextStyle(color: Colors.redAccent)),
          ),
          data: (bookshelves) {
            if (bookshelves.isEmpty) {
              return const Center(
                child: Text('Không có kệ sách nào.', style: TextStyle(color: Colors.white70)),
              );
            }

            final firstShelf = bookshelves.first;
            final shelfId = firstShelf.bookshelveId;

            // if somehow shelfId is null or empty, show fallback message
            if (shelfId == null || shelfId.isEmpty) {
              return const Center(
                child: Text('Không tìm thấy mã kệ sách.', style: TextStyle(color: Colors.white70)),
              );
            }

            final booksAsync = ref.watch(booksByShelfProvider(shelfId));


            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firstShelf.bookshelveName ?? 'Kệ sách',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (firstShelf.decription?.isNotEmpty == true)
                  Text(
                    firstShelf.decription!,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                const SizedBox(height: 16),

                // search bar
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF18223A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Tìm kiếm sách...',
                            hintStyle: TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onSubmitted: (_) => setState(() {}),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.white70),
                        onPressed: () => setState(() {}),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // books grid
                Expanded(
                  child: booksAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    error: (e, _) => Center(
                      child: Text('Lỗi tải sách: $e', style: const TextStyle(color: Colors.redAccent)),
                    ),
                    data: (books) {
                      for (final b in books) {
                        debugPrint('- ${b.bookName} (${b.bookId})');
                      }
                      if (books.isEmpty) {
                        return const Center(
                          child: Text('Không có sách trong kệ này.', style: TextStyle(color: Colors.white70)),
                        );
                      }

                      final searchText = _searchController.text.trim().toLowerCase();
                      final filtered = searchText.isEmpty
                          ? books
                          : books.where((b) => b.bookName.toLowerCase().contains(searchText)).toList();

                      if (filtered.isEmpty) {
                        return const Center(
                          child: Text('Không tìm thấy sách nào.', style: TextStyle(color: Colors.white70)),
                        );
                      }

                      return GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.6,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final book = filtered[i];
                          final author = ref.watch(userByIdProvider(book.authorId ?? ''));

                          return GestureDetector(
                            onTap: () => context.push('/books/${book.bookId}'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: GsImage(
                                      url: book.coverUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  book.bookName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                author.when(
                                  data: (user) => Text(
                                    user.fullName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  loading: () => const Text(
                                    'Đang tải...',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                  error: (_, __) => const Text(
                                    'Không rõ tác giả',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
