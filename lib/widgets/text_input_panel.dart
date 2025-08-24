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
  bool _ocrEnabled = true; // OCR toggle state

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
      print('Starting file processing...');
      String? extractedText = await _fileService.pickAndProcessTextFile();

      print(
        'File processing result: ${extractedText?.substring(0, extractedText.length > 100 ? 100 : extractedText.length)}...',
      );

      if (extractedText != null) {
        if (extractedText.startsWith('❌')) {
          // This is an error message, show it as error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                extractedText.split('\n')[0],
              ), // Show first line of error
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        } else if (extractedText.startsWith('📸')) {
          // This is an info message, show it as info
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                extractedText.split('\n')[0],
              ), // Show first line of info
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          // This is actual extracted text
          print(
            'Setting extracted text to TextField: ${extractedText.length} characters',
          );
          _textController.text = extractedText;

          // Also notify the TTS provider about the new text
          context.read<TTSProvider>().setText(extractedText);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'File processed successfully! Text extracted: ${extractedText.length} characters',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // User cancelled file selection
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No file selected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error in _processFile: $e');
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
      print(
        'Starting image processing... useCamera: $useCamera, OCR enabled: $_ocrEnabled',
      );

      if (!_ocrEnabled) {
        // OCR is disabled, show info message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'OCR is disabled. Enable OCR to extract text from images.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      String? extractedText = await _fileService.pickAndProcessImage(
        useCamera: useCamera,
      );

      if (extractedText != null) {
        if (extractedText.startsWith('❌')) {
          // This is an error message, show it as error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                extractedText.split('\n')[0],
              ), // Show first line of error
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        } else if (extractedText.startsWith('📸')) {
          // This is an info message, show it as info
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                extractedText.split('\n')[0],
              ), // Show first line of info
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          // This is actual extracted text
          print(
            'Setting extracted text to TextField: ${extractedText.length} characters',
          );
          _textController.text = extractedText;

          // Also notify the TTS provider about the new text
          context.read<TTSProvider>().setText(extractedText);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Text extracted from ${useCamera ? 'camera' : 'image'} successfully! ${extractedText.length} characters',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // User cancelled image selection
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No image selected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error in _processImage: $e');
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
          padding: const EdgeInsets.all(12), // Reduced padding
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
              const SizedBox(height: 12), // Reduced spacing
              // File Upload Section
              Container(
                padding: const EdgeInsets.all(12), // Reduced padding
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
                        Expanded(
                          // Added Expanded to prevent text overflow
                          child: Text(
                            'File Upload & Image Processing',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis, // Handle long text
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12), // Reduced spacing
                    // Make buttons wrap on small screens
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        SizedBox(
                          width: 120, // Fixed width for consistency
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
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue[300],
                              side: BorderSide(color: Colors.blue[300]!),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12, // Reduced padding
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 120, // Fixed width for consistency
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
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green[300],
                              side: BorderSide(color: Colors.green[300]!),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12, // Reduced padding
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 120, // Fixed width for consistency
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
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange[300],
                              side: BorderSide(color: Colors.orange[300]!),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12, // Reduced padding
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
                    const SizedBox(height: 8),
                    // OCR Toggle
                    Row(
                      children: [
                        Icon(
                          Icons.text_fields,
                          color: Colors.orange[300],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'OCR Enabled:',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: _ocrEnabled,
                          onChanged: (value) {
                            setState(() {
                              _ocrEnabled = value;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value
                                      ? 'OCR enabled - Images will extract text'
                                      : 'OCR disabled - Images will show info only',
                                ),
                                backgroundColor: value
                                    ? Colors.green
                                    : Colors.orange,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          activeColor: Colors.green[300],
                          inactiveThumbColor: Colors.orange[300],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12), // Reduced spacing
              // Text Input Field
              TextField(
                controller: _textController,
                maxLines: null, // Allow unlimited lines to prevent overflow
                minLines: 4, // Minimum 4 lines
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
              // Make buttons wrap on small screens
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  // Debug button to test text setting
                  OutlinedButton.icon(
                    onPressed: () {
                      _textController.text =
                          "Debug: Test text setting works! ${DateTime.now()}";
                      context.read<TTSProvider>().setText(_textController.text);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Debug: Test text set'),
                          backgroundColor: Colors.purple,
                        ),
                      );
                    },
                    icon: const Icon(Icons.bug_report, size: 18),
                    label: const Text('Debug Test'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.purple[300],
                      side: BorderSide(color: Colors.purple[300]!),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
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
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
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
                        horizontal: 12,
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
