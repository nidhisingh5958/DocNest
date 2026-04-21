// lib/screens/document_detail_screen.dart
// Full document view: PDF preview, OCR text, tags, share, rename

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import '../models/document.dart';
import '../services/document_service.dart';
import '../services/share_service.dart';
import '../utils/theme.dart';
import '../widgets/tag_chip.dart';

class DocumentDetailScreen extends StatefulWidget {
  final Document document;

  const DocumentDetailScreen({super.key, required this.document});

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen>
    with SingleTickerProviderStateMixin {
  late Document _doc;
  final _docService   = DocumentService();
  final _shareService = ShareService();
  late TabController _tabController;
  bool _showFullText = false;

  @override
  void initState() {
    super.initState();
    _doc = widget.document;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _openPdf() async {
    await OpenFilex.open(_doc.pdfPath);
  }

  Future<void> _shareDocument() async {
    await _shareService.shareDocument(_doc);
  }

  Future<void> _renameDocument() async {
    final controller = TextEditingController(text: _doc.title);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rename Document'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Document name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      await _docService.renameDocument(_doc, result.trim());
      setState(() => _doc = _doc.copyWith(title: result.trim()));
    }
  }

  Future<void> _editTags() async {
    final currentTags = List<String>.from(_doc.tags);
    final allTags = DocCategory.all;

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tags',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: allTags.map((tag) {
                  final selected = currentTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: selected,
                    selectedColor: (DocNestTheme.tagColors[tag] ??
                        DocNestTheme.accent).withOpacity(0.15),
                    checkmarkColor: DocNestTheme.tagColors[tag] ?? DocNestTheme.accent,
                    labelStyle: TextStyle(
                      color: selected
                          ? (DocNestTheme.tagColors[tag] ?? DocNestTheme.accent)
                          : DocNestTheme.textSecondary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    onSelected: (v) {
                      setModalState(() {
                        if (v) {
                          currentTags.add(tag);
                        } else {
                          currentTags.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _docService.updateTags(_doc, currentTags);
                    setState(() => _doc = _doc.copyWith(tags: currentTags));
                  },
                  child: const Text('Save Tags'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyText() {
    if (_doc.extractedText == null || _doc.extractedText!.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _doc.extractedText!));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Text copied to clipboard'),
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
      appBar: AppBar(
        title: Text(
          _doc.title,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _renameDocument,
            tooltip: 'Rename',
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: _shareDocument,
            tooltip: 'Share',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Preview'),
            Tab(text: 'Text'),
          ],
          labelColor: DocNestTheme.accent,
          unselectedLabelColor: DocNestTheme.textSecondary,
          indicatorColor: DocNestTheme.accent,
          indicatorSize: TabBarIndicatorSize.label,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPreviewTab(),
          _buildTextTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildPreviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PDF thumbnail / open button
          GestureDetector(
            onTap: _openPdf,
            child: Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: DocNestTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DocNestTheme.border),
              ),
              child: _doc.imagePaths.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(_doc.imagePaths.first),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _pdfIcon(),
                    ),
                  )
                : _pdfIcon(),
            ),
          ),

          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: _openPdf,
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Open full PDF'),
              style: TextButton.styleFrom(foregroundColor: DocNestTheme.accent),
            ),
          ),

          const SizedBox(height: 20),

          // Metadata card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DocNestTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DocNestTheme.border),
            ),
            child: Column(
              children: [
                _metaRow(Icons.folder_outlined,   'Category',  _doc.category),
                _metaRow(Icons.description_outlined,'Pages',   '${_doc.pageCount}'),
                _metaRow(Icons.calendar_today_outlined,'Date', _formatDate(_doc.createdAt)),
                _metaRow(Icons.folder_open_outlined, 'Folder', _doc.folderPath),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tags
          Row(
            children: [
              const Text('Tags',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                    color: DocNestTheme.textSecondary)),
              const Spacer(),
              TextButton(
                onPressed: _editTags,
                child: const Text('Edit'),
                style: TextButton.styleFrom(
                  foregroundColor: DocNestTheme.accent,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_doc.tags.isEmpty)
            const Text('No tags yet. Tap Edit to add.',
              style: TextStyle(color: DocNestTheme.textHint, fontSize: 13))
          else
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _doc.tags.map((t) => TagChip(tag: t)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTextTab() {
    final text = _doc.extractedText;
    if (text == null || text.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.text_snippet_outlined, size: 48, color: DocNestTheme.textHint),
            SizedBox(height: 12),
            Text(
              'No text extracted',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                  color: DocNestTheme.textSecondary),
            ),
            SizedBox(height: 6),
            Text(
              'OCR could not find readable text\nin this document.',
              style: TextStyle(color: DocNestTheme.textHint, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Copy button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Text(
                '${text.split(' ').length} words extracted',
                style: const TextStyle(color: DocNestTheme.textSecondary, fontSize: 12),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _copyText,
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy all'),
                style: TextButton.styleFrom(
                  foregroundColor: DocNestTheme.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ),
        ),

        // Text content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DocNestTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DocNestTheme.border),
              ),
              child: SelectableText(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: DocNestTheme.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: DocNestTheme.surface,
        border: Border(top: BorderSide(color: DocNestTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _editTags,
              icon: const Icon(Icons.label_outline, size: 18),
              label: const Text('Tags'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: DocNestTheme.border),
                foregroundColor: DocNestTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _shareDocument,
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text('Share'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _pdfIcon() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.picture_as_pdf_rounded,
          size: 64, color: DocNestTheme.accent.withOpacity(0.5)),
        const SizedBox(height: 8),
        const Text('Tap to open PDF',
          style: TextStyle(color: DocNestTheme.textSecondary, fontSize: 13)),
      ],
    );
  }

  Widget _metaRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: DocNestTheme.textSecondary),
          const SizedBox(width: 12),
          Text(label,
            style: const TextStyle(color: DocNestTheme.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(value,
            style: const TextStyle(
              color: DocNestTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            )),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day} ${_month(dt.month)} ${dt.year}';
  }

  String _month(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }
}
