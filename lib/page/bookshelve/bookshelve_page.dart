import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../model/book.dart';
import '../../model/bookshelve.dart';
import '../../provider.dart';
import '../../widget/gs_image.dart';

/// TEMP placeholder for your "my books" API
final myBooksProvider = FutureProvider<List<Book>>((ref) async {
  // TODO: Replace with your real API call
  await Future.delayed(const Duration(seconds: 1));
  return []; // Return a list of your books here
});

class BookshelvePage extends ConsumerStatefulWidget {
  const BookshelvePage({super.key});

  @override
  ConsumerState<BookshelvePage> createState() => _BookshelvePageState();
}

class _BookshelvePageState extends ConsumerState<BookshelvePage> {
  final TextEditingController _searchController = TextEditingController();

  int _currentPage = 0;
  final int _pageSize = 6;
  bool _hasNext = false;
  bool _hasPrevious = false;
  List<Book> _pagedBooks = [];
  int _selectedTab = 0; // 0 = favorites, 1 = my books

  Future<void> _fetchBooks(
      WidgetRef ref, {
        String? shelfId,
        bool reset = false,
      }) async {
    try {
      if (reset) {
        _currentPage = 0;
        _pagedBooks.clear();
      }

      List<Book> allBooks = [];

      if (_selectedTab == 0) {
        // ✅ Normal bookshelf API
        if (shelfId == null) return;
        allBooks = await ref.read(booksByShelfProvider(shelfId).future);
      } else {
        // ✅ Your own API (replace later)
        allBooks = await ref.read(myBooksProvider.future);
      }

      final searchText = _searchController.text.trim().toLowerCase();
      final filtered = searchText.isEmpty
          ? allBooks
          : allBooks
          .where((b) => b.bookName.toLowerCase().contains(searchText))
          .toList();

      final start = _currentPage * _pageSize;
      final end = (_currentPage + 1) * _pageSize;

      _pagedBooks = filtered.sublist(
        start,
        end > filtered.length ? filtered.length : end,
      );

      _hasPrevious = _currentPage > 0;
      _hasNext = end < filtered.length;

      setState(() {});
    } catch (e) {
      debugPrint('Fetch error: $e');
    }
  }

  void _nextPage(WidgetRef ref, {String? shelfId}) {
    if (_hasNext) {
      _currentPage++;
      _fetchBooks(ref, shelfId: shelfId);
    }
  }

  void _previousPage(WidgetRef ref, {String? shelfId}) {
    if (_hasPrevious) {
      _currentPage--;
      _fetchBooks(ref, shelfId: shelfId);
    }
  }

  void _firstPage(WidgetRef ref, {String? shelfId}) {
    if (_currentPage != 0) {
      _currentPage = 0;
      _fetchBooks(ref, shelfId: shelfId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);

    if (userId == null || userId.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF09121F),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
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

            final favoriteShelf = bookshelves.firstWhere(
                  (s) => s.bookshelveName?.toLowerCase().contains('yêu thích') ?? false,
              orElse: () => bookshelves.first,
            );
            final shelfId = favoriteShelf.bookshelveId ?? '';

            // Decide which future to watch
            final booksAsync = _selectedTab == 0
                ? ref.watch(booksByShelfProvider(shelfId))
                : ref.watch(myBooksProvider);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tab selector
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedTab = 0);
                          _fetchBooks(ref, shelfId: shelfId, reset: true);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: _selectedTab == 0
                                ? const LinearGradient(
                              colors: [Color(0xFF814BF6), Color(0xFFBD4EFF)],
                            )
                                : const LinearGradient(
                              colors: [Color(0xFF1C2942), Color(0xFF1C2942)],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Sách yêu thích',
                              style: TextStyle(
                                color: _selectedTab == 0 ? Colors.white : Colors.white54,
                                fontWeight: _selectedTab == 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedTab = 1);
                          _fetchBooks(ref, reset: true);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: _selectedTab == 1
                                ? const LinearGradient(
                              colors: [Color(0xFF814BF6), Color(0xFFBD4EFF)],
                            )
                                : const LinearGradient(
                              colors: [Color(0xFF1C2942), Color(0xFF1C2942)],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Sách của bạn',
                              style: TextStyle(
                                color: _selectedTab == 1 ? Colors.white : Colors.white54,
                                fontWeight: _selectedTab == 1
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search bar
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
                          onSubmitted: (_) =>
                              _fetchBooks(ref, shelfId: shelfId, reset: true),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.white70),
                        onPressed: () =>
                            _fetchBooks(ref, shelfId: shelfId, reset: true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: booksAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    error: (e, _) => Center(
                      child: Text('Lỗi tải sách: $e',
                          style: const TextStyle(color: Colors.redAccent)),
                    ),
                    data: (books) {
                      if (_pagedBooks.isEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback(
                              (_) => _fetchBooks(ref, shelfId: shelfId),
                        );
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }

                      if (_pagedBooks.isEmpty) {
                        return const Center(
                          child: Text('Không có sách nào.',
                              style: TextStyle(color: Colors.white70)),
                        );
                      }

                      return Column(
                        children: [
                          Expanded(
                            child: GridView.builder(
                              gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.6,
                              ),
                              itemCount: _pagedBooks.length,
                              itemBuilder: (_, i) {
                                final book = _pagedBooks[i];
                                final author =
                                ref.watch(userByIdProvider(book.authorId ?? ''));

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
                            ),
                          ),

                          // Pagination controls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: _hasPrevious
                                    ? () => _firstPage(ref, shelfId: shelfId)
                                    : null,
                                icon: const Icon(Icons.first_page),
                                color: Colors.white70,
                              ),
                              IconButton(
                                onPressed: _hasPrevious
                                    ? () => _previousPage(ref, shelfId: shelfId)
                                    : null,
                                icon: const Icon(Icons.chevron_left),
                                color: Colors.white70,
                              ),
                              Text(
                                'Trang ${_currentPage + 1}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                              ),
                              IconButton(
                                onPressed: _hasNext
                                    ? () => _nextPage(ref, shelfId: shelfId)
                                    : null,
                                icon: const Icon(Icons.chevron_right),
                                color: Colors.white70,
                              ),
                              IconButton(
                                onPressed: _hasNext
                                    ? () => _nextPage(ref, shelfId: shelfId)
                                    : null,
                                icon: const Icon(Icons.last_page),
                                color: Colors.white70,
                              ),
                            ],
                          ),
                        ],
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
