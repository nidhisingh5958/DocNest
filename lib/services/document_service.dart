// lib/services/document_service.dart
// Core business logic: scanning → processing → saving → retrieving

import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import '../models/document.dart';
import 'database_service.dart';
import 'storage_service.dart';
import 'ocr_service.dart';

class DocumentService {
  static final DocumentService _instance = DocumentService._internal();
  factory DocumentService() => _instance;
  DocumentService._internal();

  final _db      = DatabaseService();
  final _storage = StorageService();
  final _ocr     = OcrService();

  // ── Scan & Save Flow ───────────────────────────────────────────────────────

  /// Main entry: takes scanned image paths, creates PDF, runs OCR, saves to DB
  Future<Document> saveScannedDocument({
    required List<String> scannedImagePaths,
    required String title,
    String? category,
    List<String> tags = const [],
    ImageFilter filter = ImageFilter.original,
  }) async {
    // 1. Auto-suggest category if not provided
    final resolvedCategory = category ?? DocCategory.suggest(title);

    // 2. Apply image filter to all pages
    final processedPaths = <String>[];
    for (int i = 0; i < scannedImagePaths.length; i++) {
      final srcPath = scannedImagePaths[i];
      if (filter != ImageFilter.original) {
        final filtered = await _storage.applyFilter(srcPath, filter);
        final newPath = await _storage.saveImage(
          filtered,
          'page_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        processedPaths.add(newPath);
      } else {
        processedPaths.add(srcPath);
      }
    }

    // 3. Generate PDF
    final pdfPath = await _storage.createPdf(
      imagePaths: processedPaths,
      title: title,
      category: resolvedCategory,
    );

    // 4. OCR extraction (runs in background, non-blocking for UI)
    final extractedText = await _ocr.extractTextFromPages(processedPaths);

    // 5. Build folder path for display
    final year = DateTime.now().year.toString();
    final folderPath = '$year/$resolvedCategory';

    // 6. Save to SQLite
    final now = DateTime.now();
    final doc = Document(
      title: title,
      pdfPath: pdfPath,
      imagePaths: processedPaths,
      category: resolvedCategory,
      tags: tags,
      extractedText: extractedText,
      createdAt: now,
      updatedAt: now,
      pageCount: scannedImagePaths.length,
      folderPath: folderPath,
    );

    return await _db.insertDocument(doc);
  }

  // ── Retrieval ──────────────────────────────────────────────────────────────

  Future<List<Document>> getAllDocuments() => _db.getAllDocuments();

  Future<List<Document>> getByCategory(String category) =>
      _db.getByCategory(category);

  Future<List<Document>> searchDocuments(String query) =>
      _db.searchDocuments(query);

  Future<Document?> getDocumentById(int id) => _db.getDocumentById(id);

  // ── Update ─────────────────────────────────────────────────────────────────

  Future<void> renameDocument(Document doc, String newTitle) async {
    final updated = doc.copyWith(
      title: newTitle,
      updatedAt: DateTime.now(),
    );
    await _db.updateDocument(updated);
  }

  Future<void> updateTags(Document doc, List<String> tags) async {
    final updated = doc.copyWith(tags: tags, updatedAt: DateTime.now());
    await _db.updateDocument(updated);
  }

  Future<void> moveToCategory(Document doc, String newCategory) async {
    final updated = doc.copyWith(
      category: newCategory,
      updatedAt: DateTime.now(),
      folderPath: '${DateTime.now().year}/$newCategory',
    );
    await _db.updateDocument(updated);
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> deleteDocument(Document doc) async {
    await _storage.deleteDocumentFiles(doc);
    if (doc.id != null) await _db.deleteDocument(doc.id!);
  }

  // ── Stats ──────────────────────────────────────────────────────────────────

  Future<int> getDocumentCount() => _db.getDocumentCount();

  Future<String> getStorageUsed() async {
    final bytes = await _storage.getTotalStorageUsed();
    return _storage.formatBytes(bytes);
  }
}
