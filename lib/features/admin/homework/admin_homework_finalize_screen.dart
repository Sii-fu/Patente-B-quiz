import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/homework_builder_provider.dart';

class AdminHomeworkFinalizeScreen extends StatefulWidget {
  const AdminHomeworkFinalizeScreen({super.key});

  @override
  State<AdminHomeworkFinalizeScreen> createState() =>
      _AdminHomeworkFinalizeScreenState();
}

class _AdminHomeworkFinalizeScreenState extends State<AdminHomeworkFinalizeScreen> {
  static const Map<int, String> _availabilityOptions = <int, String>{
    6: '6 hours',
    12: '12 hours',
    24: '1 day',
    48: '2 days',
    72: '3 days',
    168: '7 days',
  };

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  int _timeLimit = 20;
  DateTime? _startDate;
  int _availabilityHours = 24;
  bool _shuffleQuestions = true;
  bool _retryAllowed = true;

  @override
  void initState() {
    super.initState();
    final builder = context.read<HomeworkBuilderProvider>();
    _titleController = TextEditingController(text: builder.title);
    _descriptionController = TextEditingController(text: builder.description ?? '');
    _timeLimit = builder.timeLimitMinutes;
    if (builder.startsAt != null) {
      _startDate = DateTime(
        builder.startsAt!.year,
        builder.startsAt!.month,
        builder.startsAt!.day,
      );
    }
    if (builder.startsAt != null && builder.endsAt != null) {
      final diffHours = builder.endsAt!.difference(builder.startsAt!).inHours;
      if (diffHours > 0) {
        _availabilityHours = _availabilityOptions.containsKey(diffHours)
            ? diffHours
            : _closestAvailabilityHours(diffHours);
      }
    }
    _shuffleQuestions = builder.shuffleQuestions;
    _retryAllowed = builder.retryAllowed;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  int _closestAvailabilityHours(int value) {
    return _availabilityOptions.keys.reduce(
      (a, b) => (value - a).abs() <= (value - b).abs() ? a : b,
    );
  }

  DateTime? get _effectiveStartAt {
    if (_startDate == null) return null;
    return DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
  }

  DateTime? get _effectiveEndAt {
    final start = _effectiveStartAt;
    if (start == null) return null;
    return start.add(Duration(hours: _availabilityHours));
  }

  String _formatDateTime(DateTime dateTime) {
    final y = dateTime.year.toString().padLeft(4, '0');
    final m = dateTime.month.toString().padLeft(2, '0');
    final d = dateTime.day.toString().padLeft(2, '0');
    final h = dateTime.hour.toString().padLeft(2, '0');
    final min = dateTime.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final base = _startDate ?? now;
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDate: base,
    );
    if (date == null || !mounted) return;

    setState(() {
      _startDate = DateTime(date.year, date.month, date.day);
    });
  }

  Future<void> _submit({required bool publish}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start date is required.')),
      );
      return;
    }

    final builder = context.read<HomeworkBuilderProvider>();
    builder.applySettings(
      HomeworkFormSettings(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        timeLimitMinutes: _timeLimit,
        startsAt: _effectiveStartAt,
        endsAt: _effectiveEndAt,
        shuffleQuestions: _shuffleQuestions,
        retryAllowed: _retryAllowed,
      ),
    );

    try {
      await builder.saveHomework(publish: publish);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(publish ? 'Homework published.' : 'Homework draft saved.'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save homework: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final builder = context.watch<HomeworkBuilderProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalize Homework'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Selected Quiz Count: ${builder.selectedCount} / ${builder.targetCount}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Change Quiz Selection'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Homework Title *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _timeLimit,
                decoration: const InputDecoration(
                  labelText: 'Time Limit (minutes)',
                  border: OutlineInputBorder(),
                ),
                items: const [10, 20, 30, 40, 50, 60]
                    .map(
                      (v) => DropdownMenuItem<int>(
                        value: v,
                        child: Text('$v min'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _timeLimit = value);
                  }
                },
              ),
               const SizedBox(height: 12),
               ListTile(
                 contentPadding: EdgeInsets.zero,
                 title: const Text('Start Date'),
                 subtitle: Text(
                   _effectiveStartAt == null
                       ? 'Not set'
                       : '${_formatDateTime(_effectiveStartAt!)} (midnight)',
                 ),
                 trailing: IconButton(
                   icon: const Icon(Icons.calendar_today),
                   onPressed: _pickStartDate,
                 ),
               ),
               DropdownButtonFormField<int>(
                 value: _availabilityHours,
                 decoration: const InputDecoration(
                   labelText: 'Homework availability',
                   border: OutlineInputBorder(),
                 ),
                 items: _availabilityOptions.entries
                     .map(
                       (entry) => DropdownMenuItem<int>(
                         value: entry.key,
                         child: Text(entry.value),
                       ),
                     )
                     .toList(),
                 onChanged: (value) {
                   if (value == null) return;
                   setState(() => _availabilityHours = value);
                 },
               ),
               const SizedBox(height: 8),
               ListTile(
                 contentPadding: EdgeInsets.zero,
                 title: const Text('End Date (auto-generated)'),
                 subtitle: Text(
                   _effectiveEndAt == null
                       ? 'Pick a start date first'
                       : _formatDateTime(_effectiveEndAt!),
                 ),
                 leading: const Icon(Icons.event_available),
               ),
               SwitchListTile(
                 value: _shuffleQuestions,
                 onChanged: (value) => setState(() => _shuffleQuestions = value),
                 title: const Text('Shuffle Questions'),
                 contentPadding: EdgeInsets.zero,
               ),
               SwitchListTile(
                 value: _retryAllowed,
                 onChanged: (value) => setState(() => _retryAllowed = value),
                 title: const Text('Retry Allowed'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: builder.isSaving
                          ? null
                          : () => _submit(publish: false),
                      child: const Text('Save Draft'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: builder.isSaving
                          ? null
                          : () => _submit(publish: true),
                      child: builder.isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Publish Homework'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
