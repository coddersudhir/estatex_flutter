import 'package:flutter/material.dart';

class StepStepperBlock extends StatelessWidget {
  final int currentStep;

  const StepStepperBlock({
    super.key,
    required this.currentStep,
  });

  static const List<Map<String, dynamic>> _steps = [
    {'step': 1, 'label': 'Verify Phone'},
    {'step': 2, 'label': 'Personal Info'},
    {'step': 3, 'label': 'Location'},
    {'step': 4, 'label': 'Attach Docs'},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: List.generate(_steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            final stepIndex = (index ~/ 2) + 1;
            final isCompleted = currentStep > stepIndex;
            return Expanded(
              child: Container(
                height: 2,
                color: isCompleted ? const Color(0xFFEA580C) : const Color(0xFFE2E8F0),
              ),
            );
          }

          final stepData = _steps[index ~/ 2];
          final stepNum = stepData['step'] as int;
          final isCompleted = currentStep > stepNum;
          final isActive = currentStep == stepNum;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isActive || isCompleted)
                      ? const Color(0xFFEA580C)
                      : Colors.white,
                  border: Border.all(
                    color: (isActive || isCompleted)
                        ? const Color(0xFFEA580C)
                        : const Color(0xFFCBD5E1),
                    width: 1.5,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFFEDD5),
                            blurRadius: 0,
                            spreadRadius: 2.5,
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : Text(
                          '$stepNum',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.white : const Color(0xFF94A3B8),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stepData['label'] as String,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive
                      ? FontWeight.bold
                      : isCompleted
                          ? FontWeight.w600
                          : FontWeight.w500,
                  color: isActive
                      ? const Color(0xFFEA580C)
                      : isCompleted
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF64748B),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
