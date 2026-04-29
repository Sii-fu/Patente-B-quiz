import 'package:flutter/material.dart';

Future<int?> showHomeworkTargetCountDialog(
  BuildContext context, {
  required int initialCount,
  bool barrierDismissible = true,
}) async {
  final controller = TextEditingController(text: initialCount.toString());
  int selected = initialCount;
  final quickOptions = <int>[10, 20, 30, 40, 50];

  final value = await showDialog<int>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('How many quizzes do you want in this homework?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Target quiz count',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  final parsed = int.tryParse(value.trim());
                  if (parsed != null && parsed > 0) {
                    setState(() {
                      selected = parsed;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: quickOptions
                    .map(
                      (value) => ChoiceChip(
                        selected: selected == value,
                        label: Text('$value'),
                        onSelected: (_) {
                          setState(() {
                            selected = value;
                            controller.text = value.toString();
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = int.tryParse(controller.text.trim());
                if (parsed == null || parsed <= 0) {
                  return;
                }
                Navigator.pop(context, parsed);
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      );
    },
  );

  return value;
}
