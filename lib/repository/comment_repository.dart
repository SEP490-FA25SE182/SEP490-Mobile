import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/comment.dart';
import '../provider.dart';

class CommentRepository {
  final Dio _dio;
  CommentRepository(this._dio);

  Future<Comment> create({
    required String blogId,
    String? userId,
    String? name,
    required String content,
    bool isPublished = true,
  }) async {
    final body = <String, dynamic>{
      'blogId': blogId,
      'userId': userId,
      'name': name,
      'content': content,
      'isPublished': isPublished,
      'isActived': 'ACTIVE',
    }..removeWhere((_, v) => v == null);

    final res = await _dio.post('/api/rookie/users/comments', data: body);
    return Comment.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<Comment> update(
      String id, {
        String? blogId,
        String? userId,
        String? content,
        bool? isPublished,
        String? name,
      }) async {
    final body = <String, dynamic>{
      if (blogId != null) 'blogId': blogId,
      if (userId != null) 'userId': userId,
      'content': content,
      'isPublished': isPublished,
      'name': name,
      'isActived': 'ACTIVE',
    }..removeWhere((_, v) => v == null);

    final res = await _dio.put('/api/rookie/users/comments/$id', data: body);
    return Comment.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<int> countPublishedByBlog(String blogId) async {
    final res = await _dio.get('/api/rookie/users/comments/count', queryParameters: {
      'blogId': blogId,
      'onlyPublished': true,
    });
    final data = (res.data as Map).cast<String, dynamic>();
    final c = data['count'];
    return c is int ? c : int.tryParse('$c') ?? 0;
  }

  Future<List<Comment>> getByBlogId(String blogId) async {
    final res = await _dio.get('/api/rookie/users/comments/by-blog/$blogId');
    final raw = res.data;
    final list = (raw is List) ? raw : <dynamic>[];
    return list
        .whereType<Map>()
        .map((e) => Comment.fromJson(e.cast<String, dynamic>()))
        .toList();
  }
}


