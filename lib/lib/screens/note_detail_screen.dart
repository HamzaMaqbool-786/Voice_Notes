import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note note;
  final bool isEditing;

  const NoteDetailScreen({
    super.key,
    required this.note,
    this.isEditing = false,
  });

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isEditing = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.isEditing;
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);

    _titleController.addListener(() => setState(() => _hasChanges = true));
    _contentController.addListener(() => setState(() => _hasChanges = true));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges) {
      setState(() => _isEditing = false);
      return;
    }

    await context.read<NotesProvider>().updateNote(
          widget.note.id,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
        );

    if (mounted) {
      setState(() {
        _isEditing = false;
        _hasChanges = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Note saved',
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

  Future<void> _deleteNote() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(color: const Color(0xFFFF4D6D)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<NotesProvider>().deleteNote(widget.note.id);
      Navigator.of(context).pop();
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
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: textColor),
          onPressed: () {
            if (_isEditing && _hasChanges) {
              // Show unsaved changes dialog
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: Text('Unsaved Changes',
                      style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w700)),
                  content: Text('Save your changes?',
                      style: GoogleFonts.inter(fontSize: 14)),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      child: Text('Discard',
                          style: GoogleFonts.inter(color: Colors.grey)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _saveChanges();
                      },
                      child: Text('Save',
                          style: GoogleFonts.inter(color: accentColor)),
                    ),
                  ],
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          if (!_isEditing) ...[
            IconButton(
              icon: Icon(Icons.edit_outlined, color: accentColor),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFFF4D6D)),
              onPressed: _deleteNote,
              tooltip: 'Delete',
            ),
          ] else ...[
            TextButton.icon(
              onPressed: _hasChanges ? _saveChanges : null,
              icon: Icon(Icons.check_rounded, size: 18, color: accentColor),
              label: Text(
                'Save',
                style: GoogleFonts.inter(
                  color: _hasChanges ? accentColor : accentColor.withOpacity(0.4),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metadata
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mic_rounded, size: 13, color: accentColor),
                      const SizedBox(width: 4),
                      Text(
                        'Voice Note',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: accentColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.note.recordingDuration != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: subtleColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${widget.note.recordingDuration!.inMinutes.toString().padLeft(2, '0')}:${(widget.note.recordingDuration!.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        color: subtleColor,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Title
            _isEditing
                ? TextField(
                    controller: _titleController,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Note title...',
                      hintStyle: GoogleFonts.spaceGrotesk(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: textColor.withOpacity(0.3),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    maxLines: 2,
                    minLines: 1,
                  )
                : Text(
                    widget.note.title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),

            const SizedBox(height: 8),

            // Date
            Text(
              DateFormat('EEEE, MMMM d, y · h:mm a')
                  .format(widget.note.createdAt),
              style: GoogleFonts.inter(
                fontSize: 13,
                color: subtleColor,
              ),
            ),

            const SizedBox(height: 20),

            // Divider
            Divider(
              color: isDark
                  ? const Color(0xFF2D2D44)
                  : const Color(0xFFE0E0F0),
              height: 1,
            ),

            const SizedBox(height: 20),

            // Content
            _isEditing
                ? TextField(
                    controller: _contentController,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: textColor,
                      height: 1.7,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Start writing...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 16,
                        color: textColor.withOpacity(0.3),
                        height: 1.7,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    maxLines: null,
                    minLines: 10,
                    textInputAction: TextInputAction.newline,
                  )
                : Text(
                    widget.note.content,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: textColor,
                      height: 1.7,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
