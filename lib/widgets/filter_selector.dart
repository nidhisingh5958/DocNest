// lib/widgets/filter_selector.dart
// Horizontal filter picker showing live preview thumbnails

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../utils/theme.dart';

class FilterSelector extends StatefulWidget {
  final ImageFilter selected;
  final ValueChanged<ImageFilter> onChanged;
  final String imagePath; // Use first page for preview

  const FilterSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.imagePath,
  });

  @override
  State<FilterSelector> createState() => _FilterSelectorState();
}

class _FilterSelectorState extends State<FilterSelector> {
  final _storage = StorageService();
  final Map<ImageFilter, Uint8List?> _previews = {};
  bool _loading = true;

  final List<ImageFilter> _filters = ImageFilter.values;

  @override
  void initState() {
    super.initState();
    _generatePreviews();
  }

  Future<void> _generatePreviews() async {
    for (final filter in _filters) {
      try {
        final bytes = await _storage.applyFilter(widget.imagePath, filter);
        if (mounted) {
          setState(() => _previews[filter] = bytes);
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Filter',
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: DocNestTheme.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final filter = _filters[i];
              final isSelected = filter == widget.selected;
              final preview = _previews[filter];

              return GestureDetector(
                onTap: () => widget.onChanged(filter),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 58, height: 68,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? DocNestTheme.accent
                              : DocNestTheme.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: _loading || preview == null
                          ? Container(
                              color: DocNestTheme.background,
                              child: const Center(
                                child: SizedBox(
                                  width: 14, height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 1.5),
                                ),
                              ),
                            )
                          : Image.memory(preview, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      filter.label,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected
                            ? DocNestTheme.accent
                            : DocNestTheme.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
