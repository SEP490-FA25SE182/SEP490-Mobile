import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sep490_mobile/page/blog/blog_detail_page.dart';
import 'package:sep490_mobile/page/book/advanced_search_page.dart';
import 'package:sep490_mobile/page/book/book_detail_page.dart';
import 'package:sep490_mobile/page/book/book_show_page.dart';
import 'package:sep490_mobile/page/book/page_read.dart';
import 'package:sep490_mobile/page/order/checkout_page.dart';
import 'package:sep490_mobile/page/order/detail_refund_page.dart';
import 'package:sep490_mobile/page/order/feedback_page.dart';
import 'package:sep490_mobile/page/order/order_cancel_page.dart';
import 'package:sep490_mobile/page/order/order_delivered_page.dart';
import 'package:sep490_mobile/page/order/order_detail_page.dart';
import 'package:sep490_mobile/page/order/order_pending_page.dart';
import 'package:sep490_mobile/page/order/order_processing_page.dart';
import 'package:sep490_mobile/page/bookshelve/bookshelve_page.dart';
import 'package:sep490_mobile/page/order/order_return_page.dart';
import 'package:sep490_mobile/page/order/order_shipping_page.dart';
import 'package:sep490_mobile/page/order/payment_cancel_page.dart';
import 'package:sep490_mobile/page/order/payment_success_page.dart';
import 'package:sep490_mobile/page/order/return_page.dart';
import 'package:sep490_mobile/page/profile/edit_address_page.dart';
import 'package:sep490_mobile/page/profile/location_page.dart';
import 'package:sep490_mobile/page/unity/unity_page.dart';
import 'package:sep490_mobile/page/wallet/deposit_page.dart';
import 'package:sep490_mobile/page/wallet/wallet_coin_page.dart';
import 'package:sep490_mobile/page/unity/scan_page.dart';
import 'package:sep490_mobile/page/wallet/wallet_help_page.dart';
import 'package:sep490_mobile/page/wallet/wallet_money_page.dart';
import 'package:sep490_mobile/page/wallet/withdraw_page.dart';
import 'package:sep490_mobile/widget/deep_link_service.dart';
import 'provider.dart';

import 'page/home_page.dart';
import 'page/blog_page.dart';
import 'page/library_page.dart';
import 'page/cart_page.dart';
import 'page/profile_page.dart';
import 'page/auth/login_page.dart';
import 'page/auth/register_page.dart';
import 'page/profile/edit_profile_page.dart';
import 'page/auth/forgot_password_page.dart';
import 'page/book_list_page.dart';
import 'page/profile/edit_address_page.dart' show EditAddressArgs, EditAddressPage;
import 'page/profile/create_address_page.dart';

class MyApp extends StatelessWidget {
  final GoRouter router;
  const MyApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
    );
  }
}

GoRouter buildRouter() => GoRouter(
  initialLocation: '/',
    redirect: (context, state) {
      final uri = state.uri;
      if (uri.scheme == 'rookies' && uri.host == 'payment') {
        if (uri.path == '/success') {
          return '/payment/success?${uri.query}';
        }
        if (uri.path == '/cancel') {
          return '/payment/cancel?${uri.query}';
        }
      }
      return null;
    },
  routes: [
    GoRoute(path: '/',        name: 'home',    builder: (_, __) => const HomePage()),
    GoRoute(path: '/booklist', name: 'booklist', builder: (_, __) => const BookListPage()),
    GoRoute(path: '/advanced-search', name: 'advanced_search', builder: (context, state) => const AdvancedSearchPage(),),
    GoRoute(path: '/blogs',   name: 'blogs',   builder: (_, __) => const BlogPage()),
    GoRoute(path: '/cart',    name: 'cart',    builder: (_, __) => const CartPage()),
    GoRoute(path: '/library',    name: 'library',    builder: (_, __) => const BookshelvePage()),
    GoRoute(path: '/scan', builder: (_, __) => const ScanPage()),
    GoRoute(path: '/forgot_password', builder: (_, __) => const ForgotPasswordPage()),
    GoRoute(path: '/account/edit', builder: (_, __) => const EditProfilePage()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
    GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
    GoRoute(
      path: '/books/:id',
      name: 'book_detail',
      builder: (context, state) => BookDetailPage(bookId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/show/:bookId',
      name: 'book_show',
      builder: (context, state) => BookShowPage(bookId: state.pathParameters['bookId']!),
    ),
    GoRoute(
      path: '/reader/:bookId/:chapterId',
      name: 'reader',
      builder: (context, state) => PageReadPage(
        bookId: state.pathParameters['bookId']!,
        chapterId: state.pathParameters['chapterId']!,
      ),
    ),
    GoRoute(path: '/profile', name: 'profile', builder: (_, __) => const _ProfileLoader()),
    GoRoute(path: '/address/edit', builder: (_, st) => EditAddressPage(args: st.extra as EditAddressArgs)),
    GoRoute(path: '/address/create', builder: (_, __) => const CreateAddressPage()),
    GoRoute(path: '/blogs/:id', builder: (context, st) => BlogDetailPage(blogId: st.pathParameters['id']!)),
    GoRoute(path: '/location', builder: (ctx, st) => LocationPage(userId: st.extra as String)),
    GoRoute(path: '/wallet/coin', builder: (_, __) => const WalletCoinPage()),
    GoRoute(path: '/wallet/money', builder: (_, __) => const WalletMoneyPage()),
    GoRoute(path: '/wallet/deposit/:walletId', builder: (context, st) => DepositPage(walletId: st.pathParameters['walletId']!),),
    GoRoute(path: '/wallet/withdraw/:walletId', builder: (context, st) => WithdrawPage(walletId: st.pathParameters['walletId']!),),
    GoRoute(path: '/wallet/help', builder: (context, st) => const WalletHelpPage(),),
    GoRoute(path: '/checkout', builder: (ctx, st) => const CheckoutPage()),
    GoRoute(
      path: '/payment/success',
      builder: (ctx, st) => PaymentSuccessPage(orderId: st.uri.queryParameters['orderId']),
    ),
    GoRoute(
      path: '/payment/cancel',
      builder: (ctx, st) => PaymentCancelPage(orderId: st.uri.queryParameters['orderId']),
    ),
    GoRoute(path: '/orders/pending', builder: (ctx, st) => const OrderPendingPage()),
    GoRoute(path: '/orders/processing', builder: (ctx, st) => const OrderProcessingPage()),
    GoRoute(path: '/orders/shipping', builder: (ctx, st) => const OrderShippingPage()),
    GoRoute(path: '/orders/delivered', builder: (ctx, st) => const OrderDeliveredPage()),
    GoRoute(path: '/orders/cancel', builder: (ctx, st) => const OrderCancelPage()),
    GoRoute(path: '/orders/return', builder: (ctx, st) => const OrderReturnPage()),
    GoRoute(path: '/orders/return/:orderId', builder: (ctx, st) => ReturnPage(orderId: st.pathParameters['orderId']!),),
    GoRoute(path: '/orders/feedback/:orderId', builder: (ctx, st) => FeedbackPage(orderId: st.pathParameters['orderId']!),),
    GoRoute(path: '/orders/detail/:orderId', builder: (ctx, st) => OrderDetailPage(orderId: st.pathParameters['orderId'] ?? ''),),
    GoRoute(path: '/orders/refund/:orderId', builder: (ctx, st) => DetailRefundPage(orderId: st.pathParameters['orderId'] ?? ''),),
    GoRoute(
      path: '/unity',
      name: 'unity',
      builder: (ctx, st) {
        final markerId = st.uri.queryParameters['markerId'] ?? '';
        const backendBase = 'http://192.168.1.201:8083';
        return UnityPage(markerId: markerId, backendBase: backendBase);
      },
    ),
  ],
);

/// Đọc userId từ Provider, sau đó fetch User và Role
class _ProfileLoader extends ConsumerWidget {
  const _ProfileLoader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider) ?? '';
    debugPrint('[ProfileLoader] currentUserId="$userId"');

    if (userId.isEmpty) {
      debugPrint('[ProfileLoader] -> Guest ProfilePage');
      return const ProfilePage(user: null);
    }

    final userAsync = ref.watch(userByIdProvider(userId));
    return userAsync.when(
      data: (u) {
        debugPrint('[ProfileLoader] User loaded: id=${u.userId} email=${u.email} roleId=${u.roleId}');
        if (u.roleId.isEmpty) {
          debugPrint('[ProfileLoader] roleId empty => roleName=null');
          return ProfilePage(user: u, roleName: null);
        }

        final roleAsync = ref.watch(roleByIdProvider(u.roleId));
        return roleAsync.when(
          data: (r) {
            debugPrint('[ProfileLoader] Role loaded: roleId=${r.roleId} roleName=${r.roleName}');
            return ProfilePage(user: u, roleName: r.roleName);
          },
          loading: () {
            debugPrint('[ProfileLoader] Loading role for ${u.roleId} ...');
            // Có thể hiển thị tạm với roleName “Đang tải…”
            return ProfilePage(user: u, roleName: 'Đang tải…');
          },
          error: (e, _) {
            debugPrint('[ProfileLoader] Role fetch ERROR for ${u.roleId}: $e');
            return ProfilePage(user: u, roleName: 'Thành viên'); // fallback
          },
        );
      },
      loading: () {
        debugPrint('[ProfileLoader] Loading user...');
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
      error: (e, _) {
        debugPrint('[ProfileLoader] User fetch ERROR: $e');
        return Scaffold(
          body: Center(child: Text('Lỗi: $e', style: TextStyle(color: Colors.red.shade300))),
        );
      },
    );
  }
}
