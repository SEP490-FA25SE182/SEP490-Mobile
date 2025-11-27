import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:sep490_mobile/repository/address_repository.dart';
import 'package:sep490_mobile/repository/blog_repository.dart';
import 'package:sep490_mobile/repository/cart_item_repository.dart';
import 'package:sep490_mobile/repository/cart_repository.dart';
import 'package:sep490_mobile/repository/chapter_repository.dart';
import 'package:sep490_mobile/repository/comment_repository.dart';
import 'package:sep490_mobile/repository/feedback_repository.dart';
import 'package:sep490_mobile/repository/genre_repository.dart';
import 'package:sep490_mobile/repository/ghn_repository.dart';
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
import 'model/chapter.dart';
import 'model/comment.dart';
import 'model/feedback.dart';
import 'model/genre.dart';
import 'model/ghn_category_dto.dart';
import 'model/ghn_models.dart';
import 'model/ghn_shipping.dart';
import 'model/ghn_shipping_fee.dart';
import 'model/ghn_shipping_fee_request_dto.dart';
import 'model/order.dart';
import 'model/order_detail.dart';
import 'model/page.dart';
import 'model/payment_method.dart';
import 'model/transaction.dart';
import 'model/user_address.dart';
import 'model/vn_location.dart';
import 'model/wallet.dart';
import 'repository/auth_repository.dart';
import 'repository/book_repository.dart';
import 'repository/user_repository.dart';
import 'repository/role_repository.dart';
import 'util/extensions.dart';

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


final orderDetailIdForBookProvider = FutureProvider.family<String?, (String userId, String bookId)>(
      (ref, args) async {
    final (userId, bookId) = args;

    final orderRepo = ref.read(orderRepoProvider);
    final orderDetailRepo = ref.read(orderDetailRepoProvider);

    try {

      final orders = await orderRepo.search(
        userId: userId,
        status: 'DELIVERED',
        page: 0,
        size: 100,
      );

      for (final order in orders) {
        final details = await orderDetailRepo.listByOrder(order.orderId);
        final detail = details.firstWhereOrNull((d) => d.bookId == bookId);
        if (detail != null) {
          return detail.orderDetailId;
        }
      }

      return null;
    } catch (e) {
      print('[orderDetailIdForBookProvider] Error: $e');
      return null;
    }
  },
);

final hasReviewedProvider = FutureProvider.family<bool, (String userId, String bookId)>(
      (ref, args) async {
    final (userId, bookId) = args;
    final repo = ref.read(feedbackRepoProvider);
    final list = await repo.search(userId: userId, bookId: bookId);
    return list.isNotEmpty;
  },
);

/// feedbackRepo
final userFeedbackStatusProvider = FutureProvider.family<
    ({String? orderDetailId, FeedbackStatus? status, bool hasActive}), (String userId, String bookId)>(
      (ref, args) async {
    final (userId, bookId) = args;
    final feedbackRepo = ref.read(feedbackRepoProvider);
    final orderRepo = ref.read(orderRepoProvider);
    final orderDetailRepo = ref.read(orderDetailRepoProvider);

    try {
      final orders = await orderRepo.search(
        userId: userId,
        status: 'DELIVERED',
        page: 0,
        size: 100,
      );

      String? orderDetailId;
      for (final order in orders) {
        final details = await orderDetailRepo.listByOrder(order.orderId);
        final detail = details.firstWhereOrNull((d) => d.bookId == bookId);
        if (detail != null) {
          orderDetailId = detail.orderDetailId;
          break;
        }
      }

      if (orderDetailId == null) {
        return (orderDetailId: null, status: null, hasActive: false);
      }

      final feedbacks = await feedbackRepo.search(
        userId: userId,
        bookId: bookId,
        isActived: IsActived.active,
        page: 0,
        size: 1,
      );

      if (feedbacks.isEmpty) {
        return (orderDetailId: orderDetailId, status: null, hasActive: false);
      }

      final feedback = feedbacks.first;
      return (orderDetailId: orderDetailId, status: feedback.status, hasActive: true);
    } catch (e) {
      print('[userFeedbackStatusProvider] Error: $e');
      return (orderDetailId: null, status: null, hasActive: false);
    }
  },
);

/// Provider: Count of PUBLISHED feedbacks
final publishedFeedbackCountProvider = FutureProvider.family<int, String>(
      (ref, bookId) async {
    final repo = ref.read(feedbackRepoProvider);
    final list = await repo.search(
      bookId: bookId,
      isActived: IsActived.active,
      status: FeedbackStatus.published,
      page: 0,
      size: 1,
    );
    return list.length;
  },
);

/// Provider: Load feedbacks for list page
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
      sort: ['createdAt,desc'],
    );
  },
);

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

/// Search theo orderId và REFUND
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

///ChapterRepository
final chapterRepoProvider = Provider<ChapterRepository>((ref) {
  final dio = ref.read(dioProvider);
  return ChapterRepository(dio);
});

final chapterByIdProvider = FutureProvider.family<Chapter, String>((ref, chapterId) async {
  final repo = ref.read(chapterRepoProvider);
  return repo.getById(chapterId);
});

final chapterRepositoryProvider = Provider<ChapterRepository>((ref) {
  final dio = ref.read(dioProvider);
  return ChapterRepository(dio);
});

final pagesByChapterProvider = FutureProvider.family<List<PageModel>, String>((ref, chapterId) {
  final repo = ref.read(chapterRepositoryProvider);
  return repo.getPagesByChapterId(chapterId);
});

/// GhnRepository
final ghnRepositoryProvider = Provider<GhnRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return GhnRepository(dio);
});

final ghnProvincesProvider = FutureProvider.autoDispose<List<GhnProvince>>((ref) async {
  final repo = ref.read(ghnRepositoryProvider);
  try {
    final provinces = await repo.getProvinces();
    return provinces;
  } catch (e) {
    return <GhnProvince>[];
  }
});

final ghnDistrictsProvider = FutureProvider.autoDispose.family<List<GhnDistrict>, int>((ref, provinceId) async {
  final repo = ref.read(ghnRepositoryProvider);
  try {
    return await repo.getDistricts(provinceId);
  } catch (e) {
    return <GhnDistrict>[];
  }
});

final ghnWardsProvider = FutureProvider.autoDispose.family<List<GhnWard>, int>((ref, districtId) async {
  final repo = ref.read(ghnRepositoryProvider);
  try {
    return await repo.getWards(districtId);
  } catch (e) {
    return <GhnWard>[];
  }
});


/// FeedbackRepo
final feedbackRepoProvider = Provider<FeedbackRepository>((ref) {
  return FeedbackRepository(ref.watch(dioProvider));
});

/// Checkout-only selected address (page scope)
final checkoutSelectedAddressProvider = StateProvider<UserAddress?>((ref) => null);

/// Get selected or default address ID
final selectedOrDefaultAddressIdProvider = Provider.family<String?, String>((ref, userId) {
  final addressesAsync = ref.watch(addressesByUserProvider(userId));
  final list = addressesAsync.value ?? [];
  if (list.isEmpty) return null;

  final selected = ref.watch(checkoutSelectedAddressProvider);
  if (selected != null) return selected.userAddressId;

  final defaultAddr = list.firstWhere((a) => a.isDefault, orElse: () => list.first);
  return defaultAddr.userAddressId;
});

/// Shipping fee calculator
final shippingFeeProvider = FutureProvider.family<GhnShippingFee?, String>((ref, orderId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null || userId.isEmpty) return null;

  // THIS IS THE KEY: listen to selected address in checkout
  final selectedAddressId = ref.watch(checkoutSelectedAddressIdProvider);

  final orderAsync = ref.watch(orderByIdProvider(orderId));
  final detailsAsync = ref.watch(orderDetailsByOrderProvider(orderId));

  final order = orderAsync.value;
  final details = detailsAsync.value;
  if (order == null || details == null || details.isEmpty) return null;

  // Get current selected or default address
  String? addressId;
  if (selectedAddressId != null) {
    addressId = selectedAddressId;
  } else {
    addressId = ref.read(selectedOrDefaultAddressIdProvider(userId));
  }

  if (addressId == null) return null;

  final addressAsync = ref.watch(addressByIdProvider(addressId));
  final address = addressAsync.value;
  if (address == null) return null;

  // Invalidate if address has invalid GHN data
  if (address.districtIdInt == 0 || address.wardCodeSafe == '0' || address.wardCodeSafe.isEmpty) {
    return GhnShippingFee(total: 30000); // fallback
  }

  final itemCount = details.fold<int>(0, (sum, d) => sum + d.quantity);

  final request = GhnShippingFeeRequestDTO(
    serviceTypeId: 2,
    fromDistrictId: 3695,
    fromWardCode: "90752",
    toDistrictId: address.districtIdInt,
    toWardCode: address.wardCodeSafe,
    length: 25,
    width: 25,
    height: (5 * itemCount).clamp(5, 200),
    weight: (300 * itemCount).clamp(300, 1600000),
    insuranceValue: order.totalPrice.round(),
    codValue: order.totalPrice.round(),
    items: details.map((d) {
      final bookName = ref.read(bookByIdProvider(d.bookId)).value?.bookName ?? "Sách";
      return GhnItemDTO(
        name: bookName,
        quantity: d.quantity,
        price: d.price.round(),
        length: 25,
        width: 25,
        height: 5,
        weight: 300,
        category: const GhnCategoryDTO(level1: "Book"),
      );
    }).toList(),
  );

  try {
    return await ref.read(ghnRepositoryProvider).calculateFee(request);
  } catch (e) {
    debugPrint('GHN fee error: $e');
    return GhnShippingFee(total: 30000);
  }
});

final checkoutSelectedAddressIdProvider = StateProvider<String?>((ref) => null);