import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../../models/category.dart';
import '../../utils/theme.dart';
import '../../services/quiz_repository.dart';
import '../../services/repository_provider.dart';
import '../../widgets/shimmer_loading.dart';
import 'topics_list_screen.dart';

class CategoriesListScreen extends StatefulWidget {
  const CategoriesListScreen({super.key});

  @override
  State<CategoriesListScreen> createState() => _CategoriesListScreenState();
}

class _CategoriesListScreenState extends State<CategoriesListScreen> {
  late QuizRepository _repository;
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _error;
  String _currentLanguage = 'it';

  @override
  void initState() {
    super.initState();
    _initializeRepository();
  }

  void _initializeRepository() {
    _repository = RepositoryProvider.quizRepository;
    _loadCategories();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    _currentLanguage = locale.languageCode;
  }

  Future<void> _loadCategories() async {
    try {
      setState(() => _isLoading = true);

      final response = await _repository.getCategories();

      setState(() {
        _categories = response
            .map((json) => Category.fromJson(json))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _parseColor(String? colorHex) {
    final theme = Theme.of(context);
    if (colorHex == null || colorHex.isEmpty) {
      return theme.colorScheme.primary;
    }
    try {
      // Remove '0x' prefix if exists
      final hexString = colorHex.replaceAll('0x', '').replaceAll('#', '');
      return Color(int.parse(hexString, radix: 16));
    } catch (e) {
      return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: theme.colorScheme.onPrimary),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.categoriesTitle,
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            l10n.categoriesSubtitle,
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: _isLoading
                      ? const ShimmerCardList(
                          itemCount: 8,
                          cardHeight: 100,
                          padding: EdgeInsets.all(20),
                          showImage: false,
                        )
                      : _error != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 64,
                                      color: theme.colorScheme.error,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      l10n.errorLoading,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _error!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),
                                    FilledButton.icon(
                                      onPressed: _loadCategories,
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Retry'),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _categories.isEmpty
                              ? Center(
                                  child: Text(
                                    l10n.noQuestionsAvailable,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(20),
                                  itemCount: _categories.length,
                                  itemBuilder: (context, index) {
                                    final category = _categories[index];
                                    final color = _parseColor(category.colorHex);

                                    // Category icons mapping
                                    IconData categoryIcon;
                                    switch (index) {
                                      case 0:
                                        categoryIcon = Icons.local_shipping; // Segnali Stradali
                                        break;
                                      case 1:
                                        categoryIcon = Icons.warning; // Norme di Circtazion
                                        break;
                                      case 2:
                                        categoryIcon = Icons.local_parking; // Segnali di Obbligo
                                        break;
                                      case 3:
                                        categoryIcon = Icons.build; // Manutenzione Veicolo
                                        break;
                                      case 4:
                                        categoryIcon = Icons.security; // Guida Sicura
                                        break;
                                      case 5:
                                        categoryIcon = Icons.contact_emergency; // Primo Soccorso
                                        break;
                                      default:
                                        categoryIcon = Icons.folder;
                                    }

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      child: Material(
                                        color: theme.colorScheme.surface,
                                        borderRadius: BorderRadius.circular(16),
                                        elevation: 0,
                                        child: InkWell(
                                          onTap: () {
                                            HapticFeedback.mediumImpact();
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => TopicsListScreen(
                                                  category: category,
                                                ),
                                              ),
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(16),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 18,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                                                width: 1,
                                              ),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Row(
                                              children: [
                                                // Category Icon
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: color.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Icon(
                                                    categoryIcon,
                                                    color: color,
                                                    size: 22,
                                                  ),
                                                ),
                                                const SizedBox(width: 14),
                                                // Category Name
                                                Expanded(
                                                  child: Text(
                                                    category.getName(_currentLanguage),
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      color: theme.colorScheme.onSurface,
                                                    ),
                                                  ),
                                                ),
                                                // Arrow Icon
                                                Icon(
                                                  Icons.chevron_right,
                                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                                  size: 24,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
