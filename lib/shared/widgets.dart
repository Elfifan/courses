import 'package:flutter/material.dart';

// Кастомный выпадающий список
class CustomDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? hint;
  final double? width;
  final bool isDarkMode;

  const CustomDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.isDarkMode,
    this.hint,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 180,
      height: 50,
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDarkMode ? Color(0xFF30363D) : Color(0xFFD1D5DB),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            size: 20,
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  item,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          dropdownColor: Theme.of(context).colorScheme.surface,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          menuMaxHeight: 300,
        ),
      ),
    );
  }
}