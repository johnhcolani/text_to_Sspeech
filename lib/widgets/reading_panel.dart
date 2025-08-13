import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tts_provider.dart';

class ReadingPanel extends StatefulWidget {
  const ReadingPanel({super.key});

  @override
  State<ReadingPanel> createState() => _ReadingPanelState();
}

class _ReadingPanelState extends State<ReadingPanel> {
  final ScrollController _scrollController = ScrollController();
  int _lastScrolledTo = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TTSProvider>(
      builder: (context, tts, _) {
        final text = tts.text;
        final lines = text.isEmpty ? <String>[] : text.split('\n');
        final isActive = tts.progressActive;
        final activeLine = isActive ? tts.currentLineIndex : -1;

        // Auto-scroll when active line changes
        if (isActive && lines.isNotEmpty && activeLine >= 0 && activeLine != _lastScrolledTo) {
          _lastScrolledTo = activeLine;
          // Scroll so the active line is comfortably visible
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              final itemHeight = 220.0 / 8; // Approximate height per line
              final targetOffset = (activeLine * itemHeight).clamp(0.0, _scrollController.position.maxScrollExtent);
              _scrollController.animateTo(
                targetOffset,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          });
        }

        if (lines.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: _box(context),
            child: Column(
              children: [
                Icon(
                  Icons.text_fields,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nothing to read yet.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Upload a file or type text to get started',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          height: 220, // fixed reading viewport
          decoration: _box(context),
          child: Column(
            children: [
              // Progress header
              if (isActive) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.play_arrow,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Reading in progress...',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        '${(tts.progressPercentage * 100).toInt()}%',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                LinearProgressIndicator(
                  value: tts.progressPercentage,
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                // Word progress indicator
                if (tts.wordHighlightingActive && tts.words.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.text_fields,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Word ${tts.currentWordIndex + 1} of ${tts.words.length}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Text(
                          tts.progressWord,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              
              // Text content
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
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
              ),
            ],
          ),
        );
      },
    );
  }

  // Enhanced word highlighting in the active line
  Widget _buildLine(TTSProvider tts, String line, int lineIndex, TextStyle style) {
    final start = tts.progressStart;
    final end = tts.progressEnd;

    // Find the character range for this line within the whole text
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
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            TextSpan(text: after, style: style),
          ],
        ),
      );
    }

    // Default: render plain line
    return Text(line, style: style);
  }

  BoxDecoration _box(BuildContext context) => BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.15)),
  );
}
