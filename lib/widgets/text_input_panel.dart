import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tts_provider.dart';

class TextInputPanel extends StatefulWidget {
  const TextInputPanel({super.key});

  @override
  State<TextInputPanel> createState() => _TextInputPanelState();
}

class _TextInputPanelState extends State<TextInputPanel> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  bool _didInitialSync = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = FocusNode();

    // Seed the controller once from provider on first frame (no rebuild thrash)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final text = context.read<TTSProvider>().text;
      _textController.text = text;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
      _didInitialSync = true;
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build the TextField once and pass it as Consumer.child so it won't rebuild
    final textField = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 100, maxHeight: 150),
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        onChanged: (v) => context.read<TTSProvider>().setText(v),
        decoration: InputDecoration(
          hintText:
          'Enter your text here...\n\nYou can type directly or upload a file above.',
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          filled: true,
          fillColor:
          Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );

    return Consumer<TTSProvider>(
      child: textField,
      builder: (context, ttsProvider, child) {
        // One-way sync: only push provider -> controller when
        // 1) first mount, or
        // 2) the TextField is NOT focused (user not typing), and
        // 3) texts differ (likely external change: file loaded / cleared)
        final providerText = ttsProvider.text;
        final controllerText = _textController.text;

        if ((!_didInitialSync || (!_focusNode.hasFocus && controllerText != providerText)) &&
            // also avoid overwriting during IME composition
            !_textController.value.composing.isValid) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _textController.text = providerText;
            _textController.selection = TextSelection.fromPosition(
              TextPosition(offset: _textController.text.length),
            );
            _didInitialSync = true;
          });
        }

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Panel header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_note,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Text Input',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    // live character counter tied to controller (no provider rebuild)
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _textController,
                      builder: (_, value, __) {
                        final count = value.text.length;
                        return Text(
                          '$count chars',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer
                                .withOpacity(0.7),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // File upload section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.upload_file,
                          color: Theme.of(context).colorScheme.secondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Upload File',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                        ttsProvider.isLoading ? null : ttsProvider.pickFile,
                        icon: ttsProvider.isLoading
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Icon(Icons.upload_file),
                        label: Text(
                          ttsProvider.isLoading
                              ? 'Processing...'
                              : 'Choose PDF/TXT',
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          Theme.of(context).colorScheme.secondary,
                          foregroundColor:
                          Theme.of(context).colorScheme.onSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    if (ttsProvider.fileName.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.file_present,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                ttsProvider.fileName,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              onPressed: ttsProvider.clearText,
                              icon: Icon(
                                Icons.close,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer,
                                size: 18,
                              ),
                              tooltip: 'Clear',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Divider
              Divider(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                height: 1,
                indent: 16,
                endIndent: 16,
              ),

              // Text input section (TextField is the Consumer.child, so no rebuilds)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.text_fields,
                          color: Theme.of(context).colorScheme.tertiary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Or Type Text',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Use the non-listening child here
                    child!,
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
