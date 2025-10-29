import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../model/book.dart';
import '../provider.dart';
import '../repository/book_repository.dart';
import '../widget/gs_image.dart';

/// --- PROVIDER + STATE ---
final bookListProvider =
StateNotifierProvider<BookListNotifier, AsyncValue<List<Book>>>(
      (ref) => BookListNotifier(ref.watch(bookRepoProvider)),
);

class BookListNotifier extends StateNotifier<AsyncValue<List<Book>>> {
  final BookRepository _repo;

  // Pagination & Filters
  int _currentPage = 0;
  static const int _pageSize = 20;
  bool _hasNext = true;
  bool _hasPrevious = false;
  String _searchQuery = '';
  String? _genreId;
  List<Book> _books = [];

  BookListNotifier(this._repo) : super(const AsyncLoading()) {
    fetchBooks();
  }

  Future<void> fetchBooks({bool reset = false}) async {
    try {
      if (reset) {
        _currentPage = 0;
        _books.clear();
        _hasNext = true;
        _hasPrevious = false;
        state = const AsyncLoading();
      }

      final newBooks = await _repo.list(
        page: _currentPage,
        size: _pageSize,
        search: _searchQuery,
        genreId: _genreId,
        sort: 'createdAt-desc',
      );

      _books = newBooks;
      _hasNext = newBooks.length == _pageSize;
      _hasPrevious = _currentPage > 0;

      state = AsyncData(List.from(_books));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void nextPage() {
    if (_hasNext) {
      _currentPage++;
      fetchBooks();
    }
  }

  void previousPage() {
    if (_hasPrevious && _currentPage > 0) {
      _currentPage--;
      fetchBooks();
    }
  }

  void firstPage() {
    if (_currentPage != 0) {
      _currentPage = 0;
      fetchBooks();
    }
  }

  void lastPage() async {
    // Optional: only works if backend provides total count (can extend later)
  }

  void search(String query) {
    _searchQuery = query.trim();
    fetchBooks(reset: true);
  }

  void filterByGenre(String? genreId) {
    _genreId = genreId;
    fetchBooks(reset: true);
  }

  int get currentPage => _currentPage;
  bool get hasNext => _hasNext;
  bool get hasPrevious => _hasPrevious;
}

/// --- UI PAGE ---
class BookListPage extends ConsumerWidget {
  const BookListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(bookListProvider);
    final notifier = ref.read(bookListProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF09121F),
      appBar: AppBar(
        title: const Text('Danh sách'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0E2A47),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// --- SEARCH BAR ---
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sách...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF18223A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: notifier.search,
            ),
            const SizedBox(height: 12),

            /// --- FILTER DROPDOWN (THỂ LOẠI) ---
            _GenreFilterDropdown(onChanged: notifier.filterByGenre),
            const SizedBox(height: 16),

            /// --- BOOK GRID ---
            Expanded(
              child: booksAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Lỗi: $e',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
                data: (books) {
                  if (books.isEmpty) {
                    return const Center(
                      child: Text(
                        'Không có sách nào.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 20,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.62,
                          ),
                          itemCount: books.length,
                          itemBuilder: (_, i) {
                            final book = books[i];
                            final author = ref.watch(
                                userByIdProvider(book.authorId ?? ''));

                            return GestureDetector(
                              onTap: () =>
                                  context.push('/books/${book.bookId}'),
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

                      /// --- PAGINATION BUTTONS ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: notifier.hasPrevious
                                ? notifier.firstPage
                                : null,
                            icon: const Icon(Icons.first_page),
                            color: Colors.white70,
                          ),
                          IconButton(
                            onPressed: notifier.hasPrevious
                                ? notifier.previousPage
                                : null,
                            icon: const Icon(Icons.chevron_left),
                            color: Colors.white70,
                          ),
                          Text(
                            'Trang ${notifier.currentPage + 1}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                          IconButton(
                            onPressed: notifier.hasNext
                                ? notifier.nextPage
                                : null,
                            icon: const Icon(Icons.chevron_right),
                            color: Colors.white70,
                          ),
                          IconButton(
                            onPressed: notifier.hasNext
                                ? notifier.nextPage
                                : null, // Placeholder for ">>"
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
        ),
      ),
    );
  }
}

/// --- GENRE FILTER DROPDOWN ---
class _GenreFilterDropdown extends ConsumerWidget {
  final ValueChanged<String?> onChanged;

  const _GenreFilterDropdown({required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genresAsync = ref.watch(genresProvider);

    return genresAsync.when(
      loading: () => const SizedBox(),
      error: (e, _) => const SizedBox(),
      data: (genres) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF18223A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              dropdownColor: const Color(0xFF18223A),
              iconEnabledColor: Colors.white70,
              value: null,
              hint: const Text(
                'Lọc theo thể loại',
                style: TextStyle(color: Colors.white70),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Tất cả', style: TextStyle(color: Colors.white)),
                ),
                ...genres.map(
                      (g) => DropdownMenuItem<String?>(
                    value: g.genreId,
                    child: Text(
                      g.genreName,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
              onChanged: onChanged,
            ),
          ),
        );
      },
    );
  }
}
