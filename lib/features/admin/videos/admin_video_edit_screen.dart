import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../l10n/app_localizations.dart';
import '../services/admin_repository.dart';

class AdminVideoEditScreen extends StatefulWidget {
  final Map<String, dynamic>? video;

  const AdminVideoEditScreen({super.key, this.video});

  @override
  State<AdminVideoEditScreen> createState() => _AdminVideoEditScreenState();
}

class _AdminVideoEditScreenState extends State<AdminVideoEditScreen> {
  final AdminRepository _adminRepository = AdminRepository();
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleItController;
  late final TextEditingController _titleEnController;
  late final TextEditingController _titleBnController;
  late final TextEditingController _youtubeUrlController;
  late final TextEditingController _durationController;
  late final TextEditingController _displayOrderController;

  bool _isSaving = false;
  String? _thumbnailUrl;
  File? _selectedThumbnailFile;

  bool get _isEditing => widget.video != null;

  @override
  void initState() {
    super.initState();
    _titleItController = TextEditingController(text: widget.video?['title_it'] ?? '');
    _titleEnController = TextEditingController(text: widget.video?['title_en'] ?? '');
    _titleBnController = TextEditingController(text: widget.video?['title_bn'] ?? '');
    _youtubeUrlController = TextEditingController(text: widget.video?['youtube_url'] ?? '');
    _durationController = TextEditingController(
      text: (widget.video?['duration_minutes'] ?? '').toString().replaceAll('null', ''),
    );
    _displayOrderController = TextEditingController(
      text: (widget.video?['display_order'] ?? 0).toString(),
    );
    _thumbnailUrl = widget.video?['thumbnail_url'] as String?;
  }

  @override
  void dispose() {
    _titleItController.dispose();
    _titleEnController.dispose();
    _titleBnController.dispose();
    _youtubeUrlController.dispose();
    _durationController.dispose();
    _displayOrderController.dispose();
    super.dispose();
  }

  Future<void> _pickThumbnail() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image == null) return;
      setState(() => _selectedThumbnailFile = File(image.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  String? _extractYouTubeId(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  bool _isValidYouTubeUrl(String url) => _extractYouTubeId(url) != null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    String? finalThumbnailUrl = _thumbnailUrl;

    if (_selectedThumbnailFile != null) {
      final bytes = await _selectedThumbnailFile!.readAsBytes();
      final uploaded = await _adminRepository.uploadVideoThumbnail(
        bytes,
        originalFileName: _selectedThumbnailFile!.path.split(RegExp(r'[\\/]')).last,
      );
      if (uploaded == null) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image')),
          );
        }
        return;
      }
      finalThumbnailUrl = uploaded;
    }

    final success = await _adminRepository.upsertVideo(
      id: widget.video?['id'] as int?,
      categoryId: widget.video?['category_id'] as int?,
      titleIt: _titleItController.text.trim(),
      titleEn: _titleEnController.text.trim().isEmpty ? null : _titleEnController.text.trim(),
      titleBn: _titleBnController.text.trim().isEmpty ? null : _titleBnController.text.trim(),
      youtubeUrl: _youtubeUrlController.text.trim(),
      durationMinutes: int.tryParse(_durationController.text.trim()),
      thumbnailUrl: finalThumbnailUrl,
      displayOrder: int.tryParse(_displayOrderController.text.trim()) ?? 0,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to save video')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final previewImagePath = _selectedThumbnailFile?.path;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.adminEditVideo : l10n.adminAddVideo),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleItController,
              decoration: InputDecoration(
                labelText: '${l10n.adminTitleIt} *',
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return l10n.adminTitleRequired;
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleEnController,
              decoration: InputDecoration(
                labelText: l10n.adminTitleEn,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleBnController,
              decoration: InputDecoration(
                labelText: l10n.adminTitleBn,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _youtubeUrlController,
              decoration: InputDecoration(
                labelText: '${l10n.adminYoutubeUrl} *',
                hintText: 'https://www.youtube.com/watch?v=...',
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                final v = value?.trim() ?? '';
                if (v.isEmpty) return l10n.adminYoutubeUrlRequired;
                if (!_isValidYouTubeUrl(v)) return l10n.adminYoutubeUrlRequired;
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _durationController,
                    decoration: InputDecoration(
                      labelText: l10n.adminDurationMinutes,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _displayOrderController,
                    decoration: InputDecoration(
                      labelText: l10n.adminDisplayOrder,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Thumbnail image',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (previewImagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(previewImagePath),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else if (_thumbnailUrl != null && _thumbnailUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  _thumbnailUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    color: theme.colorScheme.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              )
            else
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.image_outlined, size: 42),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickThumbnail,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(l10n.adminUploadImage),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isEditing ? l10n.settingsSave : l10n.adminAddVideo),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
