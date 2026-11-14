import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import 'providers/auth_provider.dart';
import 'providers/auth_state.dart';

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

    final success = await ref.read(authNotifierProvider.notifier).login(
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
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(error)),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showForgotPasswordSheet() {
    final resetEmailController = TextEditingController(text: _emailController.text.trim());
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
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.forestSoft,
                            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                          ),
                          child: const Icon(Icons.lock_reset_rounded, color: AppColors.primaryForest),
                        ),
                        const SizedBox(width: AppConstants.spacingSm),
                        Expanded(
                          child: Text(
                            'Reset Student Password',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingSm),
                    Text(
                      'Enter your registered student email address. We will send a secure password reset link pointing to the IIECM Authentication Portal (auth.iiecm.org).',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingMd),

                    if (resetSuccess != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppConstants.spacingSm),
                        decoration: BoxDecoration(
                          color: AppColors.forestSoft,
                          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                          border: Border.all(color: AppColors.primaryForest.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppColors.primaryForest, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                resetSuccess!,
                                style: const TextStyle(color: AppColors.primaryForest, fontSize: 13),
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
                          color: const Color(0xFFFDE8E8),
                          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                resetError!,
                                style: const TextStyle(color: AppColors.error, fontSize: 13),
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
                      decoration: const InputDecoration(
                        labelText: 'Registered Student Email',
                        hintText: 'e.g. student@iiecm.org',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingLg),

                    AppButton(
                      label: isSending ? 'Sending Link...' : 'Send Password Reset Link',
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
                                await ref.read(authNotifierProvider.notifier).sendPasswordReset(email);
                                setModalState(() {
                                  isSending = false;
                                  resetSuccess = 'Password reset instructions have been dispatched to $email.';
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
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.forestSoft,
                      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    ),
                    child: const Icon(Icons.help_outline_rounded, color: AppColors.primaryForest),
                  ),
                  const SizedBox(width: AppConstants.spacingSm),
                  Expanded(
                    child: Text(
                      'Student Credential Support',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
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
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  height: 1.5,
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
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.forestDark : AppColors.forestSoft,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? AppColors.forestLight
                                : AppColors.primaryForest.withValues(alpha: 0.2),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.school_rounded,
                          size: 36,
                          color: isDark ? AppColors.forestLight : AppColors.primaryForest,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingMd),

                    // App Title & Tagline
                    Text(
                      AppConstants.appName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(
                      AppConstants.studentPortalTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.terracotta,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingSm),
                    Text(
                      'Sign in with your registered student email address to access your courses, timetable, and clinical assessments.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingLg),

                    // Backend Configuration Warning Banner
                    if (authState.isUnconfigured) ...[
                      Container(
                        padding: const EdgeInsets.all(AppConstants.spacingMd),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
                            const SizedBox(width: AppConstants.spacingSm),
                            Expanded(
                              child: Text(
                                'Supabase is not configured. Run the app with: flutter run --dart-define-from-file=.env.json',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF92400E),
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
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 20),
                                const SizedBox(width: AppConstants.spacingSm),
                                Expanded(
                                  child: Text(
                                    authState.errorMessage ?? 'Network error connecting to student database.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.error,
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
                              onPressed: () => ref.read(authNotifierProvider.notifier).retryVerification(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingMd),
                    ] else if (authState.errorMessage != null && !authState.isUnconfigured) ...[
                      // Error message banner
                      Container(
                        padding: const EdgeInsets.all(AppConstants.spacingMd),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                            const SizedBox(width: AppConstants.spacingSm),
                            Expanded(
                              child: Text(
                                authState.errorMessage!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.error,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Registered Email Field
                          Text(
                            'Registered Email',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingSm),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'e.g. student@iiecm.org',
                              prefixIcon: Icon(Icons.email_outlined, size: 20),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your registered student email';
                              }
                              final trimmed = val.trim();
                              if (!trimmed.contains('@') || !trimmed.contains('.')) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppConstants.spacingMd),

                          // Password Field
                          Text(
                            'Password',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingSm),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleSignIn(),
                            decoration: InputDecoration(
                              hintText: 'Enter your student portal password',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
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
                                      activeColor: AppColors.primaryForest,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      onChanged: (val) {
                                        setState(() => _rememberMe = val ?? true);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: AppConstants.spacingSm),
                                  Text(
                                    'Remember Me',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: _showForgotPasswordSheet,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Forgot Password?',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.terracotta,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppConstants.spacingLg),

                          // Sign In Button
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
                          foregroundColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: AppColors.textMuted,
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
