// lib/models/document.dart
// Core data model for a scanned document

class Document {
  final int? id;
  final String title;
  final String pdfPath;       // Absolute path to PDF on device
  final List<String> imagePaths; // Paths to individual page images
  final String category;
  final List<String> tags;
  final String? extractedText; // OCR result
  final DateTime createdAt;
  final DateTime updatedAt;
  final int pageCount;
  final String folderPath;    // Relative folder path (Year/Category)

  Document({
    this.id,
    required this.title,
    required this.pdfPath,
    required this.imagePaths,
    this.category = 'Other',
    this.tags = const [],
    this.extractedText,
    required this.createdAt,
    required this.updatedAt,
    this.pageCount = 1,
    required this.folderPath,
  });

  // Convert to Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'pdf_path': pdfPath,
      'image_paths': imagePaths.join('|'), // pipe-separated list
      'category': category,
      'tags': tags.join(','),
      'extracted_text': extractedText,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'page_count': pageCount,
      'folder_path': folderPath,
    };
  }

  // Build Document from SQLite row
  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      id: map['id'] as int?,
      title: map['title'] as String,
      pdfPath: map['pdf_path'] as String,
      imagePaths: (map['image_paths'] as String?)
              ?.split('|')
              .where((p) => p.isNotEmpty)
              .toList() ??
          [],
      category: map['category'] as String? ?? 'Other',
      tags: (map['tags'] as String?)
              ?.split(',')
              .where((t) => t.isNotEmpty)
              .toList() ??
          [],
      extractedText: map['extracted_text'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      pageCount: map['page_count'] as int? ?? 1,
      folderPath: map['folder_path'] as String,
    );
  }

  // Create a copy with some fields changed
  Document copyWith({
    int? id,
    String? title,
    String? pdfPath,
    List<String>? imagePaths,
    String? category,
    List<String>? tags,
    String? extractedText,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? pageCount,
    String? folderPath,
  }) {
    return Document(
      id: id ?? this.id,
      title: title ?? this.title,
      pdfPath: pdfPath ?? this.pdfPath,
      imagePaths: imagePaths ?? this.imagePaths,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      extractedText: extractedText ?? this.extractedText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pageCount: pageCount ?? this.pageCount,
      folderPath: folderPath ?? this.folderPath,
    );
  }
}

// Available categories for documents
class DocCategory {
  static const List<String> all = [
    'Bills',
    'Notes',
    'Personal',
    'Work',
    'Other',
  ];

  // Auto-suggest category based on filename keywords
  static String suggest(String filename) {
    final lower = filename.toLowerCase();
    if (lower.contains('bill') || lower.contains('invoice') ||
        lower.contains('receipt') || lower.contains('payment')) {
      return 'Bills';
    }
    if (lower.contains('note') || lower.contains('memo') ||
        lower.contains('draft')) {
      return 'Notes';
    }
    if (lower.contains('id') || lower.contains('passport') ||
        lower.contains('license') || lower.contains('personal')) {
      return 'Personal';
    }
    if (lower.contains('work') || lower.contains('contract') ||
        lower.contains('report') || lower.contains('project')) {
      return 'Work';
    }
    return 'Other';
  }
}
