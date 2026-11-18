import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;

  /// Resolves any User ID, username, or mobile number to the corresponding auth email.
  static Future<Map<String, dynamic>> resolveIdentifier(String identifier) async {
    final cleanId = identifier.trim();
    final cleanIdLower = cleanId.toLowerCase();

    // 1. Admin alias
    if (cleanIdLower == 'admin') {
      return {
        'email': 'admin@estatex.com',
        'role': 'admin',
        'name': 'Super Administrator',
      };
    }

    // 2. Direct email address
    if (cleanId.contains('@')) {
      // Check active state
      try {
        final snap = await _db
            .collection('users')
            .where('email', isEqualTo: cleanIdLower)
            .limit(1)
            .get();

        if (snap.docs.isNotEmpty) {
          final data = snap.docs.first.data();
          if (data['isActive'] == false) {
            throw 'Your account has been deactivated or suspended. Please contact your administrator.';
          }
          return {
            'email': cleanIdLower,
            'docData': data,
            'docId': snap.docs.first.id,
          };
        }
      } catch (e) {
        if (e is String) rethrow;
      }

      return {'email': cleanIdLower};
    }

    // 3. Lookup username or mobile in Firestore 'users' collection
    try {
      // Try username
      QuerySnapshot<Map<String, dynamic>> snap = await _db
          .collection('users')
          .where('username', isEqualTo: cleanId)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        snap = await _db
            .collection('users')
            .where('username', isEqualTo: cleanIdLower)
            .limit(1)
            .get();
      }

      // Try mobile / phone
      if (snap.docs.isEmpty) {
        snap = await _db
            .collection('users')
            .where('mobile', isEqualTo: cleanId)
            .limit(1)
            .get();
      }

      if (snap.docs.isEmpty) {
        snap = await _db
            .collection('users')
            .where('phone', isEqualTo: cleanId)
            .limit(1)
            .get();
      }

      final digitsOnly = cleanId.replaceAll(RegExp(r'\D'), '');
      if (snap.docs.isEmpty && digitsOnly.length == 10) {
        snap = await _db
            .collection('users')
            .where('mobile', isEqualTo: digitsOnly)
            .limit(1)
            .get();

        if (snap.docs.isEmpty) {
          snap = await _db
              .collection('users')
              .where('phone', isEqualTo: digitsOnly)
              .limit(1)
              .get();
        }
      }

      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        if (data['isActive'] == false) {
          throw 'Your account has been deactivated or suspended. Please contact your administrator.';
        }

        final email = (data['email'] as String?)?.trim().toLowerCase();
        if (email != null && email.contains('@')) {
          return {
            'email': email,
            'docData': data,
            'docId': snap.docs.first.id,
          };
        }
      }
    } catch (e) {
      if (e is String) rethrow;
      debugPrint('Firestore identifier lookup error: $e');
    }

    throw 'User ID "$cleanId" was not found. Please register or verify your login credentials.';
  }

  /// Sign In with universal identifier (Email, User ID, or Mobile) and password.
  static Future<Map<String, dynamic>> signIn({
    required String identifier,
    required String password,
  }) async {
    final resolution = await resolveIdentifier(identifier);
    final email = resolution['email'] as String;

    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw 'Authentication failed. Please try again.';
    }

    // Hydrate user profile from Firestore
    Map<String, dynamic> userData = {};
    try {
      final docSnap = await _db.collection('users').doc(firebaseUser.uid).get();
      if (docSnap.exists && docSnap.data() != null) {
        userData = docSnap.data()!;
      } else if (resolution['docData'] != null) {
        userData = resolution['docData'] as Map<String, dynamic>;
      }
    } catch (_) {}

    final role = userData['userType'] ?? userData['role'] ?? 'Broker';
    final name = userData['name'] ?? userData['fullName'] ?? firebaseUser.displayName ?? identifier;
    final tenantId = userData['tenantId'] ?? '';

    // Save session in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userId', firebaseUser.uid);
    await prefs.setString('user_type', role.toString());
    await prefs.setString('tenantId', tenantId.toString());
    await prefs.setString('email', email);
    await prefs.setString('name', name.toString());

    return {
      'user': firebaseUser,
      'role': role,
      'name': name,
      'tenantId': tenantId,
      'userData': userData,
    };
  }

  /// Send Phone OTP via Firebase Phone Auth
  static Future<void> sendPhoneOtp({
    required String mobileNumber,
    required Function(PhoneAuthCredential) onVerificationCompleted,
    required Function(FirebaseAuthException) onVerificationFailed,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(String verificationId) onCodeAutoRetrievalTimeout,
    int? resendToken,
  }) async {
    final cleanDigits = mobileNumber.replaceAll(RegExp(r'\D'), '');
    final tenDigits = cleanDigits.length >= 10
        ? cleanDigits.substring(cleanDigits.length - 10)
        : cleanDigits;
    final formatted = '+91$tenDigits';

    await _auth.verifyPhoneNumber(
      phoneNumber: formatted,
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
      forceResendingToken: resendToken,
      timeout: const Duration(seconds: 60),
    );
  }

  /// Verify 6-digit OTP code against verificationId
  static PhoneAuthCredential createPhoneCredential({
    required String verificationId,
    required String smsCode,
  }) {
    return PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }

  /// Calculates the next sequential tenant ID (TEN-0001, TEN-0002...)
  static Future<String> generateNextTenantId() async {
    try {
      final snap = await _db.collection('users').get();
      int maxNum = 0;

      for (final doc in snap.docs) {
        final tid = doc.data()['tenantId'] as String?;
        if (tid != null) {
          final match = RegExp(r'(?:TEN|EST)-0*(\d+)', caseSensitive: false).firstMatch(tid);
          if (match != null) {
            final num = int.tryParse(match.group(1) ?? '') ?? 0;
            final normalized = num >= 1000 ? num - 1000 : num;
            if (normalized > maxNum) maxNum = normalized;
          }
        }
      }

      final nextNum = maxNum + 1;
      return 'TEN-${nextNum.toString().padLeft(4, '0')}';
    } catch (_) {
      return 'TEN-0001';
    }
  }

  /// Sign Up and provision user document matching visitor-form-home schema
  static Future<Map<String, dynamic>> signUpAndProvision({
    required String email,
    required String password,
    required String role,
    required String name,
    required String firmName,
    required String mobile,
    required String username,
    String? reraNumber,
    String? reraType,
    String? addressLine1,
    String? addressLine2,
    String? stationLocation,
    String? city,
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
    String? proofDocType,
    String? proofFileUrl,
    PhoneAuthCredential? phoneCredential,
  }) async {
    // 1. Create user in Firebase Auth
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final firebaseUser = userCredential.user;
    if (firebaseUser == null) {
      throw 'Failed to create user in Firebase Auth.';
    }

    // 2. Link verified phone credential under the SAME UID
    if (phoneCredential != null) {
      try {
        await firebaseUser.linkWithCredential(phoneCredential);
      } catch (linkErr) {
        debugPrint('Phone link notice: $linkErr');
      }
    }

    // 3. Update display name in Firebase Auth profile
    if (name.trim().isNotEmpty) {
      await firebaseUser.updateDisplayName(name.trim()).catchError((_) {});
    }

    // 4. Calculate sequential tenant ID
    final tenantId = await generateNextTenantId();

    final cleanMobile = mobile.replaceAll(RegExp(r'\D'), '');
    final tenDigits = cleanMobile.length >= 10
        ? cleanMobile.substring(cleanMobile.length - 10)
        : cleanMobile;

    final fullAddress = [
      addressLine1,
      addressLine2,
      stationLocation,
      city,
      state,
      pincode,
    ].where((s) => s != null && s.trim().isNotEmpty).join(', ');

    // 5. Structure Firestore Document
    final firestoreUserData = {
      'uid': firebaseUser.uid,
      'accountType': 'TENANT_OWNER',
      'isOwner': true,
      'tenantId': tenantId,
      'tenantType': role,
      'userType': role,
      'role': role.toLowerCase().replaceAll(' ', '-'),
      'name': name.trim(),
      'fullName': name.trim(),
      'email': email.trim().toLowerCase(),
      'username': username.trim().toLowerCase(),
      'mobile': tenDigits,
      'phone': tenDigits,
      'firmName': firmName.trim(),
      'address': fullAddress,
      'addressLine1': (addressLine1 ?? '').trim(),
      'addressLine2': (addressLine2 ?? '').trim(),
      'stationLocation': (stationLocation ?? '').trim(),
      'city': (city ?? '').trim(),
      'state': (state ?? '').trim(),
      'pincode': (pincode ?? '').trim(),
      'country': 'India',
      'latitude': latitude,
      'longitude': longitude,
      'reraNumber': (reraNumber ?? '').trim().toUpperCase(),
      'reraType': (reraType ?? '').trim(),
      'proofDocType': proofDocType ?? 'visiting-card',
      'proofFileUrl': proofFileUrl ?? '',
      'signupDate': DateTime.now().toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
      'isActivated': false,
      'accountActivationStatus': 'pending',
      'reraVerified': false,
      'reraVerificationStatus': (reraNumber != null && reraNumber.trim().isNotEmpty)
          ? 'requested'
          : 'not_verified',
      'status': 'Active',
    };

    // 6. Write to Firestore 'users/{uid}'
    await _db.collection('users').doc(firebaseUser.uid).set(firestoreUserData);

    // 7. Store session in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userId', firebaseUser.uid);
    await prefs.setString('user_type', role);
    await prefs.setString('tenantId', tenantId);
    await prefs.setString('email', email);
    await prefs.setString('name', name);

    return {
      'user': firebaseUser,
      'tenantId': tenantId,
      'role': role,
      'name': name,
    };
  }

  /// Sign out
  static Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _auth.signOut();
  }
}
