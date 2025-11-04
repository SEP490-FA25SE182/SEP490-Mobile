import 'dart:async';
import 'dart:async' show scheduleMicrotask;
import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';

class DeepLinkService {
  AppLinks? _appLinks;
  StreamSubscription<Uri>? _sub;

  Future<void> init(GoRouter router) async {
    _appLinks = AppLinks();

    // Cold start
    try {
      final Uri? initial = await _appLinks!.getInitialLink();
      if (initial != null) _handleUri(router, initial);
    } catch (_) {}

    // While app is running
    _sub = _appLinks!.uriLinkStream.listen(
          (uri) => _handleUri(router, uri),
      onError: (_) {},
    );
  }

  void _handleUri(GoRouter router, Uri uri) {
    if (uri.scheme != 'rookies' || uri.host != 'payment') return;

    String? target;
    if (uri.path == '/success') {
      target = '/payment/success${uri.hasQuery ? '?${uri.query}' : ''}';
    } else if (uri.path == '/cancel') {
      target = '/payment/cancel${uri.hasQuery ? '?${uri.query}' : ''}';
    }

    if (target == null) return;

    scheduleMicrotask(() {
      router.go(target!);
    });
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
