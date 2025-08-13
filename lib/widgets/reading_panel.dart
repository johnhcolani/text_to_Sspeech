import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../providers/tts_provider.dart';

class ReadingPanel extends StatefulWidget {
  const ReadingPanel({super.key});

  @override
  State<ReadingPanel> createState() => _ReadingPanelState();
}

class _ReadingPanelState extends State<ReadingPanel> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositions = ItemPositionsListener.create();
  int _lastScrolledTo = -1;

  @override
  Widget build(BuildContext context) {
    return Consumer<TTSProvider>(
      builder: (context, tts, _) {
        final text = tts.text;
        final lines = text.isEmpty ? <String>[] : text.split('\n');
        final isActive = tts.progressActive;
        final activeLine = isActive ? tts.currentLineIndex : -1;

        // Auto-scroll when active line changes (debounce a bit)
        if (isActive && lines.isNotEmpty && activeLine >= 0 && activeLine != _lastScrolledTo) {
          _lastScrolledTo = activeLine;
          // Scroll so the active line is comfortably visible
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_itemScrollController.isAttached) {
              _itemScrollController.scrollTo(
                index: activeLine.clamp(0, lines.length - 1),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: 0.2, // keep the active line slightly below top
              );
            }
          });
        }

        if (lines.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: _box(context),
            child: Text(
              'Nothing to read yet.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
          );
        }

        return Container(
          height: 220, // fixed reading viewport; adjust as you like
          decoration: _box(context),
          child: ScrollablePositionedList.builder(
            itemScrollController: _itemScrollController,
            itemPositionsListener: _itemPositions,
            itemCount: lines.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, i) {
              final isCurrent = i == activeLine;
              final style = Theme.of(context).textTheme.bodyMedium!;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
                      : Colors.transparent,
                  border: isCurrent
                      ? Border(
                    left: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 3,
                    ),
                  )
                      : null,
                ),
                child: _buildLine(tts, lines[i], i, style),
              );
            },
          ),
        );
      },
    );
  }

  // Optional: highlight the current WORD in the active line
  Widget _buildLine(TTSProvider tts, String line, int lineIndex, TextStyle style) {
    final start = tts.progressStart;
    final end = tts.progressEnd;

    // Find the character range for this line within the whole text.
    // We compute the absolute offset where this line starts.
    final text = tts.text;
    int lineStart = 0;
    int seenNewlines = 0;
    for (int i = 0; i < text.length && seenNewlines < lineIndex; i++) {
      if (text.codeUnitAt(i) == 10) seenNewlines++; // '\n'
      lineStart = i + 1;
    }
    final lineEnd = (lineStart + line.length).clamp(0, text.length);

    // If TTS cursor is inside this line, split into [before][word][after] spans
    final hasCursor = tts.progressActive && start >= lineStart && start <= lineEnd;
    if (hasCursor && end >= start && end <= lineEnd && start < end) {
      final before = line.substring(0, (start - lineStart).clamp(0, line.length));
      final word = line.substring((start - lineStart).clamp(0, line.length), (end - lineStart).clamp(0, line.length));
      final after = line.substring((end - lineStart).clamp(0, line.length));
      return RichText(
        text: TextSpan(
          children: [
            TextSpan(text: before, style: style),
            TextSpan(
              text: word,
              style: style.copyWith(
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(text: after, style: style),
          ],
        ),
      );
    }

    // Default: render plain line (or with line highlight via container)
    return Text(line, style: style);
  }

  BoxDecoration _box(BuildContext context) => BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.15)),
  );
}
