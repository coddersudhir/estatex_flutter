import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Step3LocationBlock extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final ValueChanged<Map<String, dynamic>> onChange;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const Step3LocationBlock({
    super.key,
    required this.initialData,
    required this.onChange,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<Step3LocationBlock> createState() => _Step3LocationBlockState();
}

class _Step3LocationBlockState extends State<Step3LocationBlock> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _addressLine1Controller;
  late final TextEditingController _addressLine2Controller;
  late final TextEditingController _stationController;
  late final TextEditingController _pincodeController;
  String _selectedState = 'Maharashtra';
  String _selectedCity = 'Thane';

  double _latitude = 19.2812;
  double _longitude = 72.8630;

  static const List<String> _states = [
    'Maharashtra',
    'Delhi',
    'Gujarat',
    'Karnataka',
    'Telangana',
    'Tamil Nadu',
    'Uttar Pradesh',
    'Haryana',
  ];

  static const Map<String, List<String>> _citiesByState = {
    'Maharashtra': ['Thane', 'Mumbai', 'Mumbai Suburban', 'Pune', 'Navi Mumbai', 'Nagpur', 'Nashik'],
    'Delhi': ['Central Delhi', 'New Delhi', 'North Delhi', 'South Delhi'],
    'Gujarat': ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot'],
    'Karnataka': ['Bengaluru Urban', 'Bengaluru Rural', 'Mysuru'],
    'Telangana': ['Hyderabad', 'Rangareddy', 'Medchal-Malkajgiri'],
    'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai'],
    'Uttar Pradesh': ['Noida', 'Greater Noida', 'Ghaziabad', 'Lucknow'],
    'Haryana': ['Gurugram', 'Faridabad', 'Panipat'],
  };

  @override
  void initState() {
    super.initState();
    _addressLine1Controller = TextEditingController(text: widget.initialData['addressLine1'] ?? '');
    _addressLine2Controller = TextEditingController(text: widget.initialData['addressLine2'] ?? '');
    _stationController = TextEditingController(text: widget.initialData['stationLocation'] ?? '');
    _pincodeController = TextEditingController(text: widget.initialData['pincode'] ?? '');
    _selectedState = widget.initialData['state'] ?? 'Maharashtra';
    _selectedCity = widget.initialData['city'] ?? 'Thane';
    _latitude = widget.initialData['latitude'] ?? 19.2812;
    _longitude = widget.initialData['longitude'] ?? 72.8630;
  }

  @override
  void dispose() {
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _stationController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _updateParent() {
    widget.onChange({
      'addressLine1': _addressLine1Controller.text.trim(),
      'addressLine2': _addressLine2Controller.text.trim(),
      'stationLocation': _stationController.text.trim(),
      'pincode': _pincodeController.text.trim(),
      'state': _selectedState,
      'city': _selectedCity,
      'latitude': _latitude,
      'longitude': _longitude,
    });
  }

  void _handleNext() {
    if (!_formKey.currentState!.validate()) return;
    _updateParent();
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final availableCities = _citiesByState[_selectedState] ?? ['Other'];
    if (!availableCities.contains(_selectedCity)) {
      _selectedCity = availableCities.first;
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Address Line 1
          const Text(
            'Address Line 1 *',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 5),
          TextFormField(
            controller: _addressLine1Controller,
            onChanged: (_) => _updateParent(),
            decoration: _inputDecoration(
              hint: 'Building, Shop / Office No.',
              icon: Icons.location_on_outlined,
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter Address Line 1' : null,
          ),
          const SizedBox(height: 12),

          // Address Line 2
          const Text(
            'Address Line 2 (Optional)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 5),
          TextFormField(
            controller: _addressLine2Controller,
            onChanged: (_) => _updateParent(),
            decoration: _inputDecoration(
              hint: 'Street, Landmark, Road',
              icon: Icons.signpost_outlined,
            ),
          ),
          const SizedBox(height: 12),

          // Station & Pincode Row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Station / Location *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: _stationController,
                      onChanged: (_) => _updateParent(),
                      decoration: _inputDecoration(hint: 'e.g. Mira Road East', icon: Icons.train_outlined),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter station/area' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pincode *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: _pincodeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => _updateParent(),
                      decoration: _inputDecoration(hint: '401107', icon: Icons.pin_drop_outlined, counter: false),
                      validator: (v) => (v == null || v.length != 6) ? '6 digits' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // State & City Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('State *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 5),
                    DropdownButtonFormField<String>(
                      value: _selectedState,
                      isExpanded: true,
                      items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedState = val;
                            _selectedCity = (_citiesByState[val] ?? ['Other']).first;
                          });
                          _updateParent();
                        }
                      },
                      decoration: _inputDecoration(hint: '', icon: Icons.map_outlined),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('District / City *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 5),
                    DropdownButtonFormField<String>(
                      value: _selectedCity,
                      isExpanded: true,
                      items: availableCities.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCity = val);
                          _updateParent();
                        }
                      },
                      decoration: _inputDecoration(hint: '', icon: Icons.location_city_outlined),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // GPS Coordinates Card
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.gps_fixed, color: Color(0xFFEA580C), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Office GPS Location',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        'Lat: ${_latitude.toStringAsFixed(4)}, Lng: ${_longitude.toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Text('✓ Tagged', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Navigation Buttons
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
                    child: const Text('Next: Documents →', style: TextStyle(fontWeight: FontWeight.bold)),
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
    bool counter = true,
  }) {
    return InputDecoration(
      hintText: hint,
      counterText: counter ? null : '',
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
      prefixIcon: Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
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
}
