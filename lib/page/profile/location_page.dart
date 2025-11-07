import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../model/user_address.dart';
import '../../provider.dart';
import '../../style/button.dart';
import '../../page/profile/edit_address_page.dart' show EditAddressArgs;

class LocationPage extends ConsumerStatefulWidget {
  final String userId;
  const LocationPage({super.key, required this.userId});

  @override
  ConsumerState<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends ConsumerState<LocationPage> {
  String? _selectedId;

  void _popWithResult(UserAddress? addr) {
    if (context.canPop()) {
      context.pop<UserAddress?>(addr);
    } else {
      Navigator.of(context).pop(addr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(addressesByUserProvider(widget.userId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1B3B68),
                    Color(0xFF0F1B2E),
                    Color(0xFF123C6B),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 8, 8, 6),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () async {
                            // Lấy object địa chỉ theo _selectedId (nếu có)
                            UserAddress? result;
                            final value = ref.read(addressesByUserProvider(widget.userId)).value;
                            if (value != null && _selectedId != null) {
                              result = value.firstWhere(
                                    (a) => a.userAddressId == _selectedId,
                                orElse: () => value.firstWhere(
                                      (a) => a.isDefault,
                                  orElse: () => value.first,
                                ),
                              );
                            }
                            _popWithResult(result);
                          },
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Chọn địa chỉ nhận sách',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: Colors.white.withOpacity(0.15)),

                  // Nội dung: danh sách địa chỉ + checkbox chọn
                  Expanded(
                    child: async.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Lỗi tải sổ địa chỉ: $e',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                      data: (list) {
                        if (list.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Bạn chưa có địa chỉ nhận hàng. Tạo ngay nào',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 14),
                                ButtonSoft(
                                  text: '+ Thêm địa chỉ',
                                  onTap: () => context.push('/address/create'),
                                ),
                              ],
                            ),
                          );
                        }

                        // Sắp xếp: mặc định lên trước cho dễ thấy
                        final def = list.where((e) => e.isDefault).toList();
                        final others = list.where((e) => !e.isDefault).toList();
                        final ordered = [...def, ...others];

                        _selectedId ??= def.isNotEmpty
                            ? def.first.userAddressId
                            : ordered.first.userAddressId;

                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
                          child: Column(
                            children: [
                              ...ordered.map((addr) => _AddressRow(
                                addr: addr,
                                selectedId: _selectedId,
                                onSelect: () => setState(() {
                                  _selectedId = addr.userAddressId;
                                }),
                                onEdit: () => context.push(
                                  '/address/edit',
                                  extra: EditAddressArgs(
                                    userId: widget.userId,
                                    address: addr,
                                  ),
                                ),
                              )),
                              const SizedBox(height: 10),
                              ButtonSoft(
                                text: '+ Thêm địa chỉ',
                                onTap: () => context.push('/address/create'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final UserAddress addr;
  final String? selectedId;
  final VoidCallback onSelect;
  final VoidCallback onEdit;

  const _AddressRow({
    required this.addr,
    required this.selectedId,
    required this.onSelect,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
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
                            Text(
                              addr.phoneNumber!,
                              style: const TextStyle(color: Colors.white54),
                            ),
                          const SizedBox(width: 4),
                          // Nút sửa
                          InkWell(
                            onTap: onEdit,
                            child: const Padding(
                              padding: EdgeInsets.all(6.0),
                              child: Icon(Icons.edit, size: 18, color: Colors.white70),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Radio chọn địa chỉ
                          Radio<String>(
                            value: addr.userAddressId,
                            groupValue: selectedId,
                            onChanged: (_) => onSelect(),
                            activeColor: const Color(0xFF5B6CF3),
                            fillColor: WidgetStateProperty.resolveWith(
                                  (states) => const Color(0xFF5B6CF3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(addr.addressInfor, style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Badge "Mặc định"
          if (addr.isDefault)
            const Positioned.fill(
              top: -10,
              child: Align(
                alignment: Alignment.topCenter,
                child: _DefaultBadge(),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2E3350).withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24, width: 0.8),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2))],
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
    );
  }
}
