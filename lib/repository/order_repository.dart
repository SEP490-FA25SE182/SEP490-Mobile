import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/book.dart';
import '../model/order.dart';
import '../provider.dart';

class OrderRepository {
  final Dio _dio;
  OrderRepository(this._dio);

  /// POST /api/rookie/users/orders/from-cart/{cartId}/wallet/{walletId}?usePoints={bool}
  /// Body: ["cartItemId-1", "cartItemId-2", ...]
  Future<Order> moveCartToOrder({
    required String cartId,
    required String walletId,
    required List<String> cartItemIds,
    bool usePoints = false,
  }) async {
    final url = '/api/rookie/users/orders/from-cart/$cartId/wallet/$walletId';
    final res = await _dio.post(
      url,
      queryParameters: {'usePoints': usePoints},
      data: cartItemIds, // gửi list id xuống BE
      options: Options(contentType: Headers.jsonContentType),
    );
    return Order.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<Order> getById(String id) async {
    final res = await _dio.get('/api/rookie/users/orders/$id');
    print(res.data);
    return Order.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<List<Order>> getByCartId(String cartId) async {
    final res = await _dio.get('/api/rookie/users/orders/cart/$cartId');
    final raw = res.data;
    final items = (raw is List) ? raw : <dynamic>[];
    return items
        .whereType<Map>()
        .map((e) => Order.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<List<Order>> getByWalletId(String walletId) async {
    final res = await _dio.get('/api/rookie/users/orders/wallet/$walletId');
    final raw = res.data;
    final items = (raw is List) ? raw : <dynamic>[];
    return items
        .whereType<Map>()
        .map((e) => Order.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  /// GET SEARCH
  Future<List<Order>> search({
    required String userId,
    String? status,
    int page = 0,
    int size = 20,
  }) async {
    final res = await _dio.get(
      '/api/rookie/users/orders/search',
      queryParameters: <String, dynamic>{
        'userId': userId,
        if (status != null) 'status': status,
        'page': page,
        'size': size,
      },
    );

    final data = res.data;

    final List items;
    if (data is Map && data['content'] is List) {
      items = data['content'] as List;
    } else if (data is List) {
      items = data;
    } else {
      items = const <dynamic>[];
    }

    return items
        .whereType<Map>()
        .map((e) => Order.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  /// PUT /api/rookie/users/orders/{id}
  Future<Order> update(
      String id, {
        int? amount,
        double? totalPrice,
        int? status,
        String? userAddressId,
        String? reason,
        String? imageUrl,
      }) async {
    final body = <String, dynamic>{
      'amount': amount,
      'totalPrice': totalPrice,
      'status': status,
      'userAddressId': userAddressId,
      'reason': reason,
      'imageUrl'  : imageUrl,
    }..removeWhere((_, v) => v == null);

    final res = await _dio.put(
      '/api/rookie/users/orders/$id',
      data: body,
      options: Options(contentType: Headers.jsonContentType),
    );
    return Order.fromJson((res.data as Map).cast<String, dynamic>());
  }


  Future<PageResponse<Book>> getPurchasedBooks({
    required String userId,
    String? q,
    String? sort,
    String? genreId,
    String? bookshelfId,
    int page = 0,
    int size = 20,
    String? status,
  }) async {
    try {
      print('Fetching purchased books: user=$userId, q=$q, sort=$sort');

      final response = await _dio.get(
        '/api/rookie/users/orders/purchased-books',
        queryParameters: <String, dynamic>{
          'userId': userId,
          'page': page,
          'size': size,
          'status': status ?? 'RECEIVED',
          if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
          if (sort != null && sort.trim().isNotEmpty) 'sort': sort.trim(),
          if (genreId != null && genreId.trim().isNotEmpty) 'genreId': genreId.trim(),
          if (bookshelfId != null && bookshelfId.trim().isNotEmpty) 'bookshelfId': bookshelfId.trim(),
        },
      );

      final data = response.data as Map<String, dynamic>;
      final List<Book> books = (data['content'] as List)
          .map((item) => Book.fromJson(item as Map<String, dynamic>))
          .toList();

      return PageResponse<Book>(
        content: books,
        totalElements: data['totalElements'] as int? ?? books.length,
        totalPages: data['totalPages'] as int? ?? 1,
        page: data['number'] as int? ?? page,
        size: data['size'] as int? ?? size,
        isLast: data['last'] as bool? ?? true,
      );
    } catch (e, st) {
      print('[OrderRepo] Error fetching purchased books: $e\n$st');
      return PageResponse<Book>(
        content: [],
        totalElements: 0,
        totalPages: 0,
        page: page,
        size: size,
        isLast: true,
      );
    }
  }

  Future<List<Book>> getPurchasedBooksSimple({
    required String userId,
    String? q,
    String? sort,
    String? status,
  }) async {
    final page = await getPurchasedBooks(
      userId: userId,
      q: q,
      sort: sort,
      page: 0,
      size: 999,
      status: status ?? 'RECEIVED',
    );
    return page.content;
  }
}

class PageResponse<T> {
  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int page;
  final int size;
  final bool isLast;

  PageResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.page,
    required this.size,
    required this.isLast,
  });

  factory PageResponse.empty() => PageResponse<T>(
    content: [],
    totalElements: 0,
    totalPages: 0,
    page: 0,
    size: 20,
    isLast: true,
  );
}


