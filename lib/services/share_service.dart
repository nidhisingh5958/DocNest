// lib/services/share_service.dart
// Local file sharing via system share sheet (Bluetooth, Wi-Fi Direct, Nearby)
// Uses the OS share sheet which handles Bluetooth/Wi-Fi Direct automatically

import 'package:share_plus/share_plus.dart';
import '../models/document.dart';

class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  /// Share a document PDF using the system share sheet.
  /// On Android, this shows Bluetooth, Nearby Share, Wi-Fi Direct, etc.
  Future<void> shareDocument(Document doc) async {
    final pdfFile = XFile(doc.pdfPath, mimeType: 'application/pdf');

    await Share.shareXFiles(
      [pdfFile],
      subject: doc.title,
      text: 'Sharing "${doc.title}" from DocNest',
    );
  }

  /// Share multiple documents at once
  Future<void> shareMultipleDocuments(List<Document> docs) async {
    final files = docs.map((d) => XFile(d.pdfPath, mimeType: 'application/pdf')).toList();

    await Share.shareXFiles(
      files,
      subject: '${docs.length} documents from DocNest',
    );
  }

  /// Share just the extracted text (e.g., for copying to other apps)
  Future<void> shareExtractedText(Document doc) async {
    if (doc.extractedText == null || doc.extractedText!.isEmpty) return;

    await Share.share(
      doc.extractedText!,
      subject: '${doc.title} — Extracted Text',
    );
  }
}
