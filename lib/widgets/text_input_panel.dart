import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tts_provider.dart';
import '../services/file_processing_service.dart';

class TextInputPanel extends StatefulWidget {
  const TextInputPanel({super.key});

  @override
  State<TextInputPanel> createState() => _TextInputPanelState();
}

class _TextInputPanelState extends State<TextInputPanel> {
  final TextEditingController _textController = TextEditingController();
  final FileProcessingService _fileService = FileProcessingService();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);

    // Add welcome text
    _textController.text =
        "Welcome to Text to Speech!\n\nThis app converts text to natural-sounding speech with advanced features:\n\n• Type or paste text directly\n• Upload files (TXT, PDF, DOC)\n• Select photos from your library\n• Take photos with your camera\n• Anti-stuttering MP3 playback\n• Multiple languages and voices\n\nStart by typing some text or using the upload buttons below.";

    // Notify TTS provider about initial text
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TTSProvider>().setText(_textController.text);
      }
    });
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    context.read<TTSProvider>().setText(_textController.text);
  }

  Future<void> _processFile() async {
    setState(() => _isProcessing = true);

    try {
      String? extractedText = await _fileService.pickAndProcessTextFile();
      if (extractedText != null) {
        _textController.text = extractedText;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File processed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _processImage({bool useCamera = false}) async {
    setState(() => _isProcessing = true);

    try {
      String? extractedText = await _fileService.pickAndProcessImage(
        useCamera: useCamera,
      );
      if (extractedText != null) {
        _textController.text = extractedText;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Text extracted from ${useCamera ? 'camera' : 'image'} successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error processing ${useCamera ? 'camera' : 'image'}: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TTSProvider>(
      builder: (context, ttsProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Text Input',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // File Upload Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.upload_file,
                          color: Colors.blue[300],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'File Upload & Image Processing',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isProcessing ? null : _processFile,
                            icon: _isProcessing
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.file_upload, size: 18),
                            label: Text(
                              _isProcessing ? 'Processing...' : 'File',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue[300],
                              side: BorderSide(color: Colors.blue[300]!),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isProcessing
                                ? null
                                : () => _processImage(useCamera: false),
                            icon: _isProcessing
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.photo_library, size: 18),
                            label: Text(
                              _isProcessing ? 'Processing...' : 'Photo',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green[300],
                              side: BorderSide(color: Colors.green[300]!),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isProcessing
                                ? null
                                : () => _processImage(useCamera: true),
                            icon: _isProcessing
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.camera_alt, size: 18),
                            label: Text(
                              _isProcessing ? 'Processing...' : 'Cam',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange[300],
                              side: BorderSide(color: Colors.orange[300]!),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Supported: TXT, PDF, Images (OCR), DOC files',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Text Input Field
              TextField(
                controller: _textController,
                maxLines: 8,
                style: TextStyle(
                  color: Colors.white.withAlpha(128),
                  fontSize: 16,
                ),
                onTap: () {
                  // Clear welcome text when user taps to type
                  if (_textController.text.contains(
                    "Welcome to Text to Speech!",
                  )) {
                    _textController.clear();
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Enter text or upload a file to extract text...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.blue.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                ),
              ),

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
                      foregroundColor: Colors.red[300],
                      side: BorderSide(color: Colors.red[300]!),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                    },
                    icon: const Icon(Icons.keyboard_hide, size: 18),
                    label: const Text('Hide Keyboard'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue[300],
                      side: BorderSide(color: Colors.blue[300]!),
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
        );
      },
    );
  }
}
