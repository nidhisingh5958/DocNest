// lib/screens/scan_screen.dart
// Document scanning screen: camera → edge detect → filter → multi-page → PDF

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import '../models/document.dart';
import '../services/document_service.dart';
import '../services/storage_service.dart';
import '../utils/theme.dart';
import '../widgets/filter_selector.dart';
import '../widgets/page_thumbnail_strip.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _docService = DocumentService();

  // Accumulated scanned pages
  List<String> _scannedPages = [];
  ImageFilter _selectedFilter = ImageFilter.original;
  bool _isProcessing = false;
  bool _isSaving = false;
  String _title = '';
  String _selectedCategory = 'Other';

  // ── Scan ───────────────────────────────────────────────────────────────────

  Future<void> _startScan() async {
    try {
      // Uses cunning_document_scanner which handles edge detection automatically
      final pictures = await CunningDocumentScanner.getPictures(
        noOfPages: 10, // Allow up to 10 pages
        isGalleryImportAllowed: true,
      );

      if (pictures != null && pictures.isNotEmpty) {
        setState(() {
          _scannedPages.addAll(pictures);
          // Auto-set a default title
          if (_title.isEmpty) {
            _title = 'Document ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Could not open camera. Please check permissions.');
      }
    }
  }

  Future<void> _removePage(int index) async {
    setState(() {
      _scannedPages.removeAt(index);
    });
  }

  Future<void> _reorderPages(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final page = _scannedPages.removeAt(oldIndex);
      _scannedPages.insert(newIndex, page);
    });
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _saveDocument() async {
    if (_scannedPages.isEmpty) return;
    if (_title.trim().isEmpty) {
      _showTitleDialog();
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _docService.saveScannedDocument(
        scannedImagePaths: _scannedPages,
        title: _title.trim(),
        category: _selectedCategory,
        filter: _selectedFilter,
      );

      if (mounted) {
        // Clear state and show success
        setState(() {
          _scannedPages = [];
          _title = '';
          _selectedFilter = ImageFilter.original;
          _selectedCategory = 'Other';
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Document saved successfully'),
              ],
            ),
            backgroundColor: DocNestTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showError('Failed to save document. Please try again.');
    }
  }

  // ── Title Dialog ───────────────────────────────────────────────────────────

  void _showTitleDialog() {
    final controller = TextEditingController(text: _title);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Document Name',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Electricity Bill March',
          ),
          onSubmitted: (val) {
            Navigator.pop(ctx);
            setState(() => _title = val);
            _saveDocument();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _title = controller.text);
              _saveDocument();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: DocNestTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DocNestTheme.background,
      body: SafeArea(
        child: _scannedPages.isEmpty
            ? _buildEmptyState()
            : _buildScanPreview(),
      ),
    );
  }

  // Empty state: big scan button
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App wordmark
          const Text(
            'DocNest',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: DocNestTheme.primary,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Scan & organize your documents',
            style: TextStyle(color: DocNestTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 60),

          // Big scan button
          GestureDetector(
            onTap: _startScan,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: DocNestTheme.accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: DocNestTheme.accent.withOpacity(0.35),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.document_scanner_rounded,
                    size: 52, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    'Scan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),
          const Text(
            'Tap to open camera',
            style: TextStyle(color: DocNestTheme.textHint, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // Preview scanned pages
  Widget _buildScanPreview() {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              Text(
                '${_scannedPages.length} page${_scannedPages.length != 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700,
                  color: DocNestTheme.primary,
                ),
              ),
              const Spacer(),
              // Add more pages
              IconButton.outlined(
                onPressed: _startScan,
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  foregroundColor: DocNestTheme.accent,
                  side: const BorderSide(color: DocNestTheme.accent),
                ),
              ),
            ],
          ),
        ),

        // Thumbnail strip (reorderable)
        PageThumbnailStrip(
          pages: _scannedPages,
          onRemove: _removePage,
          onReorder: _reorderPages,
        ),

        const SizedBox(height: 16),

        // Filter selector
        FilterSelector(
          selected: _selectedFilter,
          onChanged: (f) => setState(() => _selectedFilter = f),
          imagePath: _scannedPages.first,
        ),

        const Spacer(),

        // Title and category input
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // Document title
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Document name',
                  prefixIcon: Icon(Icons.edit_outlined, size: 20),
                ),
                controller: TextEditingController(text: _title),
                onChanged: (v) => _title = v,
              ),
              const SizedBox(height: 12),

              // Category picker
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: DocNestTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DocNestTheme.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    hint: const Text('Category'),
                    items: DocCategory.all.map((cat) => DropdownMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(
                              color: DocNestTheme.tagColors[cat] ??
                                  DocNestTheme.textHint,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(cat),
                        ],
                      ),
                    )).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedCategory = v);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Save button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveDocument,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_isSaving ? 'Saving...' : 'Save Document'),
            ),
          ),
        ),
      ],
    );
  }
}
