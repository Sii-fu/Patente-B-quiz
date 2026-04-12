import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../l10n/app_localizations.dart';
import '../../models/category.dart';
import '../../models/topic.dart';
import '../../utils/theme.dart';
import '../../services/quiz_repository.dart';
import '../../services/repository_provider.dart';
import 'subtopics_list_screen.dart';

class TopicsListScreen extends StatefulWidget {
  final Category category;

  const TopicsListScreen({
    super.key,
    required this.category,
  });

  @override
  State<TopicsListScreen> createState() => _TopicsListScreenState();
}

class _TopicsListScreenState extends State<TopicsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Topic> _topics = [];
  List<Topic> _filteredTopics = [];
  bool _isLoading = true;
  String? _error;
  String _currentLanguage = 'it';
  bool _isSearching = false;
  late QuizRepository _repository;

  @override
  void initState() {
    super.initState();
    _initializeRepository();
  }

  Future<void> _initializeRepository() async {
    _repository = RepositoryProvider.quizRepository;
    _loadTopics();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    _currentLanguage = locale.languageCode;
  }

  Future<void> _loadTopics() async {
    try {
      setState(() => _isLoading = true);

      // Use repository which handles offline/online automatically
      final topicData = await _repository.getTopicsByCategory(widget.category.id);
      final topics = topicData.map((json) => Topic.fromJson(json)).toList();

      setState(() {
        _topics = topics;
        _filteredTopics = topics;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading topics: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterTopics(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTopics = _topics;
      } else {
        _filteredTopics = _topics.where((topic) {
          final nameIt = topic.nameIt.toLowerCase();
          final nameEn = topic.nameEn?.toLowerCase() ?? '';
          final nameBn = topic.nameBn?.toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return nameIt.contains(searchLower) ||
                 nameEn.contains(searchLower) ||
                 nameBn.contains(searchLower);
        }).toList();
      }
    });
  }

  Color _getCategoryColor() {
    final theme = Theme.of(context);
    if (widget.category.colorHex == null) return theme.colorScheme.primary;
    try {
      final hexString = widget.category.colorHex!
          .replaceAll('0x', '')
          .replaceAll('#', '');
      return Color(int.parse(hexString, radix: 16));
    } catch (e) {
      return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final categoryColor = _getCategoryColor().withOpacity(.8);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              categoryColor,
              categoryColor.withValues(alpha: 0.7),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: _isSearching
                    ? Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                style: const TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  hintText: l10n.searchQuestions,
                                  hintStyle: TextStyle(
                                    color: Colors.black.withValues(alpha: 0.7),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: Colors.black,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                onChanged: _filterTopics,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.close, color: theme.colorScheme.onPrimary),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _isSearching = false;
                                _searchController.clear();
                                _filteredTopics = _topics;
                              });
                            },
                          ),
                        ],
                      )
                    : Row(
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
                                  widget.category.getName(_currentLanguage),
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimary,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  l10n.topicsSubtitle,
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.search, color: theme.colorScheme.onPrimary),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _isSearching = true;
                              });
                            },
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
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: categoryColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.loading,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
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
                                      onPressed: _loadTopics,
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Retry'),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: categoryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _filteredTopics.isEmpty
                              ? Center(
                                  child: Text(
                                    _isSearching ? l10n.noResultsFound : l10n.noQuestionsAvailable,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                  itemCount: _filteredTopics.length,
                                  itemBuilder: (context, index) {
                                    final topic = _filteredTopics[index];
                                    
                                    // Topic icons mapping
                                    IconData topicIcon;
                                    switch (index % 4) {
                                      case 0:
                                        topicIcon = Icons.dangerous;
                                        break;
                                      case 1:
                                        topicIcon = Icons.front_hand;
                                        break;
                                      case 2:
                                        topicIcon = Icons.do_not_disturb;
                                        break;
                                      case 3:
                                        topicIcon = Icons.signpost;
                                        break;
                                      default:
                                        topicIcon = Icons.topic;
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
                                                builder: (context) => SubtopicsListScreen(
                                                  topic: topic,
                                                  categoryColor: categoryColor,
                                                ),
                                              ),
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(16),
                                          child: Container(

                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                                                width: 1,
                                              ),
                                              borderRadius: BorderRadius.circular(16),
                                              
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    // Topic Icon
                                                    Container(
                                                      width: 40,
                                                      height: 40,
                                                      decoration: BoxDecoration(
                                                        color: categoryColor.withValues(alpha: 0.15),
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: Icon(
                                                        topicIcon,
                                                        color: categoryColor,
                                                        size: 22,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    // Topic Name
                                                    Expanded(
                                                      child: Text(
                                                        topic.getName(_currentLanguage),
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontWeight: FontWeight.w600,
                                                          color: theme.colorScheme.onSurface,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    // Completion badge
                                                    // Container(
                                                    //   padding: const EdgeInsets.symmetric(
                                                    //     horizontal: 10,
                                                    //     vertical: 5,
                                                    //   ),
                                                    //   decoration: BoxDecoration(
                                                    //     color: AppTheme.successGreen,
                                                    //     borderRadius: BorderRadius.circular(12),
                                                    //   ),
                                                    //   child: Text(
                                                    //     '75%',
                                                    //     style: TextStyle(
                                                    //       fontSize: 11,
                                                    //       fontWeight: FontWeight.bold,
                                                    //       color: Colors.white,
                                                    //     ),
                                                    //   ),
                                                    // ),
                                                  ],
                                                ),
                                                // const SizedBox(height: 12),
                                                // VEDI QUIZ button
                                                // SizedBox(
                                                //   width: double.maxFinite,
                                                //   child: ElevatedButton(
                                                //     onPressed: () {
                                                //       HapticFeedback.mediumImpact();
                                                //       Navigator.push(
                                                //         context,
                                                //         MaterialPageRoute(
                                                //           builder: (context) => QuizzesListScreen(
                                                //             topic: topic,
                                                //             categoryColor: categoryColor,
                                                //           ),
                                                //         ),
                                                //       );
                                                //     },
                                                //     style: ElevatedButton.styleFrom(
                                                //       backgroundColor: categoryColor,
                                                //       foregroundColor: Colors.white,
                                                //       elevation: 0,
                                                //       padding: const EdgeInsets.symmetric(vertical: 0),
                                                //       shape: RoundedRectangleBorder(
                                                //         borderRadius: BorderRadius.circular(10),
                                                //       ),
                                                //     ),
                                                //     child: Row(
                                                //       mainAxisAlignment: MainAxisAlignment.center,
                                                //       children: [
                                                //         Text(
                                                //           'VEDI QUIZ',
                                                //           style: TextStyle(
                                                //             fontSize: 14,
                                                //             fontWeight: FontWeight.bold,
                                                //           ),
                                                //         ),
                                                //         const SizedBox(width: 8),
                                                //         Icon(Icons.arrow_forward, size: 18),
                                                //       ],
                                                //     ),
                                                //   ),
                                                // ),
                                              
                                              ],
                                            ),
                                        ),
                                      ),
                                    ))  ;
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