import 'package:flutter/material.dart';

class GradeDropdown extends StatelessWidget {
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String hint;

  const GradeDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint = "-",
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isGraded = value != null;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isGraded
            ? colorScheme.primaryContainer.withOpacity(0.4)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isGraded
              ? colorScheme.primary.withOpacity(0.3)
              : Colors.transparent,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(
            hint,
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurface),
          ),
          icon: Icon(Icons.arrow_drop_down,
              size: 18, color: colorScheme.onSurface),
          dropdownColor: colorScheme.surfaceContainer,
          style: TextStyle(
            color: isGraded ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text("Sil", style: TextStyle(color: colorScheme.error)),
            ),
            ...items.map((g) => DropdownMenuItem(
              value: g,
              child: Text(g),
            ))
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}