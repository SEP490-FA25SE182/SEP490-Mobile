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
import 'package:sep490_mobile/repository/payment_method_repository.dart';
import 'package:sep490_mobile/repository/payment_repository.dart';
import 'package:sep490_mobile/repository/bookshelve_repository.dart';
import 'package:sep490_mobile/repository/genre_repository.dart';
import 'package:sep490_mobile/repository/notification_repository.dart';
import 'package:sep490_mobile/repository/transaction_repository.dart';
import 'package:sep490_mobile/repository/vn_location_repository.dart';
import 'package:sep490_mobile/repository/wallet_repository.dart';
import 'package:sep490_mobile/util/trans_type.dart';
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
import 'model/payment_method.dart';
import 'model/transaction.dart';
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

final walletByIdProvider = FutureProvider.family<Wallet?, String>((ref, wid) async {
  return ref.read(walletRepoProvider).getById(wid);
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


//Bookshelve
final bookshelveRepoProvider = Provider<BookshelveRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return BookshelveRepository(dio);
});


final bookshelveSearchProvider = StateProvider<String>((_) => '');

// provider family: input = userId
final bookshelvesProvider = FutureProvider.family<List<Bookshelve>, String>((ref, userId) async {
  final repo = ref.watch(bookshelveRepoProvider);
  final q = ref.watch(bookshelveSearchProvider);
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

// Check if book in favorite shelf
final isBookInFavoriteProvider =
FutureProvider.family<bool, (String userId, String bookId)>((ref, args) async {
  final (userId, bookId) = args;
  final repo = ref.read(bookshelveRepoProvider);
  return repo.isBookInFavorite(userId, bookId);
});

/// Genres by book provider
final genresByBookProvider =
FutureProvider.family<List<Genre>, String>((ref, bookId) async {
  final repo = ref.read(genreRepoProvider);
  return repo.listByBook(bookId: bookId);
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

///TransactionRepository
final transactionRepoProvider = Provider<TransactionRepository>(
      (ref) => TransactionRepository(ref.read(dioProvider)),
);

// Search theo orderId và PAYMENT
final transactionByOrderProvider =
FutureProvider.family<Transaction?, String>((ref, oid) async {
  final page = await ref.read(transactionRepoProvider).search(
    orderId: oid,
    transType: TransactionType.PAYMENT,
    page: 0,
    size: 1,
    sort: const ['createdAt,desc'],
  );
  return page.content.isEmpty ? null : page.content.first;
});

// Search theo orderId và REFUND
final transactionRefundByOrderProvider =
FutureProvider.family<Transaction?, String>((ref, oid) async {
  final page = await ref.read(transactionRepoProvider).search(
    orderId: oid,
    transType: TransactionType.REFUND,
    page: 0,
    size: 1,
    sort: const ['createdAt,desc'],
  );
  return page.content.isEmpty ? null : page.content.first;
});

// Lịch sử giao dịch theo walletId
final transactionsByWalletProvider =
FutureProvider.family.autoDispose<List<Transaction>, String>((ref, wid) async {
  final page = await ref.read(transactionRepoProvider).search(
    walletId: wid,
    page: 0,
    size: 200,
    sort: const ['updatedAt,desc'],
  );
  return page.content;
});

///PaymentMethodRepository
final paymentMethodRepoProvider = Provider<PaymentMethodRepository>(
      (ref) => PaymentMethodRepository(ref.read(dioProvider)),
);

final paymentMethodByIdProvider =
FutureProvider.family<PaymentMethod?, String?>((ref, pmId) async {
  if (pmId == null || pmId.isEmpty) return null;
  return ref.read(paymentMethodRepoProvider).getById(pmId);
});

///OrderRepository
final orderRepositoryProvider = Provider<OrderRepository>(
      (ref) => OrderRepository(ref.read(dioProvider)),
);