import 'package:flutter/material.dart';

/// A widget that highlights all occurrences of [query] in [text]
class HighlightedText extends StatelessWidget {
  final String text;
  final String? query;
  final TextStyle? style;
  final TextStyle? highlightStyle;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool caseSensitive;

  const HighlightedText({
    super.key,
    required this.text,
    this.query,
    this.style,
    this.highlightStyle,
    this.overflow,
    this.maxLines,
    this.caseSensitive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultTextStyle = style ?? theme.textTheme.bodyMedium ?? const TextStyle();
    final highlightTextStyle = highlightStyle ?? defaultTextStyle.copyWith(
      backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.bold,
    );

    if (query == null || query!.isEmpty || text.isEmpty) {
      return Text(
        text,
        style: defaultTextStyle,
        overflow: overflow,
        maxLines: maxLines,
      );
    }

    final String searchText = caseSensitive ? query! : query!.toLowerCase();
    final String textToSearch = caseSensitive ? text : text.toLowerCase();
    
    final List<TextSpan> spans = [];
    int start = 0;
    int indexOfSearch;
    
    do {
      indexOfSearch = textToSearch.indexOf(searchText, start);
      
      // Add non-matching text
      if (indexOfSearch > start) {
        spans.add(TextSpan(
          text: text.substring(start, indexOfSearch),
          style: defaultTextStyle,
        ));
      }
      
      // Add matching text
      if (indexOfSearch >= 0) {
        spans.add(TextSpan(
          text: text.substring(indexOfSearch, indexOfSearch + searchText.length),
          style: highlightTextStyle,
        ));
        start = indexOfSearch + searchText.length;
      }
    } while (indexOfSearch >= 0 && start < text.length);
    
    // Add remaining text
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: defaultTextStyle,
      ));
    }
    
    return RichText(
      text: TextSpan(children: spans),
      overflow: overflow ?? TextOverflow.ellipsis,
      maxLines: maxLines,
    );
  }
}
