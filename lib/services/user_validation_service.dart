import 'package:cloud_firestore/cloud_firestore.dart';

class UniquenessCheckResult {
  final bool isAvailable;
  final String? message;
  final String? matchedField;

  const UniquenessCheckResult({
    required this.isAvailable,
    this.message,
    this.matchedField,
  });
}

class UserValidationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Checks if a 10-digit mobile number is already registered in Firestore.
  static Future<UniquenessCheckResult> checkMobileAvailability(String mobile) async {
    final clean = mobile.replaceAll(RegExp(r'\D'), '');
    final tenDigits = clean.length >= 10 ? clean.substring(clean.length - 10) : clean;

    if (tenDigits.length != 10) {
      return const UniquenessCheckResult(
        isAvailable: false,
        message: 'Please enter a valid 10-digit mobile number.',
      );
    }

    try {
      final snap1 = await _db
          .collection('users')
          .where('mobile', isEqualTo: tenDigits)
          .limit(1)
          .get();

      if (snap1.docs.isNotEmpty) {
        return UniquenessCheckResult(
          isAvailable: false,
          message: 'Mobile number +91 $tenDigits is already registered, use different.',
          matchedField: 'mobile',
        );
      }

      final snap2 = await _db
          .collection('users')
          .where('phone', isEqualTo: tenDigits)
          .limit(1)
          .get();

      if (snap2.docs.isNotEmpty) {
        return UniquenessCheckResult(
          isAvailable: false,
          message: 'Mobile number +91 $tenDigits is already registered, use different.',
          matchedField: 'mobile',
        );
      }
    } catch (e) {
      // Allow fallback if network glitch or permissions pending
    }

    return const UniquenessCheckResult(isAvailable: true);
  }

  /// Checks if an email address is already registered in Firestore.
  static Future<UniquenessCheckResult> checkEmailAvailability(String email) async {
    final clean = email.trim().toLowerCase();
    if (clean.isEmpty || !clean.contains('@')) {
      return const UniquenessCheckResult(
        isAvailable: false,
        message: 'Please enter a valid email address.',
      );
    }

    try {
      final snap = await _db
          .collection('users')
          .where('email', isEqualTo: clean)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        return UniquenessCheckResult(
          isAvailable: false,
          message: 'Email "$clean" is already registered.',
          matchedField: 'email',
        );
      }
    } catch (_) {}

    return const UniquenessCheckResult(isAvailable: true);
  }

  /// Checks if a username is already taken in Firestore.
  static Future<UniquenessCheckResult> checkUsernameAvailability(String username) async {
    final clean = username.trim().toLowerCase();
    if (clean.length < 3) {
      return const UniquenessCheckResult(
        isAvailable: false,
        message: 'User ID must be at least 3 characters.',
      );
    }

    try {
      final snap = await _db
          .collection('users')
          .where('username', isEqualTo: clean)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        return UniquenessCheckResult(
          isAvailable: false,
          message: 'User ID "$username" is already taken.',
          matchedField: 'username',
        );
      }
    } catch (_) {}

    return const UniquenessCheckResult(isAvailable: true);
  }

  /// Checks if a MahaRERA Registration Number is already registered in Firestore.
  static Future<UniquenessCheckResult> checkReraAvailability(
    String reraNumber, {
    String? excludeUserId,
  }) async {
    final clean = reraNumber.trim().toUpperCase();
    if (clean.isEmpty) {
      return const UniquenessCheckResult(isAvailable: true);
    }

    if (clean.length < 5) {
      return const UniquenessCheckResult(
        isAvailable: false,
        message: 'MahaRERA number must be at least 5 characters.',
      );
    }

    try {
      final snap = await _db
          .collection('users')
          .where('reraNumber', isEqualTo: clean)
          .get();

      if (snap.docs.isNotEmpty) {
        final match = snap.docs.any((d) {
          if (excludeUserId == null || excludeUserId.trim().isEmpty) return true;
          return d.id != excludeUserId && d.data()['uid'] != excludeUserId;
        });

        if (match) {
          return UniquenessCheckResult(
            isAvailable: false,
            message: 'MahaRERA number "$clean" is already registered by another account.',
            matchedField: 'rera',
          );
        }
      }
    } catch (_) {}

    return const UniquenessCheckResult(isAvailable: true);
  }
}
