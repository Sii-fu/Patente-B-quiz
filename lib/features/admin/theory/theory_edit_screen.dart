import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import '../../../l10n/app_localizations.dart';
import '../services/admin_repository.dart';

class TheoryEditScreen extends StatefulWidget {
  final Map<String, dynamic>? card;
  final List<Map<String, dynamic>> chapters;
  final int? preselectedChapterId;

  const TheoryEditScreen({
    super.key,
    this.card,
    required this.chapters,
    this.preselectedChapterId,
  });

  @override
  State<TheoryEditScreen> createState() => _TheoryEditScreenState();
}

class _TheoryEditScreenState extends State<TheoryEditScreen> {
  final AdminRepository _adminRepository = AdminRepository();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _titleItController;
  late TextEditingController _titleEnController;
  late TextEditingController _titleBnController;
  late TextEditingController _textItController;
  late TextEditingController _textEnController;
  late TextEditingController _textBnController;
  late TextEditingController _displayOrderController;

  int? _selectedChapterId;
  String? _imageUrl;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isSaving = false;
  bool _isUploading = false;

  bool get _isEditing => widget.card != null;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final c = widget.card;
    
    _titleItController = TextEditingController(text: c?['title_it'] ?? '');
    _titleEnController = TextEditingController(text: c?['title_en'] ?? '');
    _titleBnController = TextEditingController(text: c?['title_bn'] ?? '');
    _textItController = TextEditingController(text: c?['text_it'] ?? '');
    _textEnController = TextEditingController(text: c?['text_en'] ?? '');
    _textBnController = TextEditingController(text: c?['text_bn'] ?? '');
    _displayOrderController = TextEditingController(
      text: (c?['display_order'] ?? 1).toString(),
    );
    
    // Use preselectedChapterId if provided, otherwise use card's chapter_id
    _selectedChapterId = widget.preselectedChapterId ?? c?['chapter_id'] as int?;
    _imageUrl = c?['image_url'];
  }

  @override
  void dispose() {
    _titleItController.dispose();
    _titleEnController.dispose();
    _titleBnController.dispose();
    _textItController.dispose();
    _textEnController.dispose();
    _textBnController.dispose();
    _displayOrderController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = image.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImageBytes == null || _selectedImageName == null) {
      return _imageUrl;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'theory_${timestamp}_$_selectedImageName';
      
      await Supabase.instance.client.storage
          .from('theory_images')
          .uploadBinary(
            fileName,
            _selectedImageBytes!,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = Supabase.instance.client.storage
          .from('theory_images')
          .getPublicUrl(fileName);

      setState(() {
        _isUploading = false;
      });

      return publicUrl;
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedChapterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.adminSelectChapter),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    HapticFeedback.mediumImpact();

    // Upload image if selected
    String? finalImageUrl = _imageUrl;
    if (_selectedImageBytes != null) {
      finalImageUrl = await _uploadImage();
    }

    final success = await _adminRepository.upsertTheoryCard(
      id: widget.card?['id'] as int?,
      chapterId: _selectedChapterId!,
      titleIt: _titleItController.text.trim().isEmpty ? null : _titleItController.text.trim(),
      titleEn: _titleEnController.text.trim().isEmpty ? null : _titleEnController.text.trim(),
      titleBn: _titleBnController.text.trim().isEmpty ? null : _titleBnController.text.trim(),
      textIt: _textItController.text.trim(),
      textEn: _textEnController.text.trim().isEmpty ? null : _textEnController.text.trim(),
      textBn: _textBnController.text.trim().isEmpty ? null : _textBnController.text.trim(),
      imageUrl: finalImageUrl,
      displayOrder: int.tryParse(_displayOrderController.text) ?? 1,
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.adminTheoryCardSaved),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.adminErrorSaving),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.adminEditTheoryCard : l10n.adminAddTheoryCard),
        backgroundColor: Colors.orange.withOpacity(0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        actions: [
          if (_isSaving || _isUploading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.orange,
                  ),
                ),
              ),
            )
          else
            IconButton(
              onPressed: _save,
              icon: const Icon(Icons.check, color: Colors.orange),
              tooltip: l10n.profileSaveButton,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              Card(
                color: Colors.orange.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Required fields are marked with *',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Chapter Selection Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.menu_book,
                              color: Colors.orange,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${l10n.adminChapter} *',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: _selectedChapterId,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        hint: Text(l10n.adminSelectChapter),
                        items: widget.chapters.map((chapter) {
                          return DropdownMenuItem<int>(
                            value: chapter['id'] as int,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.65,
                              ),
                              child: Text(
                                chapter['name_it'] ?? 'Unknown',
                                softWrap: true,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedChapterId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return l10n.adminSelectChapter;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _displayOrderController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.adminDisplayOrder,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          hintText: '1',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Italian Content Card (Required)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.orange.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.language,
                              color: Colors.orange,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Italiano (Italian) *',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleItController,
                        decoration: InputDecoration(
                          labelText: l10n.adminTitleIt,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          hintText: l10n.adminEnterTitleIt,
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: 2,
                        maxLength: 200,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _textItController,
                        maxLines: 6,
                        maxLength: 2000,
                        decoration: InputDecoration(
                          labelText: '${l10n.adminTextIt} *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          hintText: l10n.adminEnterTextIt,
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                          contentPadding: const EdgeInsets.all(16),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.adminFieldRequired;
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // English Content Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Theme(
                  data: theme.copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.translate,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'English (Optional)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    children: [
                      TextFormField(
                        controller: _titleEnController,
                        decoration: InputDecoration(
                          labelText: l10n.adminTitleEn,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: 2,
                        maxLength: 200,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _textEnController,
                        maxLines: 5,
                        maxLength: 2000,
                        decoration: InputDecoration(
                          labelText: l10n.adminTextEn,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                          contentPadding: const EdgeInsets.all(16),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Bangla Content Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Theme(
                  data: theme.copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.g_translate,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'বাংলা (Bangla) (Optional)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    children: [
                      TextFormField(
                        controller: _titleBnController,
                        decoration: InputDecoration(
                          labelText: l10n.adminTitleBn,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: 2,
                        maxLength: 200,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _textBnController,
                        maxLines: 5,
                        maxLength: 2000,
                        decoration: InputDecoration(
                          labelText: l10n.adminTextBn,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                          contentPadding: const EdgeInsets.all(16),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Image Upload Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.image,
                              color: Colors.purple,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${l10n.adminCardImage} (Optional)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildImageSection(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving || _isUploading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving || _isUploading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _isUploading ? 'Uploading...' : 'Saving...',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline),
                            const SizedBox(width: 8),
                            Text(
                              l10n.profileSaveButton.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        if (_selectedImageBytes != null || (_imageUrl != null && _imageUrl!.isNotEmpty)) ...[
          Container(
            constraints: const BoxConstraints(
              maxHeight: 200,
              maxWidth: double.infinity,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _selectedImageBytes != null
                  ? Image.memory(
                      _selectedImageBytes!,
                      fit: BoxFit.contain,
                    )
                  : Image.network(
                      _imageUrl!,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: Colors.orange,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        height: 150,
                        color: Colors.grey.withOpacity(0.1),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Failed to load image',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        if (_isUploading) ...[
          const LinearProgressIndicator(
            backgroundColor: Colors.orange,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
          ),
          const SizedBox(height: 12),
          Text(
            'Uploading image...',
            style: TextStyle(
              color: Colors.orange[700],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _isUploading ? null : _pickImage,
              icon: Icon(
                _imageUrl != null || _selectedImageBytes != null
                    ? Icons.change_circle_outlined
                    : Icons.upload_file,
                size: 20,
              ),
              label: Text(
                _imageUrl != null || _selectedImageBytes != null
                    ? l10n.adminChangeImage
                    : l10n.adminUploadImage,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            if (_imageUrl != null || _selectedImageBytes != null) ...[
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _isUploading
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _imageUrl = null;
                          _selectedImageBytes = null;
                          _selectedImageName = null;
                        });
                      },
                icon: const Icon(Icons.delete_outline, size: 20),
                label: const Text('Remove'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ],
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Recommended: 800x600px or larger',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
