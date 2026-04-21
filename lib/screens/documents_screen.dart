// lib/screens/documents_screen.dart
// Main document browser: list/grid, search, filter by category

import 'package:flutter/material.dart';
import '../models/document.dart';
import '../services/document_service.dart';
import '../utils/theme.dart';
import '../widgets/document_card.dart';
import '../widgets/search_bar_widget.dart';
import 'document_detail_screen.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _docService = DocumentService();

  List<Document> _documents = [];
  List<Document> _filtered  = [];
  String _searchQuery = '';
  String _activeCategory = 'All';
  bool _isGridView = false;
  bool _isLoading  = true;

  // Category filter tabs
  final List<String> _categories = ['All', ...DocCategory.all];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      List<Document> docs;
      if (_searchQuery.isNotEmpty) {
        docs = await _docService.searchDocuments(_searchQuery);
      } else if (_activeCategory != 'All') {
        docs = await _docService.getByCategory(_activeCategory);
      } else {
        docs = await _docService.getAllDocuments();
      }
      setState(() {
        _documents = docs;
        _filtered  = docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onSearch(String query) {
    setState(() => _searchQuery = query);
    _loadDocuments();
  }

  void _onCategoryChanged(String cat) {
    setState(() => _activeCategory = cat);
    _loadDocuments();
  }

  Future<void> _onDocumentTap(Document doc) async {
    await Navigator.push(context,
      MaterialPageRoute(builder: (_) => DocumentDetailScreen(document: doc)));
    _loadDocuments(); // Refresh in case of edits/deletes
  }

  Future<void> _onDelete(Document doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Document?'),
        content: Text('Delete "${doc.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DocNestTheme.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _docService.deleteDocument(doc);
      _loadDocuments();
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
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Documents',
                        style: TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w800,
                          color: DocNestTheme.primary, letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Toggle list/grid
                  IconButton(
                    icon: Icon(_isGridView ? Icons.view_list_rounded
                                           : Icons.grid_view_rounded),
                    color: DocNestTheme.textSecondary,
                    onPressed: () => setState(() => _isGridView = !_isGridView),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Search bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SearchBarWidget(
                onSearch: _onSearch,
                placeholder: 'Search documents or text inside...',
              ),
            ),

            const SizedBox(height: 12),

            // ── Category tabs ─────────────────────────────────────────────
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final isActive = cat == _activeCategory;
                  return GestureDetector(
                    onTap: () => _onCategoryChanged(cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive ? DocNestTheme.accent : DocNestTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive ? DocNestTheme.accent : DocNestTheme.border,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isActive ? Colors.white : DocNestTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // ── Document count ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '${_filtered.length} document${_filtered.length != 1 ? 's' : ''}',
                style: const TextStyle(
                  color: DocNestTheme.textSecondary, fontSize: 13),
              ),
            ),

            const SizedBox(height: 8),

            // ── Document list or grid ─────────────────────────────────────
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                  ? _buildEmptyState()
                  : _isGridView
                    ? _buildGrid()
                    : _buildList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded,
            size: 64, color: DocNestTheme.textHint),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No results found' : 'No documents yet',
            style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w600,
              color: DocNestTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
              ? 'Try a different search term'
              : 'Tap the Scan tab to add your first document',
            style: const TextStyle(
              color: DocNestTheme.textHint, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadDocuments,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        itemCount: _filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => DocumentCard(
          document: _filtered[i],
          isGrid: false,
          onTap: () => _onDocumentTap(_filtered[i]),
          onDelete: () => _onDelete(_filtered[i]),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return RefreshIndicator(
      onRefresh: _loadDocuments,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: _filtered.length,
        itemBuilder: (_, i) => DocumentCard(
          document: _filtered[i],
          isGrid: true,
          onTap: () => _onDocumentTap(_filtered[i]),
          onDelete: () => _onDelete(_filtered[i]),
        ),
      ),
    );
  }
}
