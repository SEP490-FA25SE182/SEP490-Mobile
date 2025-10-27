import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../model/user_address.dart';
import '../provider.dart';
import '../style/button.dart';
import '../page/profile/edit_address_page.dart' show EditAddressArgs;

/// Section "Sổ địa chỉ"
class UserAddressSection extends ConsumerWidget {
  final String userId;
  const UserAddressSection({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(addressesByUserProvider(userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        const Text(
          'Sổ địa chỉ',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),

        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Lỗi tải sổ địa chỉ: $e',
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
          data: (list) {
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: const Text(
                  'Bạn chưa có địa chỉ nhận hàng. Tạo ngay nào',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            final def = list.where((e) => e.isDefault).toList();
            final others = list.where((e) => !e.isDefault).toList();

            return Column(
              children: [
                if (def.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _AddressCard(
                          addr: def.first,
                          onEdit: () => context.push(
                            '/address/edit',
                            extra: EditAddressArgs(userId: userId, address: def.first),
                          ),
                        ),
                        const _DefaultBadge(),
                      ],
                    ),
                  ),

                ...others.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _AddressCard(
                        addr: a,
                        onEdit: () => context.push(
                          '/address/edit',
                          extra: EditAddressArgs(userId: userId, address: a),
                        ),
                      ),
                      if (a.isDefault) const _DefaultBadge(),
                    ],
                  ),
                )),
              ],
            );
          },
        ),

        const SizedBox(height: 10),

        // Nút thêm địa chỉ – đi đến trang tạo mới
        ButtonSoft(
          text: '+ Thêm địa chỉ',
          onTap: () => context.push('/address/create'),
        ),
      ],
    );
  }
}

/// Thẻ hiển thị 1 địa chỉ
class _AddressCard extends StatelessWidget {
  final UserAddress addr;
  final VoidCallback onEdit;
  const _AddressCard({required this.addr, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0x14FFFFFF),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_outlined, color: Color(0xFF5B6CF3)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        addr.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if ((addr.phoneNumber ?? '').isNotEmpty)
                      Text(addr.phoneNumber!, style: const TextStyle(color: Colors.white54)),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: onEdit,
                      child: const Padding(
                        padding: EdgeInsets.all(6.0),
                        child: Icon(Icons.edit, size: 18, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(addr.addressInfor, style: const TextStyle(color: Colors.white70)),
                if (addr.isDefault) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DefaultBadge extends StatelessWidget {
  const _DefaultBadge();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      top: -10,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF2E3350).withOpacity(0.9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white24, width: 0.8),
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: const Text(
            'Mặc định',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

