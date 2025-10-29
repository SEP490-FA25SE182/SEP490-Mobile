import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../model/book.dart';
import '../provider.dart';
import '../repository/book_repository.dart';
import '../widget/gs_image.dart';
import 'book/book_detail_page.dart';

final bookListProvider =
StateNotifierProvider<BookListNotifier, AsyncValue<List<Book>>>(
      (ref) => BookListNotifier(ref.watch(bookRepoProvider)),
);

class BookListNotifier extends StateNotifier<AsyncValue<List<Book>>> {
  final BookRepository _repo;
  List<Book> _allBooks = [];

  BookListNotifier(this._repo) : super(const AsyncLoading()) {
    _fetchBooks();
  }

  Future<void> _fetchBooks() async {
    try {
      final books = await _repo.list(sort: 'createdAt-desc');
      _allBooks = books;
      state = AsyncData(books);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void search(String query) {
    if (query.isEmpty) {
      state = AsyncData(_allBooks);
    } else {
      final lower = query.toLowerCase();
      final filtered = _allBooks
          .where((b) => b.bookName.toLowerCase().contains(lower))
          .toList();
      state = AsyncData(filtered);
    }
  }
}

class BookListPage extends ConsumerWidget {
  const BookListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(bookListProvider);
    final notifier = ref.read(bookListProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF09121F),
      appBar: AppBar(
        title: const Text('Danh sách sách'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0E2A47),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/');
          },
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            //Thanh tìm kiếm
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
              onChanged: notifier.search,
            ),
            const SizedBox(height: 16),

            //Danh sách sách dạng lưới
            Expanded(
              child: books.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.white)),
                error: (e, _) => Center(
                  child: Text('Lỗi: $e',
                      style: const TextStyle(color: Colors.redAccent)),
                ),
                data: (list) => list.isEmpty
                    ? const Center(
                    child: Text('Không có sách nào.',
                        style: TextStyle(color: Colors.white70)))
                    : GridView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.62, // tỉ lệ ảnh bìa
                  ),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final book = list[i];
                    final author =
                    ref.watch(userByIdProvider(book.authorId ?? ''));

                    return GestureDetector(
                      onTap: () {
                        context.push('/books/${book.bookId}');
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //Ảnh bìa
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

                          // Tên sách
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

                          // Tên tác giả
                          author.when(
                            data: (user) => Text(
                              user.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                            loading: () => const Text(
                              'Đang tải...',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 12),
                            ),
                            error: (_, __) => const Text(
                              'Không rõ tác giả',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
