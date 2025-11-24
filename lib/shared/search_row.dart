import 'package:flutter/material.dart';

class SearchRow extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final Widget? trailing;

  const SearchRow({
    super.key,
    required this.controller,
    this.hintText = 'Поиск...',
    this.onChanged,
    this.trailing,
  });

  @override
  State<SearchRow> createState() => _SearchRowState();
}

class _SearchRowState extends State<SearchRow> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
    if (widget.onChanged != null) widget.onChanged!(widget.controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.primary.withOpacity(0.06);
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: widget.controller,
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              suffixIcon: widget.controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        widget.controller.clear();
                      },
                    )
                  : null,
            ),
            onChanged: widget.onChanged,
          ),
        ),
        if (widget.trailing != null) ...[
          const SizedBox(width: 12),
          widget.trailing!,
        ],
      ],
    );
  }
}
