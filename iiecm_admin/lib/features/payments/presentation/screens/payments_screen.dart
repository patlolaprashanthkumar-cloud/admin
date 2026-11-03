import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../providers/payment_providers.dart';
import '../widgets/payment_dashboard_tab.dart';
import '../widgets/payment_reports_tab.dart';
import '../widgets/payment_transactions_tab.dart';
import '../widgets/record_payment_sheet.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        title: const Text('Fee Payments & Invoices'),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.warmCream,
        actions: [
          IconButton(
            tooltip: 'Record Payment',
            icon: const Icon(Icons.add_card_rounded),
            onPressed: () => RecordPaymentSheet.show(context),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(paymentSummaryProvider);
              ref.invalidate(paymentsListProvider);
              ref.invalidate(allStudentFeeProfilesProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryForest,
          indicatorWeight: 3,
          labelColor: AppColors.primaryForest,
          unselectedLabelColor: isDark
              ? AppColors.darkTextSecondary
              : AppColors.textSecondary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.dashboard_rounded, size: 18),
              text: 'Dashboard',
            ),
            Tab(
              icon: Icon(Icons.receipt_long_rounded, size: 18),
              text: 'Transactions',
            ),
            Tab(
              icon: Icon(Icons.assessment_outlined, size: 18),
              text: 'Reports',
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ResponsiveLayout(
          child: TabBarView(
            controller: _tabController,
            children: const [
              PaymentDashboardTab(),
              PaymentTransactionsTab(),
              PaymentReportsTab(),
            ],
          ),
        ),
      ),
    );
  }
}
