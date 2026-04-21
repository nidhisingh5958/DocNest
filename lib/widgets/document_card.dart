// lib/widgets/document_card.dart
// Reusable card component for both list and grid views

import 'dart:io';
import 'package:flutter/material.dart';
import '../models/document.dart';
import '../utils/theme.dart';
import 'tag_chip.dart';

class DocumentCard extends StatelessWidget {
  final Document document;
  final bool isGrid;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool isSelectable;
  final bool isSelected;

  const DocumentCard({
    super.key,
    required this.document,
    required this.isGrid,
    this.onTap,
    this.onDelete,
    this.isSelectable = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return isGrid ? _buildGridCard() : _buildListCard();
  }

  // ── Grid card (portrait thumbnail style) ──────────────────────────────────
  Widget _buildGridCard() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: DocNestTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? DocNestTheme.accent : DocNestTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: _thumbnail(),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: DocNestTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                          color: DocNestTheme.tagColors[document.category] ??
                              DocNestTheme.textHint,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        document.category,
                        style: const TextStyle(
                          fontSize: 10, color: DocNestTheme.textSecondary),
                      ),
                      const Spacer(),
                      Text(
                        '${document.pageCount}p',
                        style: const TextStyle(
                          fontSize: 10, color: DocNestTheme.textHint),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── List card (horizontal layout) ─────────────────────────────────────────
  Widget _buildListCard() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DocNestTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? DocNestTheme.accent : DocNestTheme.border),
        ),
        child: Row(
          children: [
            // Selection indicator or thumbnail
            if (isSelectable)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24, height: 24,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? DocNestTheme.accent : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? DocNestTheme.accent : DocNestTheme.border,
                    width: 2,
                  ),
                ),
                child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
              )
            else
              // Page thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 52, height: 68,
                  child: _thumbnail(),
                ),
              ),

            const SizedBox(width: 14),

            // Title, category, tags
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600,
                      color: DocNestTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: DocNestTheme.tagColors[document.category] ??
                              DocNestTheme.textHint,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        document.category,
                        style: const TextStyle(
                          fontSize: 12, color: DocNestTheme.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '· ${document.pageCount} page${document.pageCount != 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 12, color: DocNestTheme.textHint),
                      ),
                    ],
                  ),
                  if (document.tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4, runSpacing: 4,
                      children: document.tags
                          .take(3)
                          .map((t) => TagChip(tag: t, small: true))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),

            // Date + delete
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _shortDate(document.createdAt),
                  style: const TextStyle(
                    fontSize: 11, color: DocNestTheme.textHint),
                ),
                if (onDelete != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onDelete,
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: DocNestTheme.textHint,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Thumbnail: use first page image or PDF placeholder
  Widget _thumbnail() {
    if (document.imagePaths.isNotEmpty) {
      final file = File(document.imagePaths.first);
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _pdfPlaceholder(),
      );
    }
    return _pdfPlaceholder();
  }

  Widget _pdfPlaceholder() {
    return Container(
      color: DocNestTheme.accentSoft,
      child: Center(
        child: Icon(
          Icons.picture_as_pdf_rounded,
          color: DocNestTheme.accent.withOpacity(0.6),
          size: isGrid ? 40 : 24,
        ),
      ),
    );
  }

  String _shortDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
