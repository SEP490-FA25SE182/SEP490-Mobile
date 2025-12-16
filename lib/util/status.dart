import 'package:flutter/material.dart';

/// ===== TRANSACTION (Byte) =====
/// 0: NOT_PAID, 1: PROCESSING, 2: CANCELED, 3: PAID
String transactionStatusLabel(int? s) {
  switch (s) {
    case 0: return 'Chưa thanh toán';
    case 1: return 'Đang xử lý';
    case 2: return 'Đã hủy';
    case 3: return 'Đã thanh toán';
    default: return 'Không xác định';
  }
}

Color transactionStatusColor(int? s) {
  switch (s) {
    case 0: return Colors.orange;              // NOT_PAID
    case 1: return Colors.blue;                // PROCESSING
    case 2: return Colors.red;                 // CANCELED
    case 3: return Colors.green;               // PAID
    default: return Colors.grey;
  }
}

IconData transactionStatusIcon(int? s) {
  switch (s) {
    case 0: return Icons.payments_outlined;
    case 1: return Icons.hourglass_top_rounded;
    case 2: return Icons.cancel_outlined;
    case 3: return Icons.verified_rounded;
    default: return Icons.help_outline;
  }
}

/// ===== ORDER (Byte) =====
/// 0 UNORDERED, 1 PENDING, 2 PROCESSING, 3 SHIPPING, 4 DELIVERED, 5 CANCELLED, 6 RETURNED
String orderStatusLabel(int? s) {
  switch (s) {
    case 0: return 'Chưa đặt';
    case 1: return 'Chờ xác nhận';
    case 2: return 'Đang chuẩn bị';
    case 3: return 'Đang giao';
    case 4: return 'Đã giao';
    case 5: return 'Đã nhận';
    case 6: return 'Đã hủy';
    case 7: return 'Đã trả hàng';
    default: return 'Không xác định';
  }
}

Color orderStatusColor(int? s) {
  switch (s) {
    case 0: return Colors.grey;                 // UNORDERED
    case 1: return Colors.orange;               // PENDING
    case 2: return Colors.blue;                 // PROCESSING
    case 3: return Colors.indigo;               // SHIPPING
    case 4: return Colors.green;                // DELIVERED
    case 5: return Colors.red;                  // CANCELLED
    case 6: return Colors.deepOrange;           // RETURNED
    default: return Colors.grey;
  }
}

IconData orderStatusIcon(int? s) {
  switch (s) {
    case 0: return Icons.shopping_cart_outlined;
    case 1: return Icons.schedule_rounded;
    case 2: return Icons.build_circle_outlined;
    case 3: return Icons.local_shipping_outlined;
    case 4: return Icons.check_circle_outline;
    case 5: return Icons.cancel_outlined;
    case 6: return Icons.undo_rounded;
    default: return Icons.help_outline;
  }
}

/// ===== BOOK (Byte) =====
/// 0 IN_PROGRESS, 1 COMPLETED, 2 DROPPED
String bookStatusLabel(int? s) {
  switch (s) {
    case 0: return 'Đang viết';
    case 1: return 'Hoàn thành';
    case 2: return 'Tạm dừng';
    default: return 'Không xác định';
  }
}

Color bookStatusColor(int? s) {
  switch (s) {
    case 0: return Colors.blue;                 // IN_PROGRESS
    case 1: return Colors.green;                // COMPLETED
    case 2: return Colors.red;                  // DROPPED
    default: return Colors.grey;
  }
}

IconData bookStatusIcon(int? s) {
  switch (s) {
    case 0: return Icons.edit_note_rounded;
    case 1: return Icons.emoji_events_outlined;
    case 2: return Icons.remove_circle_outline;
    default: return Icons.help_outline;
  }
}

/// ===== PUBLICATION (Byte) =====
/// 0 DRAFT, 1 PUBLISHED, 2 ARCHIVED, 3 PENDING
String publicationStatusLabel(int? s) {
  switch (s) {
    case 0: return 'Bản nháp';
    case 1: return 'Đã xuất bản';
    case 2: return 'Lưu trữ';
    case 3: return 'Chờ duyệt';
    default: return 'Không xác định';
  }
}

Color publicationStatusColor(int? s) {
  switch (s) {
    case 0: return Colors.grey;                 // DRAFT
    case 1: return Colors.green;                // PUBLISHED
    case 2: return Colors.blueGrey;             // ARCHIVED
    case 3: return Colors.orange;               // PENDING
    default: return Colors.grey;
  }
}

IconData publicationStatusIcon(int? s) {
  switch (s) {
    case 0: return Icons.drafts_outlined;
    case 1: return Icons.public_rounded;
    case 2: return Icons.archive_outlined;
    case 3: return Icons.schedule_rounded;
    default: return Icons.help_outline;
  }
}

/// ===== CHAPTER (Byte) =====
/// 0 IN_REVIEW, 1 REJECTED, 2 APPROVED
String chapterStatusLabel(int? s) {
  switch (s) {
    case 0: return 'Đang duyệt';
    case 1: return 'Từ chối';
    case 2: return 'Đã duyệt';
    default: return 'Không xác định';
  }
}

Color chapterStatusColor(int? s) {
  switch (s) {
    case 0: return Colors.orange;               // IN_REVIEW
    case 1: return Colors.red;                  // REJECTED
    case 2: return Colors.green;                // APPROVED
    default: return Colors.grey;
  }
}

IconData chapterStatusIcon(int? s) {
  switch (s) {
    case 0: return Icons.visibility_outlined;
    case 1: return Icons.close_rounded;
    case 2: return Icons.verified_rounded;
    default: return Icons.help_outline;
  }
}
