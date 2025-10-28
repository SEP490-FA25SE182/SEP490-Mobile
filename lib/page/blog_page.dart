import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screen/nav_bottom_screen.dart';
import '../widget/gs_image.dart';
import '../model/blog.dart';
import '../repository/blog_repository.dart';
import '../provider.dart';

/// state
final _orderProvider      = StateProvider<UpdatedOrder>((_) => UpdatedOrder.latest);
final _showSearchProvider = StateProvider<bool>((_) => false);
final _searchTextProvider = StateProvider<String>((_) => '');

class BlogPage extends ConsumerWidget {
  const BlogPage({super.key});

  static const _searchIcon = 'gs://sep490-fa25se182.firebasestorage.app/icon/search.png';
  static const _filterIcon = 'gs://sep490-fa25se182.firebasestorage.app/icon/filter.png';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showSearch = ref.watch(_showSearchProvider);
    final order = ref.watch(_orderProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,

        title: showSearch
            ? null
            : const Text('Blog', style: TextStyle(fontWeight: FontWeight.w800)),

        actions: showSearch
            ? [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => ref.read(_showSearchProvider.notifier).state = false,
            tooltip: 'Đóng',
          ),
          const SizedBox(width: 6),
        ]
            : [
          IconButton(
            onPressed: () => ref.read(_showSearchProvider.notifier).state = true,
            icon: SizedBox(width: 22, height: 22,
                child: GsImage(url: _searchIcon)),
            tooltip: 'Tìm kiếm',
          ),
          IconButton(
            onPressed: () => _pickOrder(context, ref),
            icon: SizedBox(width: 22, height: 22,
                child: GsImage(url: _filterIcon)),
            tooltip: 'Lọc',
          ),
          const SizedBox(width: 6),
        ],

        bottom: showSearch
            ? const PreferredSize(
          preferredSize: Size.fromHeight(52),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _SearchBar(),
          ),
        )
            : null,
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0E2A47), Color(0xFF09121F)],
          ),
        ),
        child: Column(
          children: [
            // Header: label theo filter
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: Row(
                children: [
                  Text(
                    order == UpdatedOrder.latest ? 'Mới nhất' : 'Cũ nhất',
                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            const Expanded(child: _BlogList()),
          ],
        ),
      ),
      bottomNavigationBar: const NavBottomBar(currentIndex: 1),
    );
  }


  Future<void> _pickOrder(BuildContext context, WidgetRef ref) async {
    final cur = ref.read(_orderProvider);
    final v = await showModalBottomSheet<UpdatedOrder>(
      context: context,
      backgroundColor: const Color(0xFF141B29),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<UpdatedOrder>(
              value: UpdatedOrder.latest,
              groupValue: cur,
              onChanged: (v) => Navigator.pop(context, v),
              title: const Text('Mới nhất', style: TextStyle(color: Colors.white)),
            ),
            RadioListTile<UpdatedOrder>(
              value: UpdatedOrder.oldest,
              groupValue: cur,
              onChanged: (v) => Navigator.pop(context, v),
              title: const Text('Cũ nhất', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
    if (v != null) ref.read(_orderProvider.notifier).state = v;
  }
}

/// Ô tìm kiếm
class _SearchBar extends ConsumerStatefulWidget {
  const _SearchBar();

  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: ref.read(_searchTextProvider));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    ref.read(_searchTextProvider.notifier).state = _ctrl.text.trim();
    // Ẩn thanh search sau khi submit
    ref.read(_showSearchProvider.notifier).state = false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0x1FFFFFFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _ctrl,
              onSubmitted: (_) => _submit(),
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm theo tác giả, tiêu đề, hashtag',
                hintStyle: TextStyle(color: Colors.white60),
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white70),
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

/// Danh sách blog
class _BlogList extends ConsumerWidget {
  const _BlogList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order   = ref.watch(_orderProvider);
    final keyword = ref.watch(_searchTextProvider);
    final repo    = ref.read(blogRepoProvider);

    return FutureBuilder<({List<Blog> items, int total})>(
      future: _load(repo, keyword, order),
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Text(
              'Lỗi tải blog: ${snap.error}',
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
          );
        }
        final data = snap.data!;
        if (data.items.isEmpty) {
          return const Center(
            child: Text('Không có blog phù hợp', style: TextStyle(color: Colors.white70)),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 18),
          itemCount: data.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _BlogTile(blog: data.items[i]),
        );
      },
    );
  }

  Future<({List<Blog> items, int total})> _load(
      BlogRepository repo,
      String keyword,
      UpdatedOrder order,
      ) {
    if (keyword.isEmpty) {
      // không search -> lọc theo mới nhất/cũ nhất
      return repo.filterByUpdated(order: order);
    }
    // search
    return repo.searchForUser(q: keyword);
  }
}

/// Item tile
class _BlogTile extends StatelessWidget {
  final Blog blog;
  const _BlogTile({required this.blog});

  @override
  Widget build(BuildContext context) {
    final imgUrl = blog.coverImageUrl;
    return InkWell(
      onTap: () => context.push('/blogs/${blog.blogId}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 80,
              height: 100,
              child: (imgUrl != null && imgUrl.isNotEmpty)
                  ? GsImage(url: imgUrl, fit: BoxFit.cover)
                  : Container(color: const Color(0x225B6CF3)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              blog.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

