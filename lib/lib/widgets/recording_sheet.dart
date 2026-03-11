import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/speech_service.dart';
import '../providers/notes_provider.dart';

class RecordingSheet extends StatefulWidget {
  const RecordingSheet({super.key});

  @override
  State<RecordingSheet> createState() => _RecordingSheetState();
}

class _RecordingSheetState extends State<RecordingSheet>
    with TickerProviderStateMixin {
  final SpeechService _speechService = SpeechService();

  bool _isRecording = false;
  bool _isInitializing = false;
  bool _isSaving = false;
  String _transcribedText = '';
  String _partialText = '';
  Duration _recordingDuration = Duration.zero;
  Timer? _durationTimer;
  DateTime? _recordingStartTime;

  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    setState(() => _isInitializing = true);
    await _speechService.initialize();
    setState(() => _isInitializing = false);
  }

  void _startRecording() async {
    if (_isInitializing) return;
    HapticFeedback.mediumImpact();

    final hasPermission = await _speechService.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission required'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isRecording = true;
      _recordingStartTime = DateTime.now();
      _transcribedText = '';
      _partialText = '';
    });

    _pulseController.repeat(reverse: true);
    _waveController.repeat(reverse: true);

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordingDuration = DateTime.now().difference(_recordingStartTime!);
        });
      }
    });

    await _speechService.startListening(
      onResult: (text, isFinal) {
        if (mounted) {
          setState(() {
            if (isFinal) {
              _transcribedText += ' $text';
              _partialText = '';
            } else {
              _partialText = text;
            }
          });
        }
      },
    );
  }

  void _stopRecording() async {
    HapticFeedback.lightImpact();
    await _speechService.stopListening();

    _durationTimer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    _waveController.stop();
    _waveController.reset();

    final finalText = '$_transcribedText $_partialText'.trim();

    setState(() {
      _isRecording = false;
      _transcribedText = finalText;
      _partialText = '';
    });
  }

  Future<void> _saveNote() async {
    final text = _transcribedText.trim();
    if (text.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isSaving = true);

    await context.read<NotesProvider>().addNote(
          content: text,
          recordingDuration: _recordingDuration,
        );

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _discard() {
    if (_isRecording) {
      _speechService.cancelListening();
      _durationTimer?.cancel();
      _pulseController.stop();
      _waveController.stop();
    }
    Navigator.of(context).pop(false);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF6C63FF);
    final bgColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final textColor = isDark ? const Color(0xFFE0E0F0) : const Color(0xFF1A1A2E);
    final subtleColor = isDark ? const Color(0xFF2D2D44) : const Color(0xFFF0F0FA);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 12,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3D3D5C) : const Color(0xFFDDDDF0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            _isRecording ? 'Listening...' : 'Voice Note',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),

          // Timer
          Text(
            _formatDuration(_recordingDuration),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              color: _isRecording ? primaryColor : textColor.withOpacity(0.4),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),

          // Transcription box
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 120, maxHeight: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: subtleColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isRecording
                    ? primaryColor.withOpacity(0.4)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: SingleChildScrollView(
              child: _transcribedText.isEmpty && _partialText.isEmpty
                  ? Text(
                      _isInitializing
                          ? 'Initializing speech recognition...'
                          : _isRecording
                              ? 'Speak now...'
                              : 'Press and hold the mic to start recording',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: textColor.withOpacity(0.35),
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: _transcribedText,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: textColor,
                              height: 1.6,
                            ),
                          ),
                          if (_partialText.isNotEmpty)
                            TextSpan(
                              text: ' $_partialText',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: textColor.withOpacity(0.45),
                                height: 1.6,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 32),

          // Mic button
          GestureDetector(
            onTapDown: (_) {
              if (!_isRecording && !_isInitializing) _startRecording();
            },
            onTapUp: (_) {
              if (_isRecording) _stopRecording();
            },
            onTapCancel: () {
              if (_isRecording) _stopRecording();
            },
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isRecording ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _isRecording
                            ? [
                                const Color(0xFFFF6584),
                                const Color(0xFFFF8C6B),
                              ]
                            : [
                                primaryColor,
                                const Color(0xFF9B8FFF),
                              ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording
                                  ? const Color(0xFFFF6584)
                                  : primaryColor)
                              .withOpacity(0.45),
                          blurRadius: _isRecording ? 24 : 16,
                          spreadRadius: _isRecording ? 4 : 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),
          Text(
            _isRecording ? 'Tap to stop' : 'Tap to record',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: textColor.withOpacity(0.4),
            ),
          ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _discard,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF3D3D5C)
                            : const Color(0xFFDDDDF0),
                      ),
                    ),
                  ),
                  child: Text(
                    'Discard',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textColor.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: (_transcribedText.isNotEmpty && !_isSaving)
                      ? _saveNote
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    disabledBackgroundColor: primaryColor.withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Save Note',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
