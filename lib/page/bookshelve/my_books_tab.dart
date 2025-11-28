import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/book.dart';
import '../../provider.dart';
import '../../repository/order_repository.dart';
import '../../style/button.dart';
import '../../widget/gs_image.dart';
import 'package:go_router/go_router.dart';

// State cho My Books: search + page
final myBooksStateProvider = StateProvider<MyBooksState>((ref) {
  final userId = ref.watch(currentUserIdProvider) ?? '';
  return MyBooksState(userId: userId);
});

class MyBooksState {
  final String userId;
  final String query;
  final int page;

  MyBooksState({required this.userId, this.query = '', this.page = 0});

  MyBooksState copyWith({String? query, int? page}) {
    return MyBooksState(
      userId: userId,
      query: query ?? this.query,
      page: page ?? this.page,
    );
  }
}

// Provider chính – giống như booksByShelfProvider
final myBooksProvider = FutureProvider<PageResponse<Book>>((ref) async {
  final state = ref.watch(myBooksStateProvider);
  if (state.userId.isEmpty) return PageResponse.empty();

  final repo = ref.read(orderRepositoryProvider);
  return repo.getPurchasedBooks(
    userId: state.userId,
    q: state.query.isEmpty ? null : state.query,
    sort: 'updatedAt-desc',
    page: state.page,
    size: 20,
  );
});

class MyBooksTab extends ConsumerWidget {
  final void Function(int delta)? onPageChange;
  const MyBooksTab({super.key, this.onPageChange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myBooksStateProvider);
    final booksAsync = ref.watch(myBooksProvider);

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Tìm trong sách của bạn...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              filled: true,
              fillColor: const Color(0xFF1C2942),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              ref.read(myBooksStateProvider.notifier).state =
                  state.copyWith(query: value, page: 0);
            },
          ),
        ),

        // Nút Scan
        // ButtonSoft(
        //   text: 'Scan',
        //   onTap: () async {
        //     final result = await context.push<String>('/scan');
        //     if (result != null && result.isNotEmpty && context.mounted) {
        //       ScaffoldMessenger.of(context).showSnackBar(
        //         SnackBar(content: Text('Đã quét: $result')),
        //       );
        //     }
        //   },
        // ),
        ButtonSoft(
          text: 'Scan',
          onTap: () async {
            context.go('/unity');
          },
        ),

        // Content
        Expanded(
          child: booksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Lỗi: $e', style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            data: (page) {
              if (page.content.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.menu_book_outlined, size: 80, color: Colors.white54),
                      const SizedBox(height: 16),
                      const Text('Bạn chưa mua sách nào', style: TextStyle(color: Colors.white70, fontSize: 16)),
                      const Text('Khám phá ngay!', style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: Colors.white,
                backgroundColor: const Color(0xFF0E2A47),
                onRefresh: () async => ref.invalidate(myBooksProvider),
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.6,
                  ),
                  itemCount: page.content.length,
                  itemBuilder: (_, i) {
                    final book = page.content[i];
                    return GestureDetector(
                      onTap: () => context.push('/show/${book.bookId}'),
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
          ),
        ),
      ],
    );
  }
}