import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'core/config.dart';
import 'core/api_client.dart';
import 'core/secure_store.dart';
import 'repository/auth_repository.dart';
import 'repository/book_repository.dart';
import 'repository/user_repository.dart';

// Config & core
final configProvider = Provider<AppConfig>((_) => AppConfig.fromEnv());
final secureStoreProvider = Provider<SecureStore>((_) => SecureStore());
final dioProvider = Provider<Dio>((ref) {
  final cfg = ref.watch(configProvider);
  final store = ref.watch(secureStoreProvider);
  return buildDio(cfg, store);
});

// Repositories
final authRepoProvider  = Provider<AuthRepository>((ref) => AuthRepository(ref.watch(dioProvider), ref.watch(secureStoreProvider)));
final userRepoProvider  = Provider<UserRepository>((ref) => UserRepository(ref.watch(dioProvider)));
final bookRepoProvider  = Provider<BookRepository>((ref) => BookRepository(ref.watch(dioProvider)));
