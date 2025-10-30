import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sep490_mobile/page/blog/blog_detail_page.dart';
import 'package:sep490_mobile/page/book/book_detail_page.dart';
import 'package:sep490_mobile/page/profile/edit_address_page.dart';
import 'package:sep490_mobile/page/profile/location_page.dart';
import 'package:sep490_mobile/page/profile/wallet_coin_page.dart';
import 'package:sep490_mobile/page/scan_page.dart';
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
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/',        name: 'home',    builder: (_, __) => const HomePage()),
        GoRoute(path: '/booklist', name: 'booklist', builder: (_, __) => const BookListPage()),
        GoRoute(path: '/blogs',   name: 'blogs',   builder: (_, __) => const BlogPage()),
        //GoRoute(path: '/library', name: 'library', builder: (_, __) => const LibraryPage()),
        GoRoute(path: '/cart',    name: 'cart',    builder: (_, __) => const CartPage()),
        GoRoute(path: '/scan', builder: (_, __) => const ScanPage(),),
        GoRoute(path: '/forgot_password',    builder: (_, __) => const ForgotPasswordPage()),
        GoRoute(path: '/account/edit', builder: (_, __) => const EditProfilePage()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
        GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
        GoRoute(
          path: '/books/:id',
          name: 'book_detail',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return BookDetailPage(bookId: id);
          },
        ),
        GoRoute(path: '/profile', name: 'profile', builder: (context, state) => const _ProfileLoader(),),
        GoRoute(path: '/address/edit', builder: (_, state) => EditAddressPage(args: state.extra as EditAddressArgs),),
        GoRoute(path: '/address/create', builder: (_, __) => const CreateAddressPage(),),
        GoRoute(path: '/blogs/:id', builder: (context, state) => BlogDetailPage(blogId: state.pathParameters['id']!),),
        GoRoute(path: '/location', builder: (_, __) => const LocationPage(userId: '',)),
        GoRoute(path: '/wallet/coin', builder: (_, __) => const WalletCoinPage()),
      ],
    );

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