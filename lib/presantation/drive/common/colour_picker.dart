import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ColorPickerDialog extends StatefulWidget {
  final Function(String hexCode) onColorSelected;

  const ColorPickerDialog({Key? key, required this.onColorSelected})
      : super(key: key);

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

final List<Map<String, dynamic>> colorOptions = [
  {"hex": "#EB4335", "color": Color(0xFFEB4335)},
  {"hex": "#C74AD4", "color": Color(0xFFC74AD4)},
  {"hex": "#4285F4", "color": Color(0xFF4285F4)},
  {"hex": "#34A853", "color": Color(0xFF34A853)},
  {"hex": "#A1887F", "color": Color(0xFFA1887F)},
  {"hex": "#FB8C00", "color": Color(0xFFFB8C00)},
  {"hex": "#F06292", "color": Color(0xFFF06292)},
  {"hex": "#00BCD4", "color": Color(0xFF00BCD4)},
  {"hex": "#8BC34A", "color": Color(0xFF8BC34A)},
  {"hex": "#BDBDBD", "color": Color(0xFFBDBDBD)},
  {"hex": "#FBC02D", "color": Color(0xFFFBC02D)},
  {"hex": "#BA68C8", "color": Color(0xFFBA68C8)},
  {"hex": "#80DEEA", "color": Color(0xFF80DEEA)},
  {"hex": "#C5E1A5", "color": Color(0xFFC5E1A5)},
  {"hex": "#E0E0E0", "color": Color(0xFFE0E0E0)},
];

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  String? selectedHex;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Select color"),
      content: SizedBox(
        width: 300,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colorOptions.map((item) {
            final color = item['color'] as Color;
            final hex = item['hex'] as String;
            final isSelected = selectedHex == hex;

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedHex = hex;
                });
                widget.onColorSelected(hex);
                Navigator.of(context).pop();
              },
              child: CircleAvatar(
                radius: 20,
                backgroundColor: color,
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
