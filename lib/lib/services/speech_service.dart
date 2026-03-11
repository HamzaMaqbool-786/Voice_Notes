import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  bool get isListening => _speechToText.isListening;

  /// Initialize the speech recognition service
  Future<bool> initialize() async {
    _isInitialized = await _speechToText.initialize(
      onError: (error) {
        print('Speech recognition error: ${error.errorMsg}');
      },
      onStatus: (status) {
        print('Speech recognition status: $status');
      },
    );
    return _isInitialized;
  }

  /// Start listening and return partial/final results via callback
  Future<void> startListening({
    required Function(String text, bool isFinal) onResult,
    String localeId = '',
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isInitialized) return;

    await _speechToText.listen(
      onResult: (SpeechRecognitionResult result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      localeId: localeId.isNotEmpty ? localeId : null,
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(seconds: 5),
      partialResults: true,
      listenMode: ListenMode.dictation,
    );
  }

  /// Stop listening
  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  /// Cancel listening without saving
  Future<void> cancelListening() async {
    await _speechToText.cancel();
  }

  /// Get available locales
  Future<List<LocaleName>> getLocales() async {
    if (!_isInitialized) await initialize();
    return _speechToText.locales();
  }

  /// Check microphone availability
  Future<bool> hasPermission() async {
    if (!_isInitialized) {
      return await initialize();
    }
    return _isInitialized;
  }
}
