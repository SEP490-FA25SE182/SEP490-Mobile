import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:sep490_mobile/repository/address_repository.dart';
import 'package:sep490_mobile/repository/vn_location_repository.dart';
import 'core/config.dart';
import 'core/api_client.dart';
import 'core/secure_store.dart';
import 'model/user_address.dart';
import 'model/vn_location.dart';
import 'repository/auth_repository.dart';
import 'repository/book_repository.dart';
import 'repository/user_repository.dart';
import 'repository/role_repository.dart';

import 'model/user.dart';
import 'model/role.dart';

// Config & core
final configProvider = Provider<AppConfig>((_) => AppConfig.fromEnv());
final secureStoreProvider = Provider<SecureStore>((_) => SecureStore());
final dioProvider = Provider<Dio>((ref) {
  final cfg = ref.watch(configProvider);
  final store = ref.watch(secureStoreProvider);
  return buildDio(cfg, store);
});

/// AuthRepository
final authRepoProvider = Provider<AuthRepository>(
      (ref) => AuthRepository(ref.read(dioProvider), ref.read(secureStoreProvider)),
);

///UserRepository
final userRepoProvider = Provider<UserRepository>(
      (ref) => UserRepository(ref.read(dioProvider)),
);

// Fetch user theo id
final userByIdProvider = FutureProvider.family<User, String>((ref, id) {
  return ref.read(userRepoProvider).getProfile(id);
});
// Lưu userId hiện tại sau khi login (null = khách)
final currentUserIdProvider = StateProvider<String?>((_) => null);
// Xoá cache user theo id (sau logout)
void invalidateUserCache(WidgetRef ref, String? userId) {
  if (userId != null && userId.isNotEmpty) {
    ref.invalidate(userByIdProvider(userId));
  }
}

///RoleRepository
final roleRepoProvider = Provider<RoleRepository>(
      (ref) => RoleRepository(ref.read(dioProvider)),
);

final roleByIdProvider = FutureProvider.family<Role, String>((ref, id) {
  return ref.read(roleRepoProvider).getById(id);
});

///BookRepository
final bookRepoProvider  = Provider<BookRepository>((ref) => BookRepository(ref.watch(dioProvider)));

///AddressRepository
final addressRepoProvider =
Provider<AddressRepository>((ref) => AddressRepository(ref.read(dioProvider)));

// Danh sách địa chỉ theo userId
final addressesByUserProvider =
FutureProvider.family<List<UserAddress>, String>((ref, userId) async {
  final list = await ref.read(addressRepoProvider).listByUser(userId);
  list.sort((a, b) {
    if (a.isDefault == b.isDefault) return 0;
    return a.isDefault ? -1 : 1;
  });
  return list;
});


// Invalidate cache address (sau khi thêm/sửa/xoá/đặt mặc định)
void invalidateAddressesCache(WidgetRef ref, String userId) {
  ref.invalidate(addressesByUserProvider(userId));
}

final vnLocationRepoProvider = Provider<VnLocationRepository>(
      (ref) => VnLocationRepository(ref.read(dioProvider)),
);

final vnLocationsProvider = FutureProvider<List<VnProvince>>((ref) {
  return ref.read(vnLocationRepoProvider).fetchAll();
});