// lib/widgets/search_bar_widget.dart
// Animated search bar with debounce

import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/theme.dart';

class SearchBarWidget extends StatefulWidget {
  final ValueChanged<String> onSearch;
  final String placeholder;

  const SearchBarWidget({
    super.key,
    required this.onSearch,
    this.placeholder = 'Search...',
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final _controller = TextEditingController();
  Timer? _debounce;

  void _onChanged(String value) {
    // Debounce: wait 400ms after user stops typing before searching
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      widget.onSearch(value.trim());
    });
  }

  void _clear() {
    _controller.clear();
    widget.onSearch('');
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      decoration: InputDecoration(
        hintText: widget.placeholder,
        prefixIcon: const Icon(Icons.search_rounded,
            size: 20, color: DocNestTheme.textHint),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded,
                    size: 18, color: DocNestTheme.textHint),
                onPressed: _clear,
              )
            : null,
      ),
    );
  }
}
