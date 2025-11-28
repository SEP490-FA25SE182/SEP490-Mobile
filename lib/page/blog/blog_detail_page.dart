import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../provider.dart';
import '../../model/blog.dart';
import '../../screen/nav_bottom_screen.dart';
import '../../widget/gs_image.dart';
import 'blog_comment_page.dart';

class BlogDetailPage extends ConsumerWidget {
  final String blogId;
  const BlogDetailPage({super.key, required this.blogId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blogAsync = ref.watch(blogByIdProvider(blogId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0E2A47), Color(0xFF09121F)],
          ),
        ),
        child: blogAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('Lỗi tải blog: $e', style: const TextStyle(color: Colors.redAccent)),
          ),
          data: (blog) => _DetailBody(blog: blog),
        ),
      ),
      bottomNavigationBar: const NavBottomBar(currentIndex: 0),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  final Blog blog;
  const _DetailBody({required this.blog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authorId = blog.authorId ?? '';
    final authorAsync = (authorId.isNotEmpty)
        ? ref.watch(userByIdProvider(authorId))
        : const AsyncValue.loading();

    final cover = blog.coverImageUrl;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Stack(
            children: [
              // Cover
              AspectRatio(
                aspectRatio: 16/9,
                child: (cover != null && cover.isNotEmpty)
                    ? GsImage(url: cover, fit: BoxFit.cover)
                    : Container(color: const Color(0x225B6CF3)),
              ),
              // Back
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                child: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ],
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: authorAsync.when(
              loading: () => const SizedBox(height: 28),
              error: (_, __) => const SizedBox.shrink(),
              data: (u) => Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white10,
                    child: ClipOval(
                      child: SizedBox(
                        width: 32, height: 32,
                        child: GsImage(url: (u.avatarUrl ?? ''), fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(u.fullName,
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),

        // Title
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Text(
              blog.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                height: 1.25,
              ),
            ),
          ),
        ),

        // Divider
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Divider(color: Colors.white24, height: 1),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              (blog.content ?? '').trim().isEmpty ? '—' : blog.content!,
              style: const TextStyle(color: Colors.white70, height: 1.45),
            ),
          ),
        ),

        // Tags (#tag)
        SliverToBoxAdapter(
          child: (blog.tagNames.isEmpty)
              ? const SizedBox(height: 18)
              : Padding(
            padding: const EdgeInsets.fromLTRB(16, 30, 16, 24),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: blog.tagNames.map((t) {
                final label = t.trim();
                if (label.isEmpty) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0x225B6CF3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24, width: .8),
                  ),
                  child: Text('$label', style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: BlogCommentSection(blogId: blog.blogId),
        ),
      ],
    );
  }
}
