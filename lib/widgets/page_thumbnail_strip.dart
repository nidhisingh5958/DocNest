// lib/widgets/page_thumbnail_strip.dart
// Horizontal reorderable strip of scanned page thumbnails

import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/theme.dart';

class PageThumbnailStrip extends StatelessWidget {
  final List<String> pages;
  final void Function(int index) onRemove;
  final void Function(int oldIndex, int newIndex) onReorder;

  const PageThumbnailStrip({
    super.key,
    required this.pages,
    required this.onRemove,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: pages.length,
        onReorder: onReorder,
        buildDefaultDragHandles: false,
        itemBuilder: (_, i) {
          return ReorderableDragStartListener(
            key: ValueKey(pages[i]),
            index: i,
            child: _PageThumb(
              imagePath: pages[i],
              pageNumber: i + 1,
              onRemove: () => onRemove(i),
            ),
          );
        },
      ),
    );
  }
}

class _PageThumb extends StatelessWidget {
  final String imagePath;
  final int pageNumber;
  final VoidCallback onRemove;

  const _PageThumb({
    required this.imagePath,
    required this.pageNumber,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      margin: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(imagePath),
              width: 72,
              height: 104,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 72, height: 104,
                color: DocNestTheme.accentSoft,
                child: const Icon(Icons.image_outlined,
                    color: DocNestTheme.accent),
              ),
            ),
          ),

          // Page number badge
          Positioned(
            bottom: 20, left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'p$pageNumber',
                style: const TextStyle(
                    color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          // Remove button
          Positioned(
            top: 4, right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20, height: 20,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
