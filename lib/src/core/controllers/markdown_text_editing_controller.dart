import 'package:flutter/material.dart';

/// A [TextEditingController] that applies inline styling to basic markdown
/// sequences so users get immediate visual feedback while typing.
class MarkdownTextEditingController extends TextEditingController {
  MarkdownTextEditingController({super.text});

  static final RegExp _boldPattern = RegExp(r'\*\*(.+?)\*\*', dotAll: false);

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    bool? withComposing,
  }) {
    final TextStyle baseStyle = style ?? DefaultTextStyle.of(context).style;
    final String text = value.text;

    if (text.isEmpty) {
      return TextSpan(style: baseStyle);
    }

    final Iterable<RegExpMatch> matches = _boldPattern.allMatches(text);
    if (matches.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }

    final Color markerColor =
        baseStyle.color?.withOpacity(0.35) ?? Colors.grey.withOpacity(0.5);
    final TextStyle markerStyle = baseStyle.copyWith(color: markerColor);
    final TextStyle boldStyle =
        baseStyle.merge(const TextStyle(fontWeight: FontWeight.w600));

    final List<InlineSpan> children = <InlineSpan>[];
    int currentIndex = 0;

    for (final RegExpMatch match in matches) {
      final int start = match.start;
      final int end = match.end;

      if (start > currentIndex) {
        children.add(TextSpan(
          text: text.substring(currentIndex, start),
          style: baseStyle,
        ));
      }

      // Leading marker (**)
      children.add(TextSpan(
        text: text.substring(start, start + 2),
        style: markerStyle,
      ));

      // Bold content
      final String boldText = match.group(1) ?? '';
      if (boldText.isNotEmpty) {
        children.add(TextSpan(text: boldText, style: boldStyle));
      }

      // Trailing marker (**)
      children.add(TextSpan(
        text: text.substring(end - 2, end),
        style: markerStyle,
      ));

      currentIndex = end;
    }

    if (currentIndex < text.length) {
      children.add(TextSpan(
        text: text.substring(currentIndex),
        style: baseStyle,
      ));
    }

    return TextSpan(style: baseStyle, children: children);
  }
}
