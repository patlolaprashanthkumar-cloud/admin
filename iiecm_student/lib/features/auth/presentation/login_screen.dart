import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import 'providers/auth_provider.dart';
import 'providers/auth_state.dart';

/// Institutional Student Portal Login Screen
///
/// Designed in accordance with the IIECM Modern Academic design language:
/// Concentric brand emblem, institutional Navy/Teal accents, terracotta highlights,
/// warm off-white and dark surfaces, rounded input fields with clear validation,
/// secure credential assistance modals, and responsive layout safety.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    final success = await ref
        .read(authNotifierProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    // If successful, router redirect guard will automatically navigate to '/'
    if (!mounted) return;

    if (!success) {
      final authState = ref.read(authNotifierProvider);
      final error = authState.errorMessage;
      if (error != null && error.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(error)),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
            ),
          ),
        );
      }
    }
  }

  void _showForgotPasswordSheet() {
    final resetEmailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    bool isSending = false;
    String? resetError;
    String? resetSuccess;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final theme = Theme.of(ctx);
            final isDark = theme.brightness == Brightness.dark;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppConstants.radiusXl),
                  ),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.borderSubtle,
                  ),
                ),
                padding: const EdgeInsets.all(AppConstants.spacingLg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.borderSubtle,
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusFull,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceElevated
                                : AppColors.forestSoft,
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusMd,
                            ),
                            border: Border.all(
                              color: AppColors.primaryNavy.withValues(
                                alpha: 0.15,
                              ),
                            ),
                          ),
                          child: const Icon(
                            Icons.lock_reset_rounded,
                            color: AppColors.primaryNavy,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Reset Student Password',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Institutional Credential Recovery',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    Text(
                      'Enter your registered student email address. We will dispatch a secure password reset link pointing to the IIECM Authentication Portal (auth.iiecm.org).',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingMd),

                    if (resetSuccess != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppConstants.spacingSm),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusSm,
                          ),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.success,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                resetSuccess!,
                                style: const TextStyle(
                                  color: AppColors.success,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingMd),
                    ],

                    if (resetError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppConstants.spacingSm),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusSm,
                          ),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.error,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                resetError!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingMd),
                    ],

                    TextFormField(
                      controller: resetEmailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Registered Student Email',
                        hintText: 'e.g. student@iiecm.org',
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          size: 18,
                          color: AppColors.primaryNavy,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? AppColors.darkSurfaceElevated
                            : AppColors.warmCreamLight,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusSm,
                          ),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.borderSubtle,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusSm,
                          ),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.borderSubtle,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusSm,
                          ),
                          borderSide: const BorderSide(
                            color: AppColors.primaryNavy,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingLg),

                    AppButton(
                      label: isSending
                          ? 'Sending Link...'
                          : 'Send Password Reset Link',
                      isLoading: isSending,
                      icon: Icons.send_rounded,
                      onPressed: isSending
                          ? null
                          : () async {
                              final email = resetEmailController.text.trim();
                              if (email.isEmpty || !email.contains('@')) {
                                setModalState(() {
                                  resetError = 'Please enter a valid registered email address.';
                                });
                                return;
                              }

                              setModalState(() {
                                isSending = true;
                                resetError = null;
                                resetSuccess = null;
                              });

                              try {
                                await ref
                                    .read(authNotifierProvider.notifier)
                                    .sendPasswordReset(email);
                                setModalState(() {
                                  isSending = false;
                                  resetSuccess =
                                      'Password reset instructions have been dispatched to $email.';
                                });
                              } catch (e) {
                                setModalState(() {
                                  isSending = false;
                                  resetError = e.toString();
                                });
                              }
                            },
                    ),
                    const SizedBox(height: AppConstants.spacingSm),
                    AppButton(
                      label: 'Back to Sign In',
                      variant: AppButtonVariant.outline,
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                    const SizedBox(height: AppConstants.spacingSm),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showHelpSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppConstants.radiusXl),
            ),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
            ),
          ),
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(
                      AppConstants.radiusFull,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceElevated
                          : AppColors.forestSoft,
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusMd,
                      ),
                      border: Border.all(
                        color: AppColors.primaryNavy.withValues(alpha: 0.15),
                      ),
                    ),
                    child: const Icon(
                      Icons.help_outline_rounded,
                      color: AppColors.primaryNavy,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Student Credential Support',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Office of the Academic Registrar',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Text(
                'Student accounts are provisioned by the IIECM Academic Registrar upon enrollment.\n\n'
                '• Use the email address registered during your student enrollment.\n'
                '• If you recently received an invitation email, click the link to set your password at auth.iiecm.org first.\n'
                '• If you require assistance, contact the Registrar Office at registrar@iiecm.org.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingLg),
              AppButton(
                label: 'Close',
                variant: AppButtonVariant.outline,
                onPressed: () => Navigator.of(ctx).pop(),
              ),
              const SizedBox(height: AppConstants.spacingSm),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.backgroundWarmOffWhite,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingLg,
              vertical: AppConstants.spacingXl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Institutional Emblem / Brand Header
                    Center(
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceElevated
                              : AppColors.forestSoft,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryNavy.withValues(
                              alpha: isDark ? 0.4 : 0.2,
                            ),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.school_rounded,
                            size: 38,
                            color: isDark
                                ? AppColors.accentOrangeLight
                                : AppColors.primaryNavy,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingMd),

                    // App Title & Tagline
                    Text(
                      AppConstants.appName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(
                      AppConstants.studentPortalTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.terracotta,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingSm),
                    Text(
                      'Sign in with your registered student credentials to access your academic curriculum, examination checkpoints, and institutional records.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingLg),

                    // Backend Configuration Warning Banner
                    if (authState.isUnconfigured) ...[
                      Container(
                        padding: const EdgeInsets.all(AppConstants.spacingMd),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusMd,
                          ),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.warning,
                              size: 20,
                            ),
                            const SizedBox(width: AppConstants.spacingSm),
                            Expanded(
                              child: Text(
                                'Supabase is not configured. Run the app with: flutter run --dart-define-from-file=.env.json',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : const Color(0xFF92400E),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingMd),
                    ],

                    // Verification Error / Retry Alert Banner
                    if (authState.status == AuthStatus.verificationError) ...[
                      Container(
                        padding: const EdgeInsets.all(AppConstants.spacingMd),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusMd,
                          ),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.wifi_off_rounded,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                                const SizedBox(width: AppConstants.spacingSm),
                                Expanded(
                                  child: Text(
                                    authState.errorMessage ?? 'Network error connecting to student database.',
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppConstants.spacingSm),
                            AppButton(
                              label: 'Retry Connection',
                              icon: Icons.refresh_rounded,
                              variant: AppButtonVariant.outline,
                              onPressed: () => ref
                                  .read(authNotifierProvider.notifier)
                                  .retryVerification(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingMd),
                    ] else if (authState.errorMessage != null &&
                        !authState.isUnconfigured) ...[
                      // Error message banner
                      Container(
                        padding: const EdgeInsets.all(AppConstants.spacingMd),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusMd,
                          ),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: AppConstants.spacingSm),
                            Expanded(
                              child: Text(
                                authState.errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingMd),
                    ],

                    // Card Form Container
                    AppCard(
                      padding: const EdgeInsets.all(AppConstants.spacingLg),
                      backgroundColor: isDark
                          ? AppColors.darkSurface
                          : AppColors.white,
                      borderColor: isDark
                          ? AppColors.darkBorder
                          : AppColors.borderSubtle,
                      borderRadius: AppConstants.radiusLg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Registered Email Field
                          Text(
                            'Registered Email',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingSm),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'e.g. student@iiecm.org',
                              hintStyle: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextSecondary.withValues(
                                        alpha: 0.6,
                                      )
                                    : AppColors.textMuted,
                              ),
                              prefixIcon: const Icon(
                                Icons.email_outlined,
                                size: 18,
                                color: AppColors.primaryNavy,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? AppColors.darkSurfaceElevated
                                  : AppColors.warmCreamLight,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.radiusSm,
                                ),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.borderSubtle,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.radiusSm,
                                ),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.borderSubtle,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.radiusSm,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.primaryNavy,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your registered student email';
                              }
                              final trimmed = val.trim();
                              if (!trimmed.contains('@') ||
                                  !trimmed.contains('.')) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppConstants.spacingMd),

                          // Password Field
                          Text(
                            'Password',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingSm),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleSignIn(),
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter your student portal password',
                              hintStyle: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextSecondary.withValues(
                                        alpha: 0.6,
                                      )
                                    : AppColors.textMuted,
                              ),
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                size: 18,
                                color: AppColors.primaryNavy,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 18,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                ),
                                tooltip: _obscurePassword
                                    ? 'Show password'
                                    : 'Hide password',
                                onPressed: () {
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
                                },
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? AppColors.darkSurfaceElevated
                                  : AppColors.warmCreamLight,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.radiusSm,
                                ),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.borderSubtle,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.radiusSm,
                                ),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.borderSubtle,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.radiusSm,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.primaryNavy,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your password';
                              }
                              if (val.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppConstants.spacingSm),

                          // Remember Me & Forgot Password Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      activeColor: AppColors.primaryNavy,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      onChanged: (val) {
                                        setState(
                                          () => _rememberMe = val ?? true,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: AppConstants.spacingSm),
                                  Text(
                                    'Remember Me',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: _showForgotPasswordSheet,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: AppColors.terracotta,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppConstants.spacingLg),

                          // Sign In Button (Test Contract: 'Sign In to Student Portal')
                          AppButton(
                            label: 'Sign In to Student Portal',
                            icon: Icons.login_rounded,
                            isLoading: isLoading,
                            onPressed: isLoading ? null : _handleSignIn,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingMd),

                    // Help & Enrollment Guidance Button
                    Center(
                      child: TextButton.icon(
                        onPressed: _showHelpSheet,
                        icon: const Icon(Icons.help_outline_rounded, size: 16),
                        label: const Text('New Student or Need Help?'),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingSm),

                    // Academic Security Banner
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.verified_user_outlined,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: AppConstants.spacingXs),
                          Flexible(
                            child: Text(
                              'Authorized Student & Candidate Access Only',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
