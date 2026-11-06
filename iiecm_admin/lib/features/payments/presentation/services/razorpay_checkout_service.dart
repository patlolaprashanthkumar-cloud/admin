import 'dart:developer' as developer;

import 'package:razorpay_flutter/razorpay_flutter.dart';

typedef RazorpaySuccessCallback = void Function(
  PaymentSuccessResponse response,
);
typedef RazorpayFailureCallback = void Function(
  PaymentFailureResponse response,
);
typedef RazorpayWalletCallback = void Function(ExternalWalletResponse response);

/// Service managing the lifecycle of Razorpay Standard Flutter Checkout
class RazorpayCheckoutService {
  late Razorpay _razorpay;
  bool _isInitialized = false;
  bool _isCheckoutActive = false;

  RazorpaySuccessCallback? _onSuccess;
  RazorpayFailureCallback? _onFailure;
  RazorpayWalletCallback? _onWallet;

  bool get isCheckoutActive => _isCheckoutActive;

  /// Resets active checkout flag in case of network cancellations or timeouts
  void resetActiveState() {
    _isCheckoutActive = false;
  }

  /// Initializes the Razorpay instance and attaches listeners
  void initialize({
    required RazorpaySuccessCallback onSuccess,
    required RazorpayFailureCallback onFailure,
    RazorpayWalletCallback? onWallet,
  }) {
    if (_isInitialized) {
      _razorpay.clear();
    }

    _razorpay = Razorpay();
    _onSuccess = onSuccess;
    _onFailure = onFailure;
    _onWallet = onWallet;

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _isInitialized = true;
    _isCheckoutActive = false;
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    developer.log(
      'Razorpay Checkout SUCCESS: paymentId=${response.paymentId}, orderId=${response.orderId}',
      name: 'RazorpayCheckoutService',
    );
    _isCheckoutActive = false;
    _onSuccess?.call(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    developer.log(
      'Razorpay Checkout ERROR: code=${response.code}, message=${response.message}',
      name: 'RazorpayCheckoutService',
    );
    _isCheckoutActive = false;
    _onFailure?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    developer.log(
      'Razorpay Checkout EXTERNAL WALLET: walletName=${response.walletName}',
      name: 'RazorpayCheckoutService',
    );
    _isCheckoutActive = false;
    _onWallet?.call(response);
  }

  /// Opens the official Razorpay Standard Checkout Sheet
  void openCheckout({
    required String keyId,
    required String orderId,
    required int amountPaise,
    required String studentName,
    String? studentEmail,
    String? studentPhone,
    String? courseTitle,
    String? institutionalTitle,
  }) {
    if (!_isInitialized) {
      throw StateError(
        'RazorpayCheckoutService must be initialized before openCheckout.',
      );
    }

    if (_isCheckoutActive) {
      developer.log(
        'Checkout already active. Prevented duplicate launch.',
        name: 'RazorpayCheckoutService',
      );
      return;
    }

    _isCheckoutActive = true;

    final description = (courseTitle != null && courseTitle.isNotEmpty)
        ? 'Course Fee: $courseTitle'
        : (institutionalTitle ?? 'IIECM Institutional Program Fee');

    final Map<String, dynamic> options = {
      'key': keyId.trim(),
      'amount': amountPaise,
      'name': 'IIECM Institutional LMS',
      'description': description,
      'order_id': orderId.trim(),
      'timeout': 300, // 5 minutes session
      'prefill': {
        if (studentPhone != null && studentPhone.trim().isNotEmpty)
          'contact': studentPhone.trim(),
        if (studentEmail != null && studentEmail.trim().isNotEmpty)
          'email': studentEmail.trim(),
        'name': studentName.trim(),
      },
      'theme': {
        'color': '#245B43', // AppColors.primaryForest
      },
      'external': {
        'wallets': ['paytm', 'mobikwik', 'freecharge'],
      },
      'retry': {'enabled': true, 'max_count': 3},
      'modal': {'confirm_close': true},
    };

    try {
      _razorpay.open(options);
    } catch (e, stack) {
      _isCheckoutActive = false;
      developer.log(
        'Failed to open Razorpay checkout: $e',
        name: 'RazorpayCheckoutService',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Disposes listeners and cleans up Razorpay instance
  void dispose() {
    if (_isInitialized) {
      _razorpay.clear();
      _isInitialized = false;
      _isCheckoutActive = false;
    }
  }
}
