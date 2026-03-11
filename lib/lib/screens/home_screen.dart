import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/notes_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/note_card.dart';
import '../widgets/recording_sheet.dart';
import '../screens/note_detail_screen.dart';
import '../models/note.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _isSearching = false;
  late AnimationController _fabController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotesProvider>().loadNotes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _fabController.dispose();
    super.dispose();
  }

  void _openRecordingSheet() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RecordingSheet(),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✓ Note saved successfully',
            style: GoogleFonts.inter(fontSize: 14),
          ),
          backgroundColor: const Color(0xFF6C63FF),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _deleteNote(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Note',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This note will be permanently deleted.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: GoogleFonts.inter(color: const Color(0xFFFF4D6D))),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<NotesProvider>().deleteNote(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? const Color(0xFFE0E0F0) : const Color(0xFF1A1A2E);
    final subtleColor =
        isDark ? const Color(0xFF9090B0) : const Color(0xFF888899);
    final bgColor = isDark ? const Color(0xFF13131F) : const Color(0xFFF0F0FA);
    final accentColor = const Color(0xFF6C63FF);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Consumer<NotesProvider>(
                          builder: (context, provider, _) => Text(
                            '${provider.allNotes.length} Notes',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: subtleColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Voice Notes',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Theme toggle
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) => GestureDetector(
                      onTap: themeProvider.toggleTheme,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2D2D44)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: isDark
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                        ),
                        child: Icon(
                          isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          color: isDark
                              ? const Color(0xFFFFD700)
                              : const Color(0xFF6C63FF),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          )
                        ],
                ),
                child: Consumer<NotesProvider>(
                  builder: (context, provider, _) => TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    onChanged: (value) {
                      provider.setSearchQuery(value);
                      setState(() => _isSearching = value.isNotEmpty);
                    },
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search notes...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 15,
                        color: textColor.withOpacity(0.35),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: textColor.withOpacity(0.4),
                        size: 22,
                      ),
                      suffixIcon: _isSearching
                          ? IconButton(
                              icon: Icon(Icons.close_rounded,
                                  color: textColor.withOpacity(0.4), size: 20),
                              onPressed: () {
                                _searchController.clear();
                                provider.clearSearch();
                                setState(() => _isSearching = false);
                                _searchFocus.unfocus();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Notes list
            Expanded(
              child: Consumer<NotesProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: accentColor,
                        strokeWidth: 2,
                      ),
                    );
                  }

                  final notes = provider.notes;

                  if (notes.isEmpty) {
                    return _buildEmptyState(
                      isDark: isDark,
                      textColor: textColor,
                      subtleColor: subtleColor,
                      isSearching: _isSearching,
                      accentColor: accentColor,
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return NoteCard(
                        note: note,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NoteDetailScreen(note: note),
                            ),
                          );
                        },
                        onDelete: () => _deleteNote(context, note.id),
                        onEdit: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NoteDetailScreen(
                                  note: note, isEditing: true),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // FAB
      floatingActionButton: GestureDetector(
        onTapDown: (_) => _fabController.forward(),
        onTapUp: (_) {
          _fabController.reverse();
          _openRecordingSheet();
        },
        onTapCancel: () => _fabController.reverse(),
        child: ScaleTransition(
          scale: _fabScaleAnimation,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6C63FF),
                  Color(0xFF9B8FFF),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.mic_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required bool isDark,
    required Color textColor,
    required Color subtleColor,
    required bool isSearching,
    required Color accentColor,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSearching ? Icons.search_off_rounded : Icons.mic_none_rounded,
              color: accentColor.withOpacity(0.6),
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isSearching ? 'No notes found' : 'No voice notes yet',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'Try a different search term'
                : 'Tap the mic button to record your first note',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: subtleColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
