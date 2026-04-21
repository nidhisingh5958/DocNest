// lib/services/storage_service.dart
// Manages local file system: folders, PDFs, images

import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import '../models/document.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // ── Root Directory ─────────────────────────────────────────────────────────
  Future<Directory> get rootDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'DocNest'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Build the structured path: DocNest/Year/Category/
  Future<Directory> getCategoryDir(String category) async {
    final root = await rootDir;
    final year = DateTime.now().year.toString();
    final dir = Directory(p.join(root.path, year, category));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  // ── Image Operations ───────────────────────────────────────────────────────

  /// Save a raw image byte list to disk and return its path
  Future<String> saveImage(Uint8List bytes, String filename) async {
    final dir = await rootDir;
    final tempDir = Directory(p.join(dir.path, '.cache'));
    if (!await tempDir.exists()) await tempDir.create(recursive: true);

    final file = File(p.join(tempDir.path, filename));
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Apply a filter to an image and return the processed bytes
  Future<Uint8List> applyFilter(String imagePath, ImageFilter filter) async {
    final file = File(imagePath);
    final bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return bytes;

    switch (filter) {
      case ImageFilter.grayscale:
        image = img.grayscale(image);
        break;
      case ImageFilter.blackAndWhite:
        image = img.grayscale(image);
        // Threshold to make it truly black & white
        for (int y = 0; y < image.height; y++) {
          for (int x = 0; x < image.width; x++) {
            final pixel = image.getPixel(x, y);
            final brightness = img.getRed(pixel);
            image.setPixel(
              x, y,
              brightness > 128
                  ? img.getColor(255, 255, 255)
                  : img.getColor(0, 0, 0),
            );
          }
        }
        break;
      case ImageFilter.enhanced:
        // Boost contrast and brightness
        image = img.adjustColor(image, contrast: 1.3, brightness: 1.1);
        break;
      case ImageFilter.original:
        // No change
        break;
    }

    return Uint8List.fromList(img.encodeJpg(image, quality: 90));
  }

  // ── PDF Generation ─────────────────────────────────────────────────────────

  /// Convert a list of image paths into a single PDF file
  /// Returns the path to the generated PDF
  Future<String> createPdf({
    required List<String> imagePaths,
    required String title,
    required String category,
  }) async {
    final pdf = pw.Document();

    for (final imagePath in imagePaths) {
      final imageBytes = await File(imagePath).readAsBytes();
      final pdfImage = pw.MemoryImage(imageBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (context) => pw.Center(
            child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
          ),
        ),
      );
    }

    // Save to category folder
    final dir = await getCategoryDir(category);
    final safeTitle = title.replaceAll(RegExp(r'[^\w\s-]'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final pdfPath = p.join(dir.path, '${safeTitle}_$timestamp.pdf');

    final file = File(pdfPath);
    await file.writeAsBytes(await pdf.save());
    return pdfPath;
  }

  // ── Directory Management ───────────────────────────────────────────────────

  /// List all year/category directories
  Future<List<String>> listFolders() async {
    final root = await rootDir;
    final folders = <String>[];

    await for (final yearDir in root.list()) {
      if (yearDir is Directory) {
        await for (final catDir in yearDir.list()) {
          if (catDir is Directory) {
            folders.add(p.relative(catDir.path, from: root.path));
          }
        }
      }
    }
    return folders;
  }

  /// Delete a file and its associated resources
  Future<void> deleteDocumentFiles(Document doc) async {
    // Delete PDF
    final pdfFile = File(doc.pdfPath);
    if (await pdfFile.exists()) await pdfFile.delete();

    // Delete page images
    for (final imgPath in doc.imagePaths) {
      final imgFile = File(imgPath);
      if (await imgFile.exists()) await imgFile.delete();
    }
  }

  /// Get total storage used by DocNest in bytes
  Future<int> getTotalStorageUsed() async {
    final root = await rootDir;
    int total = 0;
    await for (final entity in root.list(recursive: true)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  /// Format bytes into human-readable string
  String formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}

// Available image filters
enum ImageFilter {
  original,
  grayscale,
  blackAndWhite,
  enhanced,
}

extension ImageFilterLabel on ImageFilter {
  String get label {
    switch (this) {
      case ImageFilter.original:    return 'Original';
      case ImageFilter.grayscale:   return 'Grayscale';
      case ImageFilter.blackAndWhite: return 'B&W';
      case ImageFilter.enhanced:    return 'Enhanced';
    }
  }
}
