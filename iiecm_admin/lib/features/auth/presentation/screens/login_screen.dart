import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../widgets/auth_text_field.dart';
import 'forgot_password_sheet.dart';

/// Administrator Login Screen adhering to IIECM Institutional Brand System
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    await ref
        .read(authNotifierProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  Future<void> _retryVerification() async {
    await ref.read(authNotifierProvider.notifier).retryProfileVerification();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authNotifierProvider);
    final isAuthenticating = authState.status == AuthStatus.authenticating;
    final isUnconfigured =
        authState.status == AuthStatus.unconfigured ||
        !AppConfig.isSupabaseConfigured;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      body: SafeArea(
        child: ResponsiveLayout(
          maxWidth: 480,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Institutional Emblem & Brand Mark
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.forestDark,
                              AppColors.primaryForest,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusMedium,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryForest.withValues(
                                alpha: 0.25,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.school_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'IIECM',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppConstants.appName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppConstants.appTagline,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Admin-only Security Scope Badge
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.forestSoft,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primaryForest.withValues(
                              alpha: 0.25,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.admin_panel_settings_outlined,
                              size: 15,
                              color: AppColors.primaryForest,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Admin & Super Admin Portal',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.primaryForest,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),

                    // Unconfigured Environment Warning
                    if (isUnconfigured) ...[
                      AppCard(
                        backgroundColor: const Color(0xFFFEF3C7),
                        borderSide: const BorderSide(color: Color(0xFFF59E0B)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Color(0xFFB45309),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Supabase Not Configured',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: const Color(0xFF92400E),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please provide SUPABASE_URL and SUPABASE_ANON_KEY when running the app, for example:\n\nflutter run --dart-define-from-file=.env.json',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF92400E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Error Message Banner (Invalid credentials, non-admin denial, profile missing)
                    if (authState.errorMessage != null && !isUnconfigured) ...[
                      AppCard(
                        backgroundColor: authState.isRetryable
                            ? AppColors.terracottaSoft
                            : const Color(0xFFFDF2F2),
                        borderSide: BorderSide(
                          color: authState.isRetryable
                              ? AppColors.accentTerracotta
                              : const Color(0xFFF8B4B4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  authState.isRetryable
                                      ? Icons.wifi_off_rounded
                                      : Icons.error_outline,
                                  size: 20,
                                  color: authState.isRetryable
                                      ? AppColors.accentTerracotta
                                      : AppColors.error,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    authState.errorMessage!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: authState.isRetryable
                                          ? AppColors.terracottaDark
                                          : AppColors.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (authState.isRetryable) ...[
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: OutlinedButton.icon(
                                  onPressed: isAuthenticating
                                      ? null
                                      : _retryVerification,
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text(
                                    'Retry Profile Verification',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    foregroundColor: AppColors.accentTerracotta,
                                    side: const BorderSide(
                                      color: AppColors.accentTerracotta,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Login Card
                    AppCard(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AuthTextField(
                            controller: _emailController,
                            label: 'Administrator Email',
                            hint: 'admin@iiecm.org',
                            prefixIcon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            enabled: !isAuthenticating && !isUnconfigured,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email.';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email address.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          AuthTextField(
                            controller: _passwordController,
                            label: 'Password',
                            hint: '••••••••',
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            enabled: !isAuthenticating && !isUnconfigured,
                            onFieldSubmitted: (_) => _submitLogin(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: isAuthenticating || isUnconfigured
                                  ? null
                                  : () => ForgotPasswordSheet.show(
                                      context,
                                      initialEmail: _emailController.text
                                          .trim(),
                                    ),
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                foregroundColor: AppColors.accentTerracotta,
                              ),
                              child: Text(
                                'Forgot password?',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: AppColors.accentTerracotta,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          FilledButton(
                            onPressed: isAuthenticating || isUnconfigured
                                ? null
                                : _submitLogin,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryForest,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.radiusMedium,
                                ),
                              ),
                            ),
                            child: isAuthenticating
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'Sign In as Administrator',
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.labelLarge
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Security & Privacy Notice
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          Text(
                            'Secured with Supabase Auth & RLS policies',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
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
