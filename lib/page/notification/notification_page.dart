import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../model/notification.dart'; // You'll create this DTO model
import '../../provider.dart';
import '../../repository/notification_repository.dart';
import '../../util/time_utils.dart'; // Optional helper for formatting time

/// --- PROVIDER + STATE MANAGEMENT ---

final userNotificationsProvider = FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  final repo = ref.watch(notificationRepoProvider);
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null || userId.isEmpty) {
    return const [];
  }

  return repo.list(userId: userId, sort: 'createdAt-desc');
});

/// --- PAGE ---

class NotificationPage extends ConsumerWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);

    // --- Handle Not Logged In ---
    if (userId == null || userId.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF09121F),
        appBar: AppBar(
          title: const Text('Thông báo'),
          centerTitle: true,
          backgroundColor: const Color(0xFF0E2A47),
        ),
        body: Center(
          child: GestureDetector(
            onTap: () => context.push('/login'),
            child: const Text(
              'Vui lòng đăng nhập trước',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      );
    }

    // --- Load Notifications ---
    final notificationsAsync = ref.watch(userNotificationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF09121F),
      appBar: AppBar(
        title: const Text('Thông báo'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0E2A47),
      ),
      body: notificationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (e, _) => Center(
          child: Text('Lỗi: $e', style: const TextStyle(color: Colors.redAccent)),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Text(
                'Không có thông báo nào.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, i) {
              final n = notifications[i];
              final isRead = n.isRead ?? false;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isRead ? const Color(0xFF18223A) : const Color(0xFF213A5C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  title: Text(
                    n.title ?? 'Thông báo',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (n.message != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            n.message!,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      if (n.createdAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            formatTimeAgo(n.createdAt!), // optional util
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      isRead ? Icons.check_circle : Icons.circle,
                      color: isRead ? Colors.greenAccent : Colors.white54,
                    ),
                    onPressed: isRead
                        ? null
                        : () async {
                      final repo = ref.read(notificationRepoProvider);
                      await repo.markAsRead(n.notificationId);
                      ref.invalidate(userNotificationsProvider);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
