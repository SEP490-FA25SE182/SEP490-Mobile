import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../provider.dart';
import '../model/cart_item.dart';
import '../widget/gs_image.dart';
import '../model/book.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  bool _editMode = false;
  final Set<String> _checked = <String>{};
  bool _selectAll = false;

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUserIdProvider);
    if (uid == null || uid.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
          title: const Text('Giỏ hàng'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Bạn chưa đăng nhập', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Về trang chủ'),
              ),
            ],
          ),
        ),
      );
    }

    final cartAsync = ref.watch(cartByUserProvider(uid));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/');
          },
        ),
        title: const Text('Giỏ hàng'),
        actions: [
          TextButton(
            onPressed: () => setState(() => _editMode = !_editMode),
            child: Text(
              _editMode ? 'Xong' : 'Sửa',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0E2A47), Color(0xFF09121F)],
          ),
        ),
        child: cartAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Lỗi tải giỏ hàng: $e', style: const TextStyle(color: Colors.redAccent))),
          data: (cart) {
            if (cart == null) {
              return const Center(
                child: Text('Giỏ hàng trống', style: TextStyle(color: Colors.white70)),
              );
            }

            final cartId = cart.cartId;
            final itemsAsync = ref.watch(cartItemsByCartProvider(cartId));

            return itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Lỗi tải sản phẩm: $e',
                    style: const TextStyle(color: Colors.redAccent)),
              ),
              data: (items) {
                final allIds = items.map((e) => e.cartItemId).toSet();
                _selectAll = _checked.length == allIds.length && allIds.isNotEmpty;

                final total = items
                    .where((i) => _checked.contains(i.cartItemId))
                    .fold<double>(0.0, (sum, i) => sum + i.price * i.quantity);

                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, idx) {
                          final it = items[idx];
                          final ticked = _checked.contains(it.cartItemId);
                          return _CartItemRow(
                            item: it,
                            ticked: ticked,
                            onTick: (v) {
                              setState(() {
                                if (v == true) {
                                  _checked.add(it.cartItemId);
                                } else {
                                  _checked.remove(it.cartItemId);
                                }
                              });
                            },
                            onMinus: () => _changeQty(it, it.quantity - 1),
                            onPlus : () => _changeQty(it, it.quantity + 1),
                          );
                        },
                      ),
                    ),

                    _CartBottomBar(
                      selectAll: _selectAll,
                      onToggleAll: (val) {
                        setState(() {
                          _selectAll = val ?? false;
                          _checked.clear();
                          if (_selectAll) _checked.addAll(allIds);
                        });
                      },
                      total: total,
                      editMode: _editMode,
                      onCheckout: () {
                        if (_checked.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Bạn chưa chọn sản phẩm.')),
                          );
                          return;
                        }
                        // TODO: điều hướng sang màn hình checkout
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đi tới thanh toán…')),
                        );
                      },
                      onDeleteSelected: () async {
                        if (_checked.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Chưa chọn sản phẩm nào để xoá.')),
                          );
                          return;
                        }
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Xóa sản phẩm'),
                            content: Text('Xóa ${_checked.length} sản phẩm khỏi giỏ hàng?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
                              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
                            ],
                          ),
                        );
                        if (ok != true) return;

                        final repo = ref.read(cartItemRepoProvider);
                        for (final id in _checked) {
                          await repo.remove(id);
                        }
                        setState(() {
                          _checked.clear();
                          _selectAll = false;
                        });
                        ref.invalidate(cartItemsByCartProvider(cart.cartId));
                        ref.invalidate(cartByUserProvider(uid));
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _changeQty(CartItem it, int next) async {
    if (next < 1) return;
    try {
      await ref.read(cartItemRepoProvider).update(
        it.cartItemId,
        quantity: next,
        price: it.price, // giữ nguyên giá
      );
      // refresh list và tổng
      ref.invalidate(cartItemsByCartProvider(it.cartId));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật số lượng thất bại: $e')),
      );
    }
  }
}

/// Hàng 1 item trong giỏ
class _CartItemRow extends ConsumerWidget {
  final CartItem item;
  final bool ticked;
  final ValueChanged<bool?> onTick;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _CartItemRow({
    required this.item,
    required this.ticked,
    required this.onTick,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(bookByIdProvider(item.bookId));
    final priceStr = _fmtVnd(item.price);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x0FFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: ticked,
            onChanged: onTick,
            side: const BorderSide(color: Colors.white54),
            activeColor: const Color(0xFF5B6CF3),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56, height: 72,
              child: bookAsync.when(
                data: (b) => (b.coverUrl != null && b.coverUrl!.isNotEmpty)
                    ? GsImage(url: b.coverUrl!, fit: BoxFit.cover)
                    : Container(color: const Color(0x225B6CF3)),
                loading: () => Container(color: const Color(0x1FFFFFFF)),
                error: (_, __) => Container(color: const Color(0x225B6CF3)),
              ),
            ),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bookAsync.when(
                  data: (b) => Text(
                    b.bookName ?? '(Không rõ tên sách)',
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  loading: () => const SizedBox(height: 18),
                  error: (_, __) => const Text('(Lỗi tải tên sách)', style: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(height: 6),
                Text(priceStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ],
            ),
          ),

          const SizedBox(width: 8),

          _QtyControl(
            qty: item.quantity,
            onMinus: onMinus,
            onPlus: onPlus,
          ),
        ],
      ),
    );
  }

  String _fmtVnd(double v) {
    final s = v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '$s VND';
  }
}

class _QtyControl extends StatelessWidget {
  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _QtyControl({required this.qty, required this.onMinus, required this.onPlus});

  static const _minus = 'gs://sep490-fa25se182.firebasestorage.app/icon/minus.png';
  static const _plus  = 'gs://sep490-fa25se182.firebasestorage.app/icon/plus.png';

  @override
  Widget build(BuildContext context) {
    Widget gsBtn(String url, VoidCallback onTap) => InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 26,
        height: 26,
        child: GsImage(url: url, fit: BoxFit.contain),
      ),
    );

    return Row(
      children: [
        gsBtn(_minus, onMinus),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0x335B6CF3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: Text('$qty', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 8),
        gsBtn(_plus, onPlus),
      ],
    );
  }
}

class _CartBottomBar extends StatelessWidget {
  final bool selectAll;
  final ValueChanged<bool?> onToggleAll;
  final double total;
  final bool editMode;
  final VoidCallback onCheckout;
  final VoidCallback onDeleteSelected;

  const _CartBottomBar({
    required this.selectAll,
    required this.onToggleAll,
    required this.total,
    required this.editMode,
    required this.onCheckout,
    required this.onDeleteSelected,
  });

  @override
  Widget build(BuildContext context) {
    final totalStr = _formatVnd(total);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        color: Color(0x22000000),
        border: Border(top: BorderSide(color: Colors.white12, width: 1)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: selectAll,
            onChanged: onToggleAll,
            side: const BorderSide(color: Colors.white54),
            activeColor: const Color(0xFF5B6CF3),
          ),
          const Text('Tất cả', style: TextStyle(color: Colors.white70)),
          const Spacer(),
          if (!editMode) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Tổng', style: TextStyle(color: Colors.white54)),
                Text(totalStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(width: 12),
          ],
          SizedBox(
            height: 40,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: editMode ? const Color(0xFF7A3B3B) : const Color(0xFF6E5ADF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onPressed: editMode ? onDeleteSelected : onCheckout,
              child: Text(editMode ? 'XÓA' : 'MUA HÀNG', style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatVnd(double v) {
    final s = v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '$s VND';
  }
}
