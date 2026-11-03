enum PaymentDateFilterType {
  today,
  thisWeek,
  thisMonth,
  lastMonth,
  custom,
  allTime,
}

class PaymentFilter {
  final PaymentDateFilterType dateFilterType;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final String? status; // null for all, or 'pending', 'verified', etc.
  final String? paymentMethod; // null for all, or 'cash', 'upi', etc.
  final String searchQuery;
  final String sortBy; // 'date' or 'amount'
  final bool sortDescending;

  const PaymentFilter({
    this.dateFilterType = PaymentDateFilterType.allTime,
    this.customStartDate,
    this.customEndDate,
    this.status,
    this.paymentMethod,
    this.searchQuery = '',
    this.sortBy = 'date',
    this.sortDescending = true,
  });

  PaymentFilter copyWith({
    PaymentDateFilterType? dateFilterType,
    DateTime? customStartDate,
    DateTime? customEndDate,
    String? status,
    bool clearStatus = false,
    String? paymentMethod,
    bool clearPaymentMethod = false,
    String? searchQuery,
    String? sortBy,
    bool? sortDescending,
  }) {
    return PaymentFilter(
      dateFilterType: dateFilterType ?? this.dateFilterType,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      status: clearStatus ? null : (status ?? this.status),
      paymentMethod: clearPaymentMethod
          ? null
          : (paymentMethod ?? this.paymentMethod),
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      sortDescending: sortDescending ?? this.sortDescending,
    );
  }

  /// Calculates the inclusive start and end DateTime boundaries for this filter
  ({DateTime? start, DateTime? end}) get dateRange {
    final now = DateTime.now();
    switch (dateFilterType) {
      case PaymentDateFilterType.today:
        final start = DateTime(now.year, now.month, now.day);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        return (start: start, end: end);
      case PaymentDateFilterType.thisWeek:
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(monday.year, monday.month, monday.day);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        return (start: start, end: end);
      case PaymentDateFilterType.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        return (start: start, end: end);
      case PaymentDateFilterType.lastMonth:
        final firstOfThisMonth = DateTime(now.year, now.month, 1);
        final lastDayOfLastMonth = firstOfThisMonth.subtract(
          const Duration(days: 1),
        );
        final start = DateTime(
          lastDayOfLastMonth.year,
          lastDayOfLastMonth.month,
          1,
        );
        final end = DateTime(
          lastDayOfLastMonth.year,
          lastDayOfLastMonth.month,
          lastDayOfLastMonth.day,
          23,
          59,
          59,
          999,
        );
        return (start: start, end: end);
      case PaymentDateFilterType.custom:
        return (
          start: customStartDate != null
              ? DateTime(
                  customStartDate!.year,
                  customStartDate!.month,
                  customStartDate!.day,
                )
              : null,
          end: customEndDate != null
              ? DateTime(
                  customEndDate!.year,
                  customEndDate!.month,
                  customEndDate!.day,
                  23,
                  59,
                  59,
                  999,
                )
              : null,
        );
      case PaymentDateFilterType.allTime:
        return (start: null, end: null);
    }
  }
}
