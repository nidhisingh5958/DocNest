// lib/screens/share_screen.dart
// Local sharing hub: select documents and share via Bluetooth/Wi-Fi Direct/Nearby

import 'package:flutter/material.dart';
import '../models/document.dart';
import '../services/document_service.dart';
import '../services/share_service.dart';
import '../utils/theme.dart';
import '../widgets/document_card.dart';

class ShareScreen extends StatefulWidget {
  const ShareScreen({super.key});

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  final _docService   = DocumentService();
  final _shareService = ShareService();

  List<Document> _documents = [];
  final Set<int> _selectedIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final docs = await _docService.getAllDocuments();
    setState(() {
      _documents = docs;
      _isLoading = false;
    });
  }

  void _toggleSelect(Document doc) {
    if (doc.id == null) return;
    setState(() {
      if (_selectedIds.contains(doc.id)) {
        _selectedIds.remove(doc.id);
      } else {
        _selectedIds.add(doc.id!);
      }
    });
  }

  Future<void> _shareSelected() async {
    final selected = _documents
        .where((d) => d.id != null && _selectedIds.contains(d.id))
        .toList();

    if (selected.isEmpty) return;

    if (selected.length == 1) {
      await _shareService.shareDocument(selected.first);
    } else {
      await _shareService.shareMultipleDocuments(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DocNestTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Share info banner ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: DocNestTheme.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                      color: DocNestTheme.accent, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Uses Bluetooth, Wi-Fi Direct, or Nearby Share — no internet needed',
                        style: TextStyle(
                          color: DocNestTheme.accent, fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Share method icons ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _shareMethodBadge(Icons.bluetooth_rounded, 'Bluetooth'),
                  const SizedBox(width: 8),
                  _shareMethodBadge(Icons.wifi_tethering_rounded, 'Wi-Fi Direct'),
                  const SizedBox(width: 8),
                  _shareMethodBadge(Icons.share_location_rounded, 'Nearby'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Document selection list ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    '${_selectedIds.length} selected',
                    style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: DocNestTheme.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (_selectedIds.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(() => _selectedIds.clear()),
                      style: TextButton.styleFrom(
                        foregroundColor: DocNestTheme.danger,
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text('Clear'),
                    ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _documents.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      itemCount: _documents.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final doc = _documents[i];
                        final isSelected = doc.id != null &&
                            _selectedIds.contains(doc.id);
                        return GestureDetector(
                          onTap: () => _toggleSelect(doc),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? DocNestTheme.accent
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: DocumentCard(
                              document: doc,
                              isGrid: false,
                              isSelectable: true,
                              isSelected: isSelected,
                              onTap: () => _toggleSelect(doc),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // ── Share button ──────────────────────────────────────────────
            if (_selectedIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _shareSelected,
                    icon: const Icon(Icons.share_rounded),
                    label: Text(
                      'Share ${_selectedIds.length} document${_selectedIds.length != 1 ? 's' : ''}',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _shareMethodBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: DocNestTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DocNestTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: DocNestTheme.textSecondary),
          const SizedBox(width: 4),
          Text(label,
            style: const TextStyle(
              fontSize: 11, color: DocNestTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.share_outlined, size: 56, color: DocNestTheme.textHint),
          SizedBox(height: 16),
          Text('No documents to share',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                color: DocNestTheme.textSecondary)),
          SizedBox(height: 8),
          Text('Scan some documents first',
            style: TextStyle(color: DocNestTheme.textHint, fontSize: 13)),
        ],
      ),
    );
  }
}
