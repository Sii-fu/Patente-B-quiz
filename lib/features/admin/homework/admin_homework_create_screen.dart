import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/homework_set.dart';
import '../../../repositories/homework_repository.dart';
import 'admin_homework_chapters_screen.dart';
import 'providers/homework_builder_provider.dart';
import 'widgets/homework_target_count_dialog.dart';

class AdminHomeworkCreateScreen extends StatefulWidget {
  const AdminHomeworkCreateScreen({
    super.key,
    this.editingHomework,
  });

  final HomeworkSet? editingHomework;

  @override
  State<AdminHomeworkCreateScreen> createState() => _AdminHomeworkCreateScreenState();
}

class _AdminHomeworkCreateScreenState extends State<AdminHomeworkCreateScreen> {
  late final HomeworkBuilderProvider _builder;
  bool _didPromptTarget = false;

  @override
  void initState() {
    super.initState();
    _builder = HomeworkBuilderProvider(
      repository: HomeworkRepository(),
      editingHomework: widget.editingHomework,
    );
    _initializeFlow();
  }

  @override
  void dispose() {
    _builder.dispose();
    super.dispose();
  }

  Future<void> _initializeFlow() async {
    await _builder.initialize();
    if (!mounted) return;

    if (!_builder.isEditing && !_didPromptTarget) {
      _didPromptTarget = true;
      final count = await showHomeworkTargetCountDialog(
        context,
        initialCount: _builder.targetCount,
        barrierDismissible: false,
      );
      if (count != null) {
        _builder.setTargetCount(count);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HomeworkBuilderProvider>.value(
      value: _builder,
      child: Consumer<HomeworkBuilderProvider>(
        builder: (context, builder, _) {
          if (builder.isInitializing) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return const AdminHomeworkChaptersScreen();
        },
      ),
    );
  }
}
