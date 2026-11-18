import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/user_validation_service.dart';

class Step1VerifyPhoneBlock extends StatefulWidget {
  final String initialMobile;
  final Function(String verifiedMobile, PhoneAuthCredential? credential) onVerified;

  const Step1VerifyPhoneBlock({
    super.key,
    required this.initialMobile,
    required this.onVerified,
  });

  @override
  State<Step1VerifyPhoneBlock> createState() => _Step1VerifyPhoneBlockState();
}

class _Step1VerifyPhoneBlockState extends State<Step1VerifyPhoneBlock> {
  late final TextEditingController _mobileController;
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isOtpStage = false;
  bool _isCheckingMobile = false;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  String? _errorMessage;
  String? _mobileAvailabilityError;
  String? _verificationId;
  int? _resendToken;

  int _countdown = 30;
  Timer? _countdownTimer;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _mobileController = TextEditingController(text: widget.initialMobile);
  }

  @override
  void dispose() {
    _mobileController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _countdownTimer?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onMobileChanged(String val) {
    setState(() {
      _errorMessage = null;
      _mobileAvailabilityError = null;
    });

    final digits = val.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _isCheckingMobile = true);
      final res = await UserValidationService.checkMobileAvailability(digits);
      if (mounted) {
        setState(() {
          _isCheckingMobile = false;
          if (!res.isAvailable) {
            _mobileAvailabilityError = res.message;
          }
        });
      }
    });
  }

  void _startTimer() {
    _countdown = 30;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        t.cancel();
      }
    });
  }

  Future<void> _sendOtp() async {
    final digits = _mobileController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) {
      setState(() => _errorMessage = 'Please enter a valid 10-digit mobile number.');
      return;
    }

    setState(() {
      _isSendingOtp = true;
      _errorMessage = null;
    });

    // Final pre-check
    final avail = await UserValidationService.checkMobileAvailability(digits);
    if (!avail.isAvailable) {
      setState(() {
        _isSendingOtp = false;
        _errorMessage = avail.message;
      });
      return;
    }

    try {
      await AuthService.sendPhoneOtp(
        mobileNumber: digits,
        resendToken: _resendToken,
        onVerificationCompleted: (PhoneAuthCredential cred) {
          if (!mounted) return;
          widget.onVerified(digits, cred);
        },
        onVerificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() {
            _isSendingOtp = false;
            _errorMessage = e.message ?? 'SMS OTP verification failed.';
          });
        },
        onCodeSent: (String verId, int? resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verId;
            _resendToken = resendToken;
            _isSendingOtp = false;
            _isOtpStage = true;
          });
          _startTimer();
          _otpFocusNodes[0].requestFocus();
        },
        onCodeAutoRetrievalTimeout: (String verId) {
          _verificationId = verId;
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSendingOtp = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    final otpCode = _otpControllers.map((c) => c.text).join();
    if (otpCode.length != 6) {
      setState(() => _errorMessage = 'Please enter all 6 digits of the OTP.');
      return;
    }

    if (_verificationId == null) {
      setState(() => _errorMessage = 'OTP session expired. Please request a new OTP.');
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
      _errorMessage = null;
    });

    try {
      final credential = AuthService.createPhoneCredential(
        verificationId: _verificationId!,
        smsCode: otpCode,
      );

      final digits = _mobileController.text.replaceAll(RegExp(r'\D'), '');
      widget.onVerified(digits, credential);
    } catch (e) {
      setState(() {
        _isVerifyingOtp = false;
        _errorMessage = 'Invalid OTP. Please check the code and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_errorMessage != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              border: Border.all(color: const Color(0xFFFEE2E2)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 16, color: Color(0xFFDC2626)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

        if (!_isOtpStage) ...[
          // Mobile Input Stage
          const Text(
            'Mobile Number',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _mobileController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: _onMobileChanged,
            decoration: InputDecoration(
              counterText: '',
              prefixText: '+91 ',
              prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 14),
              prefixIcon: const Icon(Icons.phone_android_outlined, size: 18, color: Color(0xFF94A3B8)),
              suffixIcon: _isCheckingMobile
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFEA580C)),
                      ),
                    )
                  : null,
              hintText: 'Enter 10-digit mobile number',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFEA580C), width: 1.8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          if (_mobileAvailabilityError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '✕ $_mobileAvailabilityError',
                style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.w500),
              ),
            ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _isSendingOtp ? null : _sendOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isSendingOtp
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Send OTP',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ] else ...[
          // OTP Entry Stage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Enter 6-digit OTP sent to +91 ${_mobileController.text}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF475569)),
              ),
              GestureDetector(
                onTap: () => setState(() => _isOtpStage = false),
                child: const Text(
                  'Edit',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 44,
                height: 48,
                child: TextFormField(
                  controller: _otpControllers[index],
                  focusNode: _otpFocusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFEA580C), width: 2),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (val) {
                    if (val.isNotEmpty && index < 5) {
                      _otpFocusNodes[index + 1].requestFocus();
                    } else if (val.isEmpty && index > 0) {
                      _otpFocusNodes[index - 1].requestFocus();
                    }
                    if (_otpControllers.every((c) => c.text.isNotEmpty)) {
                      _verifyOtp();
                    }
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _countdown > 0 ? 'Resend code in ${_countdown}s' : 'Didn\'t get OTP?',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              if (_countdown == 0)
                GestureDetector(
                  onTap: _sendOtp,
                  child: const Text(
                    'Resend OTP',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _isVerifyingOtp ? null : _verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isVerifyingOtp
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Verify & Continue',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ],
    );
  }
}
