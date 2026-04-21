// lib/services/ocr_service.dart
// Offline OCR using Google ML Kit Text Recognition
// Works entirely on-device, no internet required

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  static final OcrService _instance = OcrService._internal();
  factory OcrService() => _instance;
  OcrService._internal();

  // Latin script recognizer (covers English and most European languages)
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Extract text from a single image file path
  /// Returns the full extracted text string (empty if nothing found)
  Future<String> extractText(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _recognizer.processImage(inputImage);
      return recognizedText.text.trim();
    } catch (e) {
      // If OCR fails, return empty — don't crash the app
      return '';
    }
  }

  /// Extract text from multiple pages and combine
  Future<String> extractTextFromPages(List<String> imagePaths) async {
    final buffer = StringBuffer();

    for (int i = 0; i < imagePaths.length; i++) {
      final text = await extractText(imagePaths[i]);
      if (text.isNotEmpty) {
        if (i > 0) buffer.write('\n\n--- Page ${i + 1} ---\n\n');
        buffer.write(text);
      }
    }

    return buffer.toString();
  }

  /// Clean up the recognizer when done
  void dispose() {
    _recognizer.close();
  }
}
