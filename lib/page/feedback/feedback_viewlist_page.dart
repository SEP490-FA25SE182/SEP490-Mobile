import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../model/feedback.dart';
import '../../provider.dart';

/// Provider: Load PUBLISHED feedbacks (paginated)
final feedbackListProvider = FutureProvider.family<List<BookFeedback>, (String bookId, int page)>(
      (ref, args) async {
    final (bookId, page) = args;
    final repo = ref.read(feedbackRepoProvider);
    return repo.search(
      bookId: bookId,
      isActived: IsActived.active,
      status: FeedbackStatus.published,
      page: page,
      size: 10,
      sort: ['createdAt-desc'],
    );
  },
);

class FeedbackViewListPage extends ConsumerStatefulWidget {
  final String bookId;
  final String bookName;

  const FeedbackViewListPage({
    super.key,
    required this.bookId,
    required this.bookName,
  });

  @override
  ConsumerState<FeedbackViewListPage> createState() => _FeedbackViewListPageState();
}

class _FeedbackViewListPageState extends ConsumerState<FeedbackViewListPage> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  final List<BookFeedback> _feedbacks = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadFeedbacks(page: 0);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9 &&
          !_isLoadingMore &&
          _hasMore) {
        _loadMore();
      }
    });
  }

  /// Load feedbacks using .future
  Future<void> _loadFeedbacks({int page = 0}) async {
    if (page == 0) {
      setState(() {
        _feedbacks.clear();
        _currentPage = 0;
        _hasMore = true;
      });
    }

    try {
      final feedbacks = await ref.read(feedbackListProvider((widget.bookId, page)).future);

      setState(() {
        if (page == 0) {
          _feedbacks.clear();
        }
        _feedbacks.addAll(feedbacks);
        _currentPage = page;
        _hasMore = feedbacks.length == 10;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
      print('Error loading feedbacks: $e');
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    await _loadFeedbacks(page: _currentPage + 1);
  }

  Future<void> _onRefresh() => _loadFeedbacks(page: 0);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFF09121F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E2A47),
        title: Text(
          'Đánh giá: ${widget.bookName}',
          style: const TextStyle(fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _feedbacks.isEmpty && !_isLoadingMore
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _onRefresh,
        color: const Color(0xFF5B6CF3),
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: _feedbacks.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _feedbacks.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                ),
              );
            }

            final feedback = _feedbacks[index];
            return _buildFeedbackItem(feedback, dateFormat);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.rate_review_outlined, size: 64, color: Colors.white38),
          SizedBox(height: 16),
          Text('Chưa có đánh giá nào', style: TextStyle(color: Colors.white70, fontSize: 16)),
          SizedBox(height: 8),
          Text('Hãy là người đầu tiên đánh giá!', style: TextStyle(color: Colors.white54, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildFeedbackItem(BookFeedback feedback, DateFormat dateFormat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF18223A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A344A), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF5B6CF3),
                child: Text(
                  feedback.userId.length >= 2 ? feedback.userId.substring(0, 2).toUpperCase() : '??',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User ${feedback.userId.length >= 8 ? feedback.userId.substring(0, 8) : feedback.userId}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      dateFormat.format(feedback.createdAt),
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < feedback.rating ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFFD700),
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (feedback.content?.trim().isNotEmpty == true)
            Text(
              feedback.content!,
              style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            )
          else
            const Text(
              'Không có bình luận',
              style: TextStyle(color: Colors.white38, fontStyle: FontStyle.italic, fontSize: 13),
            ),
        ],
      ),
    );
  }
}