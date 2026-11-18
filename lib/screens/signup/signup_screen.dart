import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';
import 'step_role_selector_block.dart';
import 'step_stepper_block.dart';
import 'step1_verify_phone_block.dart';
import 'step2_personal_info_block.dart';
import 'step3_location_block.dart';
import 'step4_documents_block.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  String _selectedRole = 'Broker';
  int _currentStep = 1;

  String _verifiedMobile = '';
  PhoneAuthCredential? _phoneCredential;

  Map<String, dynamic> _personalData = {};
  Map<String, dynamic> _locationData = {};
  Map<String, dynamic> _documentsData = {};

  bool _isSubmitting = false;

  void _onPhoneVerified(String mobile, PhoneAuthCredential? cred) {
    setState(() {
      _verifiedMobile = mobile;
      _phoneCredential = cred;
      _currentStep = 2;
    });
  }

  Future<void> _handleFinalSubmit() async {
    setState(() => _isSubmitting = true);

    try {
      final email = _personalData['email'] as String;
      final password = _personalData['password'] as String;
      final name = _personalData['name'] as String;
      final firmName = _personalData['firmName'] as String;
      final username = _personalData['username'] as String;
      final reraNumber = _personalData['reraNumber'] as String?;
      final reraType = _personalData['reraType'] as String?;

      final addressLine1 = _locationData['addressLine1'] as String?;
      final addressLine2 = _locationData['addressLine2'] as String?;
      final stationLocation = _locationData['stationLocation'] as String?;
      final city = _locationData['city'] as String?;
      final state = _locationData['state'] as String?;
      final pincode = _locationData['pincode'] as String?;
      final latitude = _locationData['latitude'] as double?;
      final longitude = _locationData['longitude'] as double?;

      final proofDocType = _documentsData['proofDocType'] as String?;
      final proofFileUrl = _documentsData['proofFileUrl'] as String?;

      final result = await AuthService.signUpAndProvision(
        email: email,
        password: password,
        role: _selectedRole,
        name: name,
        firmName: firmName,
        mobile: _verifiedMobile,
        username: username,
        reraNumber: reraNumber,
        reraType: reraType,
        addressLine1: addressLine1,
        addressLine2: addressLine2,
        stationLocation: stationLocation,
        city: city,
        state: state,
        pincode: pincode,
        latitude: latitude,
        longitude: longitude,
        proofDocType: proofDocType,
        proofFileUrl: proofFileUrl,
        phoneCredential: _phoneCredential,
      );

      if (!mounted) return;

      _showSuccessDialog(
        username: result['name'] ?? name,
        tenantId: result['tenantId'] ?? '',
        role: _selectedRole,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog({
    required String username,
    required String tenantId,
    required String role,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD1FAE5),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.check, color: Color(0xFF059669), size: 30),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Account Created Successfully!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome to EstateX, $username. Your $role account ($tenantId) has been created and synced in Firestore.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Proceed to Sign In →', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () {
            if (_currentStep > 1) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Image.asset('assets/images/logo.png', height: 26, fit: BoxFit.contain),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text(
              'Sign In',
              style: TextStyle(color: Color(0xFFEA580C), fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Create your account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Step $_currentStep of 4',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Step 0: Role Selector Block (Active when at Step 1 or 2)
              if (_currentStep <= 2) ...[
                StepRoleSelectorBlock(
                  selectedRole: _selectedRole,
                  onSelectRole: (role) {
                    setState(() {
                      _selectedRole = role;
                    });
                  },
                ),
                const SizedBox(height: 10),
              ],

              // 4-Step Stepper Bar
              StepStepperBlock(currentStep: _currentStep),
              const SizedBox(height: 10),

              // Active Step Body Block
              if (_currentStep == 1)
                Step1VerifyPhoneBlock(
                  initialMobile: _verifiedMobile,
                  onVerified: _onPhoneVerified,
                )
              else if (_currentStep == 2)
                Step2PersonalInfoBlock(
                  role: _selectedRole,
                  verifiedMobile: _verifiedMobile,
                  initialData: _personalData,
                  onChange: (data) => _personalData.addAll(data),
                  onNext: () => setState(() => _currentStep = 3),
                  onBack: () => setState(() => _currentStep = 1),
                )
              else if (_currentStep == 3)
                Step3LocationBlock(
                  initialData: _locationData,
                  onChange: (data) => _locationData.addAll(data),
                  onNext: () => setState(() => _currentStep = 4),
                  onBack: () => setState(() => _currentStep = 2),
                )
              else if (_currentStep == 4)
                Step4DocumentsBlock(
                  initialData: _documentsData,
                  onChange: (data) => _documentsData.addAll(data),
                  onSubmit: _handleFinalSubmit,
                  onBack: () => setState(() => _currentStep = 3),
                  isSubmitting: _isSubmitting,
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
