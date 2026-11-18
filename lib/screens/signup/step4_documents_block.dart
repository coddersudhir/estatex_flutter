import 'package:flutter/material.dart';

class Step4DocumentsBlock extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final ValueChanged<Map<String, dynamic>> onChange;
  final VoidCallback onSubmit;
  final VoidCallback onBack;
  final bool isSubmitting;

  const Step4DocumentsBlock({
    super.key,
    required this.initialData,
    required this.onChange,
    required this.onSubmit,
    required this.onBack,
    this.isSubmitting = false,
  });

  @override
  State<Step4DocumentsBlock> createState() => _Step4DocumentsBlockState();
}

class _Step4DocumentsBlockState extends State<Step4DocumentsBlock> {
  String _proofDocType = 'visiting-card';
  String? _proofFileName;
  bool _agreeTerms = true;
  String? _error;

  static const List<Map<String, String>> _docTypes = [
    {'id': 'visiting-card', 'label': 'Visiting Card'},
    {'id': 'udyam-aadhaar', 'label': 'Udyam Aadhaar / MSME'},
    {'id': 'shop-act', 'label': 'Shop & Establishment (Shop Act)'},
    {'id': 'gst-certificate', 'label': 'GST Certificate'},
    {'id': 'rera-certificate', 'label': 'RERA Certificate'},
    {'id': 'coi', 'label': 'Certificate of Incorporation (COI)'},
    {'id': 'other-proof', 'label': 'Other Business Proof'},
  ];

  @override
  void initState() {
    super.initState();
    _proofDocType = widget.initialData['proofDocType'] ?? 'visiting-card';
    _proofFileName = widget.initialData['proofFileName'];
    _agreeTerms = widget.initialData['agreeTerms'] ?? true;
  }

  void _handleSubmit() {
    if (!_agreeTerms) {
      setState(() => _error = 'Please accept the Terms of Service to proceed.');
      return;
    }
    setState(() => _error = null);

    widget.onChange({
      'proofDocType': _proofDocType,
      'proofFileName': _proofFileName ?? 'kyc_proof_doc.png',
      'proofFileUrl': '',
      'agreeTerms': _agreeTerms,
    });

    widget.onSubmit();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_error != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              border: Border.all(color: const Color(0xFFFEE2E2)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 16, color: Color(0xFFDC2626)),
                const SizedBox(width: 6),
                Text(_error!, style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
              ],
            ),
          ),

        // Info Banner
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Profile Proof & Business License (Optional)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              SizedBox(height: 3),
              Text(
                'Upload an identity or company registration document for faster priority verification.',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Document Type Dropdown
        const Text(
          'Select Document Type',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: _proofDocType,
          isExpanded: true,
          items: _docTypes
              .map((d) => DropdownMenuItem(
                    value: d['id'],
                    child: Text(d['label']!, style: const TextStyle(fontSize: 13)),
                  ))
              .toList(),
          onChanged: (val) {
            if (val != null) setState(() => _proofDocType = val);
          },
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.file_copy_outlined, size: 16, color: Color(0xFF94A3B8)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFEA580C), width: 1.8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
        const SizedBox(height: 12),

        // Upload Container
        InkWell(
          onTap: () {
            setState(() {
              _proofFileName = '${_proofDocType}_document.pdf';
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEDD5),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.cloud_upload_outlined, color: Color(0xFFEA580C), size: 20),
                  ),
                ),
                const SizedBox(height: 8),
                if (_proofFileName != null)
                  Text(
                    '✓ $_proofFileName',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                  )
                else ...[
                  const Text(
                    'Click to attach document (PDF, PNG, JPG)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Max limit: 10MB',
                    style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Terms of Service Checkbox
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: _agreeTerms,
                activeColor: const Color(0xFFEA580C),
                onChanged: (val) => setState(() => _agreeTerms = val ?? false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'I confirm that the details provided are true and accurate, and I agree to the EstateX Terms of Service and Privacy Policy.',
                style: const TextStyle(fontSize: 11, color: Color(0xFF475569), height: 1.3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Action Buttons Row
        Row(
          children: [
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: widget.isSubmitting ? null : widget.onBack,
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
                height: 44,
                child: ElevatedButton(
                  onPressed: widget.isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA580C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: widget.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Complete Registration ✓',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
