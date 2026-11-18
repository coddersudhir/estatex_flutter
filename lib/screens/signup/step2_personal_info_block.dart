import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/user_validation_service.dart';

class Step2PersonalInfoBlock extends StatefulWidget {
  final String role;
  final String verifiedMobile;
  final Map<String, dynamic> initialData;
  final ValueChanged<Map<String, dynamic>> onChange;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const Step2PersonalInfoBlock({
    super.key,
    required this.role,
    required this.verifiedMobile,
    required this.initialData,
    required this.onChange,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<Step2PersonalInfoBlock> createState() => _Step2PersonalInfoBlockState();
}

class _Step2PersonalInfoBlockState extends State<Step2PersonalInfoBlock> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _firmNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late final TextEditingController _reraController;
  String _reraType = 'Individual';

  bool _showPassword = false;
  bool _showConfirmPassword = false;

  bool _isCheckingEmail = false;
  String? _emailStatusMessage;
  bool? _isEmailAvailable;

  bool _isCheckingUsername = false;
  String? _usernameStatusMessage;
  bool? _isUsernameAvailable;

  // Debounced MahaRERA Uniqueness Check
  bool _isCheckingRera = false;
  String? _reraStatusMessage;
  bool? _isReraAvailable;

  Timer? _emailDebounce;
  Timer? _usernameDebounce;
  Timer? _reraDebounce;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData['name'] ?? '');
    _firmNameController = TextEditingController(text: widget.initialData['firmName'] ?? '');
    _emailController = TextEditingController(text: widget.initialData['email'] ?? '');
    _usernameController = TextEditingController(text: widget.initialData['username'] ?? '');
    _passwordController = TextEditingController(text: widget.initialData['password'] ?? '');
    _confirmPasswordController = TextEditingController(text: widget.initialData['confirmPassword'] ?? '');
    _reraController = TextEditingController(text: widget.initialData['reraNumber'] ?? '');
    _reraType = widget.initialData['reraType'] ?? 'Individual';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _firmNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _reraController.dispose();
    _emailDebounce?.cancel();
    _usernameDebounce?.cancel();
    _reraDebounce?.cancel();
    super.dispose();
  }

  void _onEmailChanged(String val) {
    _updateParent();
    _emailDebounce?.cancel();
    final clean = val.trim().toLowerCase();
    if (clean.isEmpty || !clean.contains('@')) {
      setState(() {
        _isCheckingEmail = false;
        _isEmailAvailable = null;
        _emailStatusMessage = null;
      });
      return;
    }

    _emailDebounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _isCheckingEmail = true);
      final res = await UserValidationService.checkEmailAvailability(clean);
      if (mounted) {
        setState(() {
          _isCheckingEmail = false;
          _isEmailAvailable = res.isAvailable;
          _emailStatusMessage = res.message;
        });
      }
    });
  }

  void _onUsernameChanged(String val) {
    _updateParent();
    _usernameDebounce?.cancel();
    final clean = val.trim().toLowerCase();
    if (clean.length < 3) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = null;
        _usernameStatusMessage = null;
      });
      return;
    }

    _usernameDebounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _isCheckingUsername = true);
      final res = await UserValidationService.checkUsernameAvailability(clean);
      if (mounted) {
        setState(() {
          _isCheckingUsername = false;
          _isUsernameAvailable = res.isAvailable;
          _usernameStatusMessage = res.message;
        });
      }
    });
  }

  void _onReraChanged(String val) {
    _updateParent();
    _reraDebounce?.cancel();
    final clean = val.trim().toUpperCase();
    if (clean.length < 5) {
      setState(() {
        _isCheckingRera = false;
        _isReraAvailable = null;
        _reraStatusMessage = null;
      });
      return;
    }

    _reraDebounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _isCheckingRera = true);
      final res = await UserValidationService.checkReraAvailability(clean);
      if (mounted) {
        setState(() {
          _isCheckingRera = false;
          _isReraAvailable = res.isAvailable;
          _reraStatusMessage = res.message;
        });
      }
    });
  }

  void _updateParent() {
    widget.onChange({
      'name': _nameController.text.trim(),
      'firmName': _firmNameController.text.trim(),
      'email': _emailController.text.trim(),
      'username': _usernameController.text.trim(),
      'password': _passwordController.text,
      'confirmPassword': _confirmPasswordController.text,
      'reraNumber': _reraController.text.trim().toUpperCase(),
      'reraType': _reraType,
    });
  }

  void _handleNext() {
    if (!_formKey.currentState!.validate()) return;
    if (_isEmailAvailable == false) return;
    if (_isUsernameAvailable == false) return;
    if (_isReraAvailable == false) return;
    if (_passwordController.text != _confirmPasswordController.text) return;

    _updateParent();
    widget.onNext();
  }

  bool get _isReraApplicable =>
      widget.role == 'Broker' || widget.role == 'Mandate Firm';

  @override
  Widget build(BuildContext context) {
    final isPasswordMatch = _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _passwordController.text == _confirmPasswordController.text;

    final isPasswordMismatch = _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _passwordController.text != _confirmPasswordController.text;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Owner / Contact Name
          const Text(
            'Owner / Primary Contact Name *',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 5),
          TextFormField(
            controller: _nameController,
            onChanged: (_) => _updateParent(),
            decoration: _inputDecoration(
              hint: 'Enter primary contact name',
              icon: Icons.person_outline,
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter contact name' : null,
          ),
          const SizedBox(height: 12),

          // Company / Firm Name
          const Text(
            'Company / Firm Name *',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 5),
          TextFormField(
            controller: _firmNameController,
            onChanged: (_) => _updateParent(),
            decoration: _inputDecoration(
              hint: 'Enter firm name',
              icon: Icons.business_outlined,
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter company/firm name' : null,
          ),
          const SizedBox(height: 12),

          // Email Address
          const Text(
            'Email Address *',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 5),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: _onEmailChanged,
            decoration: _inputDecoration(
              hint: 'Enter email address',
              icon: Icons.email_outlined,
              suffix: _isCheckingEmail
                  ? _spinner()
                  : _isEmailAvailable == true
                      ? const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18)
                      : _isEmailAvailable == false
                          ? const Icon(Icons.cancel, color: Color(0xFFDC2626), size: 18)
                          : null,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty || !v.contains('@')) {
                return 'Please enter a valid email address';
              }
              if (_isEmailAvailable == false) {
                return _emailStatusMessage ?? 'Email already registered';
              }
              return null;
            },
          ),
          if (_isEmailAvailable == true)
            const Padding(
              padding: EdgeInsets.only(top: 3),
              child: Text(
                '✓ Email is available',
                style: TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w500),
              ),
            ),
          const SizedBox(height: 12),

          // Verified Mobile (Read-Only)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mobile Number *',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '✓ Verified',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          TextFormField(
            initialValue: '+91 ${widget.verifiedMobile}',
            readOnly: true,
            style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w600),
            decoration: _inputDecoration(
              hint: '',
              icon: Icons.phone_android,
              fillColor: const Color(0xFFF1F5F9),
            ),
          ),
          const SizedBox(height: 12),

          // Create User ID
          const Text(
            'Create User ID *',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 5),
          TextFormField(
            controller: _usernameController,
            onChanged: _onUsernameChanged,
            decoration: _inputDecoration(
              hint: 'Choose unique user handle',
              icon: Icons.badge_outlined,
              suffix: _isCheckingUsername
                  ? _spinner()
                  : _isUsernameAvailable == true
                      ? const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18)
                      : _isUsernameAvailable == false
                          ? const Icon(Icons.cancel, color: Color(0xFFDC2626), size: 18)
                          : null,
            ),
            validator: (v) {
              if (v == null || v.trim().length < 3) {
                return 'User ID must be at least 3 characters';
              }
              if (_isUsernameAvailable == false) {
                return _usernameStatusMessage ?? 'User ID already taken';
              }
              return null;
            },
          ),
          if (_isUsernameAvailable == true)
            const Padding(
              padding: EdgeInsets.only(top: 3),
              child: Text(
                '✓ User ID is available',
                style: TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w500),
              ),
            ),
          const SizedBox(height: 12),

          // Password & Confirm Password
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Password *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      onChanged: (_) {
                        setState(() {});
                        _updateParent();
                      },
                      decoration: _inputDecoration(
                        hint: 'Create password',
                        icon: Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off, size: 16, color: const Color(0xFF94A3B8)),
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6) ? 'Min 6 chars' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Confirm *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_showConfirmPassword,
                      onChanged: (_) {
                        setState(() {});
                        _updateParent();
                      },
                      decoration: _inputDecoration(
                        hint: 'Confirm password',
                        icon: Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(_showConfirmPassword ? Icons.visibility : Icons.visibility_off, size: 16, color: const Color(0xFF94A3B8)),
                          onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                        ),
                      ),
                      validator: (v) {
                        if (v != _passwordController.text) return 'Mismatch';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isPasswordMatch)
            const Padding(
              padding: EdgeInsets.only(top: 3),
              child: Text('✓ Passwords match perfectly', style: TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w500)),
            ),
          if (isPasswordMismatch)
            const Padding(
              padding: EdgeInsets.only(top: 3),
              child: Text('✕ Passwords do not match', style: TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.w500)),
            ),
          const SizedBox(height: 12),

          // MahaRERA Reg. Number (Debounced Firestore Check)
          if (_isReraApplicable) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MahaRERA Reg. Number (Optional)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: _reraController,
                        onChanged: _onReraChanged,
                        textCapitalization: TextCapitalization.characters,
                        decoration: _inputDecoration(
                          hint: 'e.g. A51800012345',
                          icon: Icons.verified_outlined,
                          suffix: _isCheckingRera
                              ? _spinner()
                              : _isReraAvailable == true && _reraController.text.isNotEmpty
                                  ? const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18)
                                  : _isReraAvailable == false
                                      ? const Icon(Icons.cancel, color: Color(0xFFDC2626), size: 18)
                                      : null,
                        ),
                        validator: (v) {
                          if (_isReraAvailable == false) {
                            return _reraStatusMessage ?? 'MahaRERA already registered';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                if (_reraController.text.trim().isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RERA Type *',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 5),
                        DropdownButtonFormField<String>(
                          value: _reraType,
                          items: const [
                            DropdownMenuItem(value: 'Individual', child: Text('Individual', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'Entity / Firm', child: Text('Entity / Firm', style: TextStyle(fontSize: 13))),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _reraType = val);
                              _updateParent();
                            }
                          },
                          decoration: _inputDecoration(hint: '', icon: Icons.apartment),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            if (_isReraAvailable == true && _reraController.text.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 3),
                child: Text(
                  '✓ MahaRERA number is available',
                  style: TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w500),
                ),
              ),
            if (_isReraAvailable == false)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  '✕ ${_reraStatusMessage ?? "Already registered by another account"}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.w500),
                ),
              ),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 8),

          // Actions Row (Back / Next)
          Row(
            children: [
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton(
                    onPressed: widget.onBack,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('← Back', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: _handleNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Next: Location →', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
    Color? fillColor,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
      prefixIcon: Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
      suffixIcon: suffix,
      filled: fillColor != null,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEA580C), width: 1.8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    );
  }

  Widget _spinner() {
    return const Padding(
      padding: EdgeInsets.all(12.0),
      child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFEA580C))),
    );
  }
}
