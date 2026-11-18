import 'package:flutter/material.dart';

class StepRoleSelectorBlock extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String> onSelectRole;

  const StepRoleSelectorBlock({
    super.key,
    required this.selectedRole,
    required this.onSelectRole,
  });

  static const List<Map<String, dynamic>> _roles = [
    {
      'id': 'Developer',
      'label': 'Developer',
      'icon': Icons.business,
    },
    {
      'id': 'Mandate Firm',
      'label': 'Mandate Firm',
      'icon': Icons.assignment_outlined,
    },
    {
      'id': 'Broker',
      'label': 'Broker',
      'icon': Icons.person_search_outlined,
    },
    {
      'id': 'Caller Vendor',
      'label': 'Caller Vendor',
      'icon': Icons.headset_mic_outlined,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Register as',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 4,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.05,
          children: _roles.map((r) {
            final isActive = selectedRole == r['id'];
            return InkWell(
              onTap: () => onSelectRole(r['id'] as String),
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFFFFF7ED) : Colors.white,
                      border: Border.all(
                        color: isActive ? const Color(0xFFEA580C) : const Color(0xFFE2E8F0),
                        width: isActive ? 1.8 : 1.0,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: const Color(0xFFEA580C).withOpacity(0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          r['icon'] as IconData,
                          size: 18,
                          color: isActive ? const Color(0xFFEA580C) : const Color(0xFF64748B),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          r['label'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                            color: isActive ? const Color(0xFFEA580C) : const Color(0xFF334155),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEA580C),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.check, size: 10, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
