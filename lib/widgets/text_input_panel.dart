import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemChannels;
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

  void _hideKeyboard() {
    _focusNode.unfocus();
    // Hide keyboard on iOS
    SystemChannels.textInput.invokeMethod('TextInput.hide');
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
        style: const TextStyle(
          color: Colors.white, // White text for visibility
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText:
              'Enter your text here...\n\nYou can type directly or upload a file above.',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.5), // White with opacity for hint
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.3), // White border with opacity
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: const Color(0xFF64B5F6), // Light blue focused border
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(
            0.05,
          ), // Very light white background
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

        if ((!_didInitialSync ||
                (!_focusNode.hasFocus && controllerText != providerText)) &&
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
            color: Colors.white.withOpacity(
              0.1,
            ), // Changed to white with low opacity
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2), // Added white border
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  0.2,
                ), // Increased shadow opacity
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: _hideKeyboard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Panel header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF64B5F6,
                    ).withOpacity(0.2), // Light blue with opacity
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_note,
                        color: const Color(0xFF64B5F6), // Light blue icon
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Text Input',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF64B5F6), // Light blue text
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
                              color: Colors.white.withOpacity(
                                0.8,
                              ), // White with opacity
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
                            color: const Color(0xFF64B5F6), // Light blue icon
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Upload File',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white, // White text
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // File picker removed - focusing on core TTS functionality
                      // Text input is the primary way to add content

                      // File info and error display
                      if (ttsProvider.hasError) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFEF5350,
                            ).withOpacity(0.2), // Red with opacity
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(
                                0xFFEF5350,
                              ).withOpacity(0.4), // Red border
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: const Color(0xFFEF5350), // Red icon
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  ttsProvider.lastError ?? 'An error occurred',
                                  style: TextStyle(
                                    color: Colors.white, // White text
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),

                // Divider
                Divider(
                  color: Colors.white.withOpacity(0.2), // White with opacity
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
                            color: const Color(0xFF64B5F6), // Light blue icon
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Or Type Text',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(
                                  0xFF64B5F6,
                                ), // Light blue text
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Use the non-listening child here
                      child!,

                      // Text management buttons
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _textController.text.isNotEmpty
                                ? () {
                                    _textController.clear();
                                    context.read<TTSProvider>().setText('');
                                  }
                                : null,
                            icon: const Icon(Icons.clear, size: 18),
                            label: const Text('Clear Text'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(
                                0xFFEF5350,
                              ), // Red text for clear
                              side: BorderSide(
                                color: const Color(
                                  0xFFEF5350,
                                ).withOpacity(0.5), // Red border
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: _hideKeyboard,
                            icon: const Icon(Icons.keyboard_hide, size: 18),
                            label: const Text('Hide Keyboard'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(
                                0xFF64B5F6,
                              ), // Light blue text
                              side: BorderSide(
                                color: const Color(
                                  0xFF64B5F6,
                                ).withOpacity(0.5), // Light blue border
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
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
      },
    );
  }
}
