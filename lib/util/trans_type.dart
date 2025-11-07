enum TransactionType { PAYMENT, REFUND, SETTLEMENT, DEPOSIT, WITHDRAW }

TransactionType parseTransactionType(dynamic v) {
  if (v == null) return TransactionType.PAYMENT;
  if (v is TransactionType) return v;

  final s = v.toString().trim().toUpperCase();
  switch (s) {
    case 'REFUND': return TransactionType.REFUND;
    case 'SETTLEMENT': return TransactionType.SETTLEMENT;
    case 'DEPOSIT': return TransactionType.DEPOSIT;
    case 'WITHDRAW': return TransactionType.WITHDRAW;
    case 'PAYMENT':
    default: return TransactionType.PAYMENT;
  }
}
