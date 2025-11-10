import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../model/book.dart';
import '../../repository/order_repository.dart';
import 'favorite_books_tab.dart';
import 'my_books_tab.dart';

class BookshelvePage extends ConsumerStatefulWidget {
  const BookshelvePage({super.key});

  @override
  ConsumerState<BookshelvePage> createState() => _BookshelvePageState();
}

class _BookshelvePageState extends ConsumerState<BookshelvePage> {
  int _selectedTab = 0;

  final favoriteBooksPageIndexProvider = StateProvider<int>((_) => 0);

  @override
  Widget build(BuildContext context) {
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
      body: Column(
        children: [
          const SizedBox(height: 8),

          // Tab selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: _tabItem('Sách yêu thích', _selectedTab == 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: _tabItem('Sách của bạn', _selectedTab == 1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tab content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _selectedTab == 0
                  ? FavoriteBooksTab(
                key: const ValueKey('fav'),
                onPageChange: (delta) {
                  ref
                      .read(favoriteBooksPageIndexProvider.notifier)
                      .update((state) => state + delta);
                },
              )
                  : const MyBooksTab(key: ValueKey('mine')),
            ),
          ),

          // PHÂN TRANG CHỈ HIỆN KHI Ở TAB "SÁCH CỦA BẠN"
          Consumer(
            builder: (context, ref, _) {
              if (_selectedTab == 0) {
                // Favorite tab: dùng page index cũ (nếu cần)
                final page = ref.watch(favoriteBooksPageIndexProvider);
                return _buildOldPagination(page, ref, isFavorite: true);
              }

              // My Books tab: dùng phân trang thật từ API
              final asyncPage = ref.watch(myBooksProvider);
              return asyncPage.when(
                data: (page) => _buildRealPagination(page, ref),
                loading: () => const SizedBox(height: 50),
                error: (_, __) => const SizedBox(height: 50),
              );
            },
          ),
        ],
      ),
    );
  }

  // Pagination cho Favorite tab (giữ nguyên như cũ)
  Widget _buildOldPagination(int page, WidgetRef ref, {required bool isFavorite}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.first_page, color: Colors.white70),
            onPressed: page > 0
                ? () => ref.read(favoriteBooksPageIndexProvider.notifier).state = 0
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white70),
            onPressed: page > 0
                ? () => ref.read(favoriteBooksPageIndexProvider.notifier).state--
                : null,
          ),
          Text(
            'Trang ${page + 1}',
            style: const TextStyle(color: Colors.white),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white70),
            onPressed: () {
              ref.read(favoriteBooksPageIndexProvider.notifier).state++;
            },
          ),
          IconButton(
            icon: const Icon(Icons.last_page, color: Colors.white70),
            onPressed: null, // chưa biết tổng trang
          ),
        ],
      ),
    );
  }

  // Pagination cho My Books tab (dùng dữ liệu thật từ API)
  Widget _buildRealPagination(PageResponse<Book> page, WidgetRef ref) {
    if (page.totalPages <= 1) {
      return const SizedBox(height: 50);
    }

    final currentState = ref.read(myBooksStateProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.first_page, color: Colors.white70),
            onPressed: page.page > 0
                ? () => ref.read(myBooksStateProvider.notifier).state =
                currentState.copyWith(page: 0)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white70),
            onPressed: page.page > 0
                ? () => ref.read(myBooksStateProvider.notifier).state =
                currentState.copyWith(page: page.page - 1)
                : null,
          ),
          Text(
            'Trang ${page.page + 1} / ${page.totalPages}',
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white70),
            onPressed: !page.isLast
                ? () => ref.read(myBooksStateProvider.notifier).state =
                currentState.copyWith(page: page.page + 1)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.last_page, color: Colors.white70),
            onPressed: !page.isLast
                ? () => ref.read(myBooksStateProvider.notifier).state =
                currentState.copyWith(page: page.totalPages - 1)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _tabItem(String text, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: isActive
            ? const LinearGradient(colors: [Color(0xFF814BF6), Color(0xFFBD4EFF)])
            : const LinearGradient(colors: [Color(0xFF1C2942), Color(0xFF1C2942)]),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white54,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}