import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:sep490_mobile/repository/address_repository.dart';
import 'package:sep490_mobile/repository/blog_repository.dart';
import 'package:sep490_mobile/repository/cart_item_repository.dart';
import 'package:sep490_mobile/repository/cart_repository.dart';
import 'package:sep490_mobile/repository/comment_repository.dart';
import 'package:sep490_mobile/repository/genre_repository.dart';
import 'package:sep490_mobile/repository/order_detail_repository.dart';
import 'package:sep490_mobile/repository/order_repository.dart';
import 'package:sep490_mobile/repository/payment_repository.dart';
import 'package:sep490_mobile/repository/bookshelve_repository.dart';
import 'package:sep490_mobile/repository/genre_repository.dart';
import 'package:sep490_mobile/repository/notification_repository.dart';
import 'package:sep490_mobile/repository/vn_location_repository.dart';
import 'package:sep490_mobile/repository/wallet_repository.dart';
import 'core/config.dart';
import 'core/api_client.dart';
import 'core/secure_store.dart';
import 'model/blog.dart';
import 'model/book.dart';
import 'model/cart.dart';
import 'model/cart_item.dart';
import 'model/bookshelve.dart';
import 'model/comment.dart';
import 'model/genre.dart';
import 'model/order.dart';
import 'model/order_detail.dart';
import 'model/user_address.dart';
import 'model/vn_location.dart';
import 'model/wallet.dart';
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

// Lấy 1 sách theo id
final bookByIdProvider = FutureProvider.family<Book, String>((ref, id) async {
  return ref.read(bookRepoProvider).getById(id);
});

///AddressRepository
final addressRepoProvider =
Provider<AddressRepository>((ref) => AddressRepository(ref.read(dioProvider)));

final addressByIdProvider = FutureProvider.family<UserAddress?, String>((ref, id) async {
  return ref.read(addressRepoProvider).getOne(id);
});

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

///BlogRepository
final blogRepoProvider = Provider<BlogRepository>((ref) => BlogRepository(ref.read(dioProvider)));

final blogByIdProvider =
FutureProvider.family<Blog, String>((ref, id) => ref.read(blogRepoProvider).getById(id));


final genreRepoProvider = Provider<GenreRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return GenreRepository(dio);
});

final genresProvider = FutureProvider<List<Genre>>((ref) async {
  final repo = ref.watch(genreRepoProvider);
  return repo.list();
});

///CartRepository
final cartRepoProvider     = Provider((ref) => CartRepository(ref.read(dioProvider)));
final cartItemRepoProvider = Provider((ref) => CartItemRepository(ref.read(dioProvider)));

final cartByUserProvider = FutureProvider.family<Cart?, String>((ref, userId) {
  return ref.read(cartRepoProvider).getByUserId(userId);
});

final cartItemsByCartProvider = FutureProvider.family<List<CartItem>, String>((ref, cartId) {
  return ref.read(cartItemRepoProvider).listByCart(cartId);
});

///WalletRepository
final walletRepoProvider = Provider<WalletRepository>(
      (ref) => WalletRepository(ref.read(dioProvider)),
);

//Lấy ví theo user
final walletByUserProvider = FutureProvider.family<Wallet?, String>((ref, userId) async {
  return ref.read(walletRepoProvider).getByUserId(userId);
});


///OrderRepository
final orderRepoProvider = Provider<OrderRepository>(
      (ref) => OrderRepository(ref.read(dioProvider)),
);

final orderDetailRepoProvider = Provider<OrderDetailRepository>(
      (ref) => OrderDetailRepository(ref.read(dioProvider)),
);

final orderByIdProvider = FutureProvider.family<Order, String>((ref, id) async {
  return ref.read(orderRepoProvider).getById(id);
});

final orderDetailsByOrderProvider = FutureProvider.family<List<OrderDetail>, String>((ref, oid) async {
  return ref.read(orderDetailRepoProvider).listByOrder(oid);
});

///PaymentRepository
final paymentRepoProvider = Provider<PaymentRepository>(
      (ref) => PaymentRepository(ref.read(dioProvider)),
);

final bookshelveRepoProvider = Provider<BookshelveRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return BookshelveRepository(dio);
});

// trạng thái tìm kiếm (Bookshelve)
final bookshelveSearchProvider = StateProvider<String>((_) => '');

// provider family: input = userId
final bookshelvesProvider = FutureProvider.family<List<Bookshelve>, String>((ref, userId) async {
  final repo = ref.watch(bookshelveRepoProvider);
  final q = ref.watch(bookshelveSearchProvider);
  // gọi repo với q nếu có
  return repo.listByUser(
    userId: userId,
    page: 0,
    size: 10,
    searchQuery: q.isNotEmpty ? q : null,
    sort: ['createdAt-desc'],
  );
});

final booksByShelfProvider = FutureProvider.family<List<Book>, String>((ref, shelfId) async {
  final repo = ref.watch(bookRepoProvider);
  return repo.getBooksByShelfId(shelfId, sort: ['createdAt-desc']);
});



final notificationRepoProvider = Provider<NotificationRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return NotificationRepository(dio);
});

///CommentRepository
final commentRepoProvider = Provider<CommentRepository>(
      (ref) => CommentRepository(ref.read(dioProvider)),
);

final commentCountProvider =
FutureProvider.family<int, String>((ref, blogId) {
  return ref.read(commentRepoProvider).countPublishedByBlog(blogId);
});

final commentsByBlogProvider =
FutureProvider.family<List<Comment>, String>((ref, blogId) {
  return ref.read(commentRepoProvider).getByBlogId(blogId);
});
