import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/api_config.dart';
import '../core/utils.dart';
import '../models/user.dart';

/// Application authentication state.
class AuthState {
  const AuthState({
    this.session,
    this.loading = false,
    this.error,
    this.restoring = false,
    this.resetEmail,
    this.devCode,
    this.resetToken,
  });

  final AuthSession? session;
  final bool loading;

  /// True while the persisted session is being restored on startup.
  final bool restoring;
  final String? error;

  /// Email/phone used to start the password reset flow (used for resend).
  final String? resetEmail;

  /// Development-only verification code returned by the backend.
  final String? devCode;

  /// One-time token returned once the reset OTP has been verified.
  final String? resetToken;

  bool get isLoggedIn => session != null;

  bool get hasPendingReset => resetEmail != null;

  AuthState copyWith({
    AuthSession? session,
    bool? loading,
    bool? restoring,
    String? error,
    String? resetEmail,
    String? devCode,
    String? resetToken,
    bool clearSession = false,
    bool clearError = false,
    bool clearReset = false,
  }) => AuthState(
    session: clearSession ? null : (session ?? this.session),
    loading: loading ?? this.loading,
    restoring: restoring ?? this.restoring,
    error: clearError ? null : (error ?? this.error),
    resetEmail: clearReset ? null : (resetEmail ?? this.resetEmail),
    devCode: clearReset ? null : (devCode ?? this.devCode),
    resetToken: clearReset ? null : (resetToken ?? this.resetToken),
  );
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    _restore();
    return const AuthState(restoring: true);
  }

  final _api = ApiClient.instance;

  /// Locally-built super-admin session used when [kDemoMode] is on, so the app
  /// can be demonstrated without a backend.
  static final _demoUser = UserRecord(
    id: 'demo-super-admin',
    fullname: 'Demo Super Admin',
    email: kAdminEmail,
    role: 'super_admin',
    status: 'active',
  );

  Future<void> _restore() async {
    String? token;
    try {
      token = await ApiClient.readToken();
    } catch (_) {
      // Secure storage is unavailable (e.g. fresh install / test env) —
      // treat as signed out.
      state = const AuthState();
      return;
    }
    if (token == null) {
      state = const AuthState();
      return;
    }
    if (kDemoMode) {
      // The demo token is not a real JWT — skip the `/auth/me` round-trip.
      state = AuthState(
        session: AuthSession(token: token, user: _demoUser),
        restoring: false,
      );
      return;
    }
    try {
      final me = await _api.get('/auth/me');
      final user = UserRecord.fromJson(singleJson(me, ['user']));
      state = AuthState(
        session: AuthSession(token: token, user: user),
        restoring: false,
      );
    } catch (_) {
      await ApiClient.clearToken();
      state = const AuthState();
    }
  }

  /// Logs in with an email or a phone number plus a password.
  Future<bool> login(String emailOrPhone, String password) async {
    if (kDemoMode) {
      // Demo mode: any non-empty credentials open a role-specific local account.
      // Demo identities route to the admin, vendor or buyer experience locally.
      final identity = emailOrPhone.trim();
      if (identity.isEmpty || password.isEmpty) {
        state = state.copyWith(
          loading: false,
          error: 'Enter an email and a password.',
        );
        return false;
      }
      final normalizedIdentity = identity.toLowerCase();
      final role =
          normalizedIdentity.contains('admin')
              ? 'super_admin'
              : normalizedIdentity.contains('supplier')
              ? 'supplier'
              : normalizedIdentity.contains('vendor')
              ? 'vendor'
              : normalizedIdentity.contains('affiliate')
              ? 'affiliate'
              : 'buyer';
      state = AuthState(
        session: AuthSession(
          token: 'demo-token',
          user:
              role == 'super_admin'
                  ? _demoUser
                  : UserRecord(
                    id: 'demo-$role',
                    fullname:
                        'Demo ${role[0].toUpperCase()}${role.substring(1)}',
                    email: identity,
                    role: role,
                    companyName:
                        role == 'supplier' ? 'Rwanda Fresh Produce Co.' : null,
                    status: 'active',
                  ),
        ),
      );
      return true;
    }
    state = state.copyWith(loading: true, clearError: true);
    try {
      final isEmail = emailOrPhone.contains('@');
      final body = {
        if (isEmail) 'email': emailOrPhone else 'phone': emailOrPhone,
        'password': password,
      };
      final res = await _api.post('/auth/login', body: body);
      final token = res['token'] as String?;
      final user = UserRecord.fromJson(singleJson(res, ['user']));
      if (token == null) throw ApiException('Login failed: no token returned');
      await ApiClient.writeToken(token);
      state = AuthState(session: AuthSession(token: token, user: user));
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: friendlyError(e));
      return false;
    }
  }

  /// Creates a new account for one of the supported user types
  /// (buyer, vendor, supplier or affiliate).
  Future<bool> register({
    required String fullName,
    required String telephone,
    String? email,
    String? gender,
    String role = 'buyer',
    String? companyName,
    required String password,
  }) async {
    if (kDemoMode) {
      // Demo mode: create the session locally, no backend call.
      state = AuthState(
        session: AuthSession(
          token: 'demo-token',
          user: UserRecord(
            id: 'demo-$role',
            fullname: fullName,
            email: email?.trim().isNotEmpty == true ? email!.trim() : null,
            phone: telephone.trim(),
            role: role,
            gender: gender,
            companyName:
                companyName?.trim().isNotEmpty == true
                    ? companyName!.trim()
                    : null,
            status: 'active',
          ),
        ),
      );
      return true;
    }
    state = state.copyWith(loading: true, clearError: true);
    try {
      final res = await _api.post(
        '/auth/register',
        body: {
          'Fullname': fullName,
          if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
          'phone': telephone.trim(),
          if (gender != null && gender.isNotEmpty) 'gender': gender,
          'role': role,
          if (companyName != null && companyName.trim().isNotEmpty)
            'companyName': companyName.trim(),
          'password': password,
        },
      );
      final token = res['token'] as String?;
      final user = UserRecord.fromJson(singleJson(res, ['user']));
      if (token == null) {
        throw ApiException('Registration failed: no token returned');
      }
      await ApiClient.writeToken(token);
      state = AuthState(session: AuthSession(token: token, user: user));
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: friendlyError(e));
      return false;
    }
  }

  Future<void> logout() async {
    await ApiClient.clearToken();
    state = const AuthState();
  }

  /// Abandons an in-progress password reset (used when the user changes the
  /// email/phone they entered).
  void clearResetFlow() {
    state = state.copyWith(clearReset: true);
  }

  /// Starts the password reset flow: requests a verification code for the
  /// registered email or phone.
  Future<bool> forgotPassword(String emailOrPhone) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final identity = emailOrPhone.trim();
      final isEmail = identity.contains('@');
      final res = await _api.post(
        '/auth/forgot-password',
        body: {if (isEmail) 'email': identity else 'phone': identity},
      );
      state = state.copyWith(
        loading: false,
        resetEmail: identity,
        devCode: res is Map ? res['devCode']?.toString() : null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: friendlyError(e));
      return false;
    }
  }

  /// Verifies the reset code and stores the returned one-time reset token.
  Future<bool> verifyResetOtp(String code) async {
    final email = state.resetEmail;
    if (email == null) {
      state = state.copyWith(error: 'Start the reset flow again.');
      return false;
    }
    state = state.copyWith(loading: true, clearError: true);
    try {
      final identity = email.trim();
      final isEmail = identity.contains('@');
      final res = await _api.post(
        '/auth/verify-reset-otp',
        body: {
          if (isEmail) 'email': identity else 'phone': identity,
          'code': code,
        },
      );
      final token = res is Map ? res['resetToken']?.toString() : null;
      if (token == null || token.isEmpty) {
        throw ApiException('Code verified but no reset token was returned.');
      }
      state = state.copyWith(loading: false, resetToken: token);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: friendlyError(e));
      return false;
    }
  }

  /// Updates the password with the verified reset token.
  Future<bool> resetPassword(String newPassword) async {
    final token = state.resetToken;
    if (token == null) {
      state = state.copyWith(error: 'Verify your code before resetting.');
      return false;
    }
    state = state.copyWith(loading: true, clearError: true);
    try {
      await _api.post(
        '/auth/reset-password',
        body: {'resetToken': token, 'newPassword': newPassword},
      );
      state = state.copyWith(loading: false, clearReset: true);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: friendlyError(e));
      return false;
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

final currentUserProvider = Provider<UserRecord?>(
  (ref) => ref.watch(authControllerProvider).session?.user,
);

/// The landing route for a signed-in user based on their role.
/// Mirrors the frontend role routing (vendor/supplier/affiliate/delivery/admin).
String roleHome(UserRecord user) {
  switch (user.userType) {
    case 'super_admin':
      return '/admin';
    case 'supplier':
      return '/supplier';
    case 'affiliate':
      return '/affiliate';
    case 'vendor':
      return '/vendor';
    default:
      return '/home';
  }
}
