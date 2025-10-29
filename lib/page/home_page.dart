import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widget/gs_image.dart';
import '../provider.dart';
import '../model/book.dart';
import '../screen/new_book_screen.dart';
import '../screen/nav_bottom_screen.dart';

final booksProvider = FutureProvider<List<Book>>((ref) async {
  return ref.watch(bookRepoProvider).list(sort: '');
});

final newestBooksProvider = FutureProvider<List<Book>>((ref) async {
  return ref.watch(bookRepoProvider).newestBooks(limit: 5);
});

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(newestBooksProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          _circleIcon(Icons.search),
          const SizedBox(width: 8),
          _circleIcon(Icons.notifications_none),
          const SizedBox(width: 12),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0E2A47), Color(0xFF09121F)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: books.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (e, _) => Center(
                  child: Text(
                    'Error: $e',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
            data: (list) {
              // Banner tĩnh trong Storage
              const bannerGs =
                  'gs://sep490-fa25se182.firebasestorage.app/banner/banner.png';

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  const Text(
                    'Khám phá',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 16),

                  // Dải cover nhỏ
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const spacing = 12.0;
                      final itemWidth = (constraints.maxWidth - spacing * 3) / 4;

                      return SizedBox(
                        height: 110,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: min(5, list.length),
                          separatorBuilder: (_, __) =>
                          const SizedBox(width: spacing),
                          itemBuilder: (_, i) {
                            final book = list[i];
                            return GestureDetector(
                              onTap: () {
                                //Navigate to detail
                                context.push('/books/${book.bookId}');
                              },
                              child: SizedBox(
                                width: itemWidth,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: AspectRatio(
                                    aspectRatio: 9 / 14,
                                    child: GsImage(
                                        url: book.coverUrl, fit: BoxFit.cover),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Banner lớn
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: GsImage(url: bannerGs, fit: BoxFit.cover),
                    ),
                  ),

                  const SizedBox(height: 24),
                  NewBooksSection(books: list),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: const NavBottomBar(currentIndex: 0),
    );
  }

  static Widget _circleIcon(IconData icon) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFF18223A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}
