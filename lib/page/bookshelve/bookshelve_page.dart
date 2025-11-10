import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  final myBooksPageIndexProvider = StateProvider<int>((_) => 0);

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
                onPageChange: (pageDelta) {
                  ref
                      .read(favoriteBooksPageIndexProvider.notifier)
                      .update((state) => state + pageDelta);
                },
              )
                  : MyBooksTab(
                key: const ValueKey('mine'),
                onPageChange: (pageDelta) {
                  ref
                      .read(myBooksPageIndexProvider.notifier)
                      .update((state) => state + pageDelta);
                },
              ),
            ),
          ),

          // Pagination buttons
          Consumer(
            builder: (context, ref, _) {
              final isFavoriteTab = _selectedTab == 0;
              final page = isFavoriteTab
                  ? ref.watch(favoriteBooksPageIndexProvider)
                  : ref.watch(myBooksPageIndexProvider);

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.first_page, color: Colors.white70),
                      onPressed: page > 0
                          ? () {
                        if (isFavoriteTab) {
                          ref
                              .read(favoriteBooksPageIndexProvider.notifier)
                              .state = 0;
                        } else {
                          ref
                              .read(myBooksPageIndexProvider.notifier)
                              .state = 0;
                        }
                      }
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white70),
                      onPressed: page > 0
                          ? () {
                        if (isFavoriteTab) {
                          ref
                              .read(favoriteBooksPageIndexProvider.notifier)
                              .state--;
                        } else {
                          ref
                              .read(myBooksPageIndexProvider.notifier)
                              .state--;
                        }
                      }
                          : null,
                    ),
                    Text(
                      'Trang ${page + 1}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.white70),
                      onPressed: () {
                        if (isFavoriteTab) {
                          ref
                              .read(favoriteBooksPageIndexProvider.notifier)
                              .state++;
                        } else {
                          ref
                              .read(myBooksPageIndexProvider.notifier)
                              .state++;
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.last_page, color: Colors.white70),
                      onPressed: () {
                        // optionally jump to last page (you can enhance if total known)
                      },
                    ),
                  ],
                ),
              );
            },
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
