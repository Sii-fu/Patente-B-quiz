import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/theory_card.dart';
import '../../services/theory_service.dart';
import '../../utils/theme.dart';
import '../../utils/localization_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theory/theory_card_detail_screen.dart';

/// Page 2: Theory Reading Screen
/// Shows a list of theory card titles for a chapter
class TheoryReadingScreen extends StatefulWidget {
  final int chapterId;
  final int initialCardIndex;

  const TheoryReadingScreen({
    super.key,
    required this.chapterId,
    this.initialCardIndex = 0,
  });

  @override
  State<TheoryReadingScreen> createState() => _TheoryReadingScreenState();
}

class _TheoryReadingScreenState extends State<TheoryReadingScreen> {
  late TheoryService _theoryService;
  late ScrollController _scrollController;

  List<TheoryCard> _cards = [];
  Set<int> _readCardIds = {};
  String _chapterName = '';
  int _currentCardIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _initializeServices();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    _theoryService = TheoryService.online();

    await _loadChapterData();

    // Scroll to initial card after loading
    if (widget.initialCardIndex > 0 && _cards.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCard(widget.initialCardIndex);
      });
    }
  }

  Future<void> _loadChapterData() async {
    setState(() => _isLoading = true);

    try {
      print('📖 Loading chapter data directly from Supabase for chapter ${widget.chapterId}...');
      
      // Load chapter info directly from Supabase
      final chapter = await _theoryService.getChapterById(widget.chapterId);
      print('📖 Chapter loaded: ${chapter?.nameIt ?? "NULL"}');
      
      final languageCode = Localizations.localeOf(context).languageCode;

      // Load cards directly from Supabase
      final cards = await _theoryService.getCardsForChapter(widget.chapterId);
      print('📖 Loaded ${cards.length} cards directly from Supabase');

      // Load read status
      final readIds = await _theoryService.getReadCardIds(widget.chapterId);
      print('📖 Found ${readIds.length} read cards');

      setState(() {
        _chapterName = chapter?.getLocalizedName(languageCode) ?? 'Chapter';
        _cards = cards;
        _readCardIds = readIds.toSet();
        _isLoading = false;
      });

      
      print('✅ Chapter data loaded successfully');
    } catch (e, stackTrace) {
      print('❌ Error loading chapter data: $e');
      print('📍 Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
        _cards = []; // Ensure empty list instead of null
      });
    }
  }

  void _onScroll() {
    // Mark cards as read as user scrolls past them
    if (_scrollController.hasClients) {
      final scrollPosition = _scrollController.position.pixels;
      final viewportHeight = _scrollController.position.viewportDimension;

      for (int i = 0; i < _cards.length; i++) {
        final cardPosition = i * 500.0; // Approximate card height
        if (scrollPosition > cardPosition - viewportHeight / 2) {
          _markCardAsRead(_cards[i].id);
          _currentCardIndex = i;
        }
      }
    }
  }

  Future<void> _markCardAsRead(int cardId) async {
    if (!_readCardIds.contains(cardId)) {
      await _theoryService.markCardAsRead(widget.chapterId, cardId);
      setState(() {
        _readCardIds.add(cardId);
      });
    }
  }

  void _scrollToCard(int index) {
    if (_scrollController.hasClients && index < _cards.length) {
      _scrollController.animateTo(
        index * 500.0, // Approximate card height
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCards = _cards.length;
    final currentProgress = _currentCardIndex + 1;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Lezione ${widget.chapterId} ($currentProgress/$totalCards)',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
              ? _buildEmptyState()
              : _buildCardsFeed(),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book_outlined, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No theory cards available',
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsFeed() {
    final languageCode = Localizations.localeOf(context).languageCode;
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _cards.length,
      itemBuilder: (context, index) {
        final card = _cards[index];
        return _buildTheoryCardListItem(card, languageCode);
      },
    );
  }

  Widget _buildTheoryCardListItem(TheoryCard card, String languageCode) {
    final theme = Theme.of(context);
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
              // Icon
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
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
  }
}
