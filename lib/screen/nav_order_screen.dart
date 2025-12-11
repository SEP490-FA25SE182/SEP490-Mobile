import 'package:flutter/material.dart';

enum OrderTab { pending, processing, shipping, delivered, received, cancelled, returned }

extension OrderTabLabel on OrderTab {
  String get label {
    switch (this) {
      case OrderTab.pending:    return 'Chờ xác nhận';
      case OrderTab.processing: return 'Chờ lấy hàng';
      case OrderTab.shipping:   return 'Chờ giao';
      case OrderTab.delivered:  return 'Đã giao';
      case OrderTab.received:   return 'Hoàn thành';
      case OrderTab.cancelled:  return 'Đã huỷ';
      case OrderTab.returned:   return 'Trả hàng';
    }
  }
}

/// Thanh tab order
class NavOrderScreen extends StatelessWidget {
  final OrderTab current;
  final ValueChanged<OrderTab> onChanged;

  const NavOrderScreen({
    super.key,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Chia tab thành 2 nhóm
    final topTabs = const [
      OrderTab.pending,
      OrderTab.processing,
      OrderTab.shipping,
    ];
    final bottomTabs = const [
      OrderTab.delivered,
      OrderTab.received,
      OrderTab.cancelled,
      OrderTab.returned,
    ];

    Widget buildTab(OrderTab t) {
      final active = t == current;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => onChanged(t),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: active ? const Color(0xFF2C3C78) : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              t.label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: active ? Colors.cyanAccent : Colors.white70,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x22FFFFFF))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hàng 1: 3 tab đầu
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: topTabs.map(buildTab).toList(),
          ),
          const SizedBox(height: 8),
          // Hàng 2: các tab còn lại
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: bottomTabs.map(buildTab).toList(),
          ),
        ],
      ),
    );
  }
}
