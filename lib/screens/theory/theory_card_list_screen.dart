import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/theory_card.dart';
import '../../services/theory_service.dart';
import '../../database/database_provider.dart';
import '../../utils/theme.dart';
import '../../utils/localization_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theory_card_detail_screen.dart';

/// Screen showing list of all theory cards (titles only)
class TheoryCardListScreen extends StatefulWidget {
  const TheoryCardListScreen({super.key});

  @override
  State<TheoryCardListScreen> createState() => _TheoryCardListScreenState();
}

class _TheoryCardListScreenState extends State<TheoryCardListScreen> {
  late TheoryService _theoryService;
  List<TheoryCard> _allCards = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadCards();
  }

  Future<void> _initializeAndLoadCards() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final db = DatabaseProvider.instance;
      final supabase = Supabase.instance.client;
      _theoryService = TheoryService(db, supabase);

      // Load all cards from all chapters
      await _loadAllTheoryCards();
    } catch (e) {
      print('❌ Error initializing: $e');
      setState(() {
        _errorMessage = 'Error loading theory cards';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAllTheoryCards() async {
    try {
      // Load all cards directly from Supabase (already sorted)
      final allCards = await _theoryService.getAllCards();

      if (allCards.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No theory cards available';
        });
        return;
      }

      setState(() {
        _allCards = allCards;
        _isLoading = false;
      });

      print('✅ Loaded ${allCards.length} theory cards directly from Supabase');
    } catch (e) {
      print('❌ Error loading cards: $e');
      setState(() {
        _errorMessage = 'Failed to load theory cards';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          l10n.theoryCardListTitle,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_allCards.isEmpty) {
      return _buildEmptyState();
    }

    return _buildCardList();
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Center(
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
            _errorMessage ?? l10n.theoryCardListErrorLoading,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _initializeAndLoadCards,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.theoryCardListRetry),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.theoryCardListEmpty,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardList() {
    final theme = Theme.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _allCards.length,
      itemBuilder: (context, index) {
        final card = _allCards[index];
        final title = card.getLocalizedTitle(languageCode) ?? 
                     card.getLocalizedText(languageCode).substring(0, 50) + '...';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TheoryCardDetailScreen(card: card),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Icon based on chapter
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.menu_book,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lezione ${card.chapterId}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Arrow
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
