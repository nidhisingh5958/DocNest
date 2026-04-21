// lib/services/database_service.dart
// Handles all local SQLite storage for DocNest

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/document.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  // ── Initialization ─────────────────────────────────────────────────────────
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'docnest.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Documents table
    await db.execute('''
      CREATE TABLE documents (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        title         TEXT    NOT NULL,
        pdf_path      TEXT    NOT NULL,
        image_paths   TEXT    NOT NULL,
        category      TEXT    DEFAULT 'Other',
        tags          TEXT    DEFAULT '',
        extracted_text TEXT,
        created_at    TEXT    NOT NULL,
        updated_at    TEXT    NOT NULL,
        page_count    INTEGER DEFAULT 1,
        folder_path   TEXT    NOT NULL
      )
    ''');

    // Full-text search virtual table for OCR text search
    await db.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS documents_fts
      USING fts4(
        content="documents",
        title,
        extracted_text
      )
    ''');

    // Trigger to keep FTS in sync
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS documents_ai AFTER INSERT ON documents BEGIN
        INSERT INTO documents_fts(rowid, title, extracted_text)
        VALUES (new.id, new.title, new.extracted_text);
      END
    ''');

    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS documents_ad AFTER DELETE ON documents BEGIN
        INSERT INTO documents_fts(documents_fts, rowid, title, extracted_text)
        VALUES ('delete', old.id, old.title, old.extracted_text);
      END
    ''');

    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS documents_au AFTER UPDATE ON documents BEGIN
        INSERT INTO documents_fts(documents_fts, rowid, title, extracted_text)
        VALUES ('delete', old.id, old.title, old.extracted_text);
        INSERT INTO documents_fts(rowid, title, extracted_text)
        VALUES (new.id, new.title, new.extracted_text);
      END
    ''');
  }

  // ── CRUD Operations ────────────────────────────────────────────────────────

  /// Insert a new document; returns the new document with its assigned ID
  Future<Document> insertDocument(Document doc) async {
    final db = await database;
    final id = await db.insert('documents', doc.toMap()..remove('id'));
    return doc.copyWith(id: id);
  }

  /// Fetch all documents, newest first
  Future<List<Document>> getAllDocuments() async {
    final db = await database;
    final rows = await db.query(
      'documents',
      orderBy: 'created_at DESC',
    );
    return rows.map((r) => Document.fromMap(r)).toList();
  }

  /// Fetch documents filtered by category
  Future<List<Document>> getByCategory(String category) async {
    final db = await database;
    final rows = await db.query(
      'documents',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'created_at DESC',
    );
    return rows.map((r) => Document.fromMap(r)).toList();
  }

  /// Full-text search across title and extracted_text
  Future<List<Document>> searchDocuments(String query) async {
    final db = await database;
    // Use FTS for fast text search
    final rows = await db.rawQuery('''
      SELECT d.* FROM documents d
      INNER JOIN documents_fts fts ON d.id = fts.rowid
      WHERE documents_fts MATCH ?
      ORDER BY d.created_at DESC
    ''', [query]);
    return rows.map((r) => Document.fromMap(r)).toList();
  }

  /// Update an existing document
  Future<void> updateDocument(Document doc) async {
    final db = await database;
    await db.update(
      'documents',
      doc.toMap(),
      where: 'id = ?',
      whereArgs: [doc.id],
    );
  }

  /// Delete a document by ID
  Future<void> deleteDocument(int id) async {
    final db = await database;
    await db.delete('documents', where: 'id = ?', whereArgs: [id]);
  }

  /// Fetch a single document by ID
  Future<Document?> getDocumentById(int id) async {
    final db = await database;
    final rows = await db.query(
      'documents',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Document.fromMap(rows.first);
  }

  /// Get total document count
  Future<int> getDocumentCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM documents');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
