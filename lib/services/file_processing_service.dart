import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' hide TextLine;
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../utils/validators.dart';

class FileProcessingService {
  static final FileProcessingService _instance =
      FileProcessingService._internal();
  factory FileProcessingService() => _instance;
  FileProcessingService._internal();

  final ImagePicker _imagePicker = ImagePicker();

  /// Open app settings if permissions are denied
  Future<void> openAppSettings() async {
    try {
      await ph.openAppSettings();
    } catch (e) {
      debugPrint('Error opening app settings: $e');
    }
  }

  /// Check current permission status without requesting
  Future<Map<ph.Permission, ph.PermissionStatus>>
  checkPermissionStatus() async {
    try {
      Map<ph.Permission, ph.PermissionStatus> statuses = {};

      if (Platform.isAndroid) {
        // Android permissions
        for (ph.Permission permission in [
          ph.Permission.storage,
          ph.Permission.camera,
          ph.Permission.photos,
          ph.Permission.manageExternalStorage,
          ph.Permission.videos,
          ph.Permission.audio,
        ]) {
          statuses[permission] = await permission.status;
        }
      } else if (Platform.isIOS) {
        // iOS permissions
        for (ph.Permission permission in [
          ph.Permission.camera,
          ph.Permission.photos,
          ph.Permission.microphone,
        ]) {
          statuses[permission] = await permission.status;
        }
      }
      // macOS: no mobile-style permissions; system dialogs handle file/photo access

      return statuses;
    } catch (e) {
      debugPrint('Error checking permission status: $e');
      return {};
    }
  }

  /// Request necessary permissions
  Future<bool> requestPermissions() async {
    try {
      List<ph.Permission> permissions = [];

      if (Platform.isAndroid) {
        // Request all necessary permissions for Android
        permissions = [
          ph.Permission.camera,
          ph.Permission.photos,
          ph.Permission.storage,
          ph.Permission.manageExternalStorage,
        ];
      } else if (Platform.isIOS) {
        // iOS permissions - handled by the system when needed
        permissions = [
          ph.Permission.camera,
          ph.Permission.photos,
          ph.Permission.microphone,
        ];
      }
      // macOS: no permission request; sandbox + system dialogs handle access

      if (permissions.isEmpty) {
        return true; // iOS/macOS handle permissions via system
      }

      debugPrint('Requesting permissions: $permissions');

      // Check current permission status first
      Map<ph.Permission, ph.PermissionStatus> statuses = await permissions
          .request();

      // Log permission statuses for debugging
      debugPrint('Permission statuses: $statuses');

      // For Android, we're more lenient - if camera and photos work, that's enough
      bool hasEssentialPermissions = false;
      if (Platform.isAndroid) {
        hasEssentialPermissions =
            statuses[ph.Permission.camera]?.isGranted == true ||
            statuses[ph.Permission.photos]?.isGranted == true;
      } else {
        hasEssentialPermissions = statuses.values.every(
          (status) => status.isGranted,
        );
      }

      if (!hasEssentialPermissions) {
        // Log which permissions were denied
        statuses.forEach((permission, status) {
          if (!status.isGranted) {
            debugPrint('Permission denied: $permission - $status');
          }
        });
      }

      return hasEssentialPermissions;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return false;
    }
  }

  /// Pick and process text files (TXT, PDF)
  Future<String?> pickAndProcessTextFile() async {
    try {
      debugPrint('pickAndProcessTextFile: Starting...');

      // On iOS, let the system handle permissions when needed
      // On Android, check permissions first but don't fail completely if they're denied
      if (Platform.isAndroid) {
        debugPrint('pickAndProcessTextFile: Checking Android permissions...');
        bool hasPermissions = await requestPermissions();
        debugPrint(
          'pickAndProcessTextFile: Permissions granted: $hasPermissions',
        );

        // Even if permissions are denied, try to open the file picker
        // The system might still allow it or show permission dialog
        if (!hasPermissions) {
          debugPrint(
            'pickAndProcessTextFile: Permissions denied, but trying file picker anyway...',
          );
        }
      }

      debugPrint('pickAndProcessTextFile: Opening file picker...');
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'pdf'],
      );

      debugPrint(
        'pickAndProcessTextFile: File picker result: ${result?.files.length ?? 0} files',
      );

      if (result != null && result.files.isNotEmpty) {
        String filePath = result.files.first.path!;
        debugPrint('pickAndProcessTextFile: Selected file: $filePath');

        // Validate file before processing
        final fileSize = await File(filePath).length();
        final sizeValidationError = InputValidator.validateFileSize(fileSize);
        if (sizeValidationError != null) {
          debugPrint('File validation error: $sizeValidationError');
          return '❌ **File Size Error**\n\n$sizeValidationError';
        }

        String? extractedText = await _extractTextFromFile(File(filePath));
        debugPrint(
          'pickAndProcessTextFile: Extracted text length: ${extractedText?.length ?? 0}',
        );
        return extractedText;
      } else {
        debugPrint(
          'pickAndProcessTextFile: No file selected or picker cancelled',
        );
        return null;
      }
    } catch (e) {
      debugPrint('pickAndProcessTextFile: Error: $e');
      return '❌ **Error Processing File**\n\nAn error occurred while trying to process your file:\n\n$e\n\nPlease try again or contact support if the problem persists.';
    }
  }

  /// Pick and process image for OCR using Google ML Kit
  Future<String?> pickAndProcessImage({bool useCamera = false}) async {
    try {
      debugPrint('pickAndProcessImage: Starting... useCamera: $useCamera');

      // On iOS, let the system handle permissions when needed
      // On Android, check permissions first but don't fail completely if they're denied
      if (Platform.isAndroid) {
        debugPrint('pickAndProcessImage: Checking Android permissions...');
        bool hasPermissions = await requestPermissions();
        debugPrint('pickAndProcessImage: Permissions granted: $hasPermissions');

        // Even if permissions are denied, try to open the camera/photo picker
        // The system might still allow it or show permission dialog
        if (!hasPermissions) {
          debugPrint(
            'pickAndProcessImage: Permissions denied, but trying image picker anyway...',
          );
        }
      }

      debugPrint(
        'pickAndProcessImage: Opening ${useCamera ? 'camera' : 'photo library'}...',
      );
      XFile? image;

      if (useCamera) {
        image = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
        );
      } else {
        image = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
        );
      }

      debugPrint(
        'pickAndProcessImage: Image picker result: ${image?.path ?? 'null'}',
      );

      if (image != null) {
        debugPrint('pickAndProcessImage: Image selected: ${image.path}');

        // Extract text using OCR
        String? extractedText = await _extractTextFromImage(image);

        if (extractedText != null && extractedText.isNotEmpty) {
          debugPrint(
            'pickAndProcessImage: OCR successful. Text length: ${extractedText.length}',
          );
          return extractedText;
        } else {
          debugPrint('pickAndProcessImage: OCR failed or no text found');
          return '📸 **Image Selected Successfully!**\n\nFile: ${image.path}\n\n⚠️ **No Text Found**\n\nThe image was processed but no readable text was detected.\n\n**Possible reasons:**\n• Image doesn\'t contain text\n• Text is too blurry or small\n• Image quality is too low\n• Text is in an unsupported language\n\n**Try:**\n• Taking a clearer photo\n• Ensuring text is well-lit and readable\n• Using a higher resolution image';
        }
      } else {
        debugPrint(
          'pickAndProcessImage: No image selected or picker cancelled',
        );
        return null;
      }
    } catch (e) {
      debugPrint('pickAndProcessImage: Error: $e');
      return '❌ **Error Processing Image**\n\nAn error occurred while trying to ${useCamera ? 'take a photo' : 'access your photo library'}:\n\n$e\n\nPlease try again or contact support if the problem persists.';
    }
  }

  /// Extract text from various file types
  Future<String?> _extractTextFromFile(File file) async {
    try {
      String extension = file.path.split('.').last.toLowerCase();
      debugPrint(
        '_extractTextFromFile: Processing file with extension: $extension',
      );
      debugPrint('_extractTextFromFile: File path: ${file.path}');
      debugPrint('_extractTextFromFile: File exists: ${await file.exists()}');
      debugPrint(
        '_extractTextFromFile: File size: ${await file.length()} bytes',
      );

      String? extractedText;

      switch (extension) {
        case 'txt':
          debugPrint('_extractTextFromFile: Processing TXT file...');
          extractedText = await file.readAsString();
          break;

        case 'pdf':
          debugPrint('_extractTextFromFile: Processing PDF file...');
          extractedText = await _extractTextFromPDF(file);
          break;

        default:
          debugPrint('_extractTextFromFile: Unsupported file type: $extension');
          return null;
      }

      debugPrint(
        '_extractTextFromFile: Extraction completed. Text length: ${extractedText?.length ?? 0}',
      );
      if (extractedText != null && extractedText.isNotEmpty) {
        debugPrint(
          '_extractTextFromFile: First 100 chars: ${extractedText.substring(0, extractedText.length > 100 ? 100 : extractedText.length)}...',
        );
      }

      return extractedText;
    } catch (e) {
      debugPrint('Error extracting text from file: $e');
      return null;
    }
  }

  /// Extract text from PDF using Syncfusion
  Future<String?> _extractTextFromPDF(File file) async {
    try {
      debugPrint('_extractTextFromPDF: Starting PDF extraction...');
      PdfDocument document = PdfDocument(inputBytes: await file.readAsBytes());
      debugPrint(
        '_extractTextFromPDF: PDF document loaded. Pages: ${document.pages.count}',
      );

      String extractedText = '';

      for (int i = 0; i < document.pages.count; i++) {
        debugPrint('_extractTextFromPDF: Processing page ${i + 1}...');
        PdfTextExtractor extractor = PdfTextExtractor(document);
        String pageText = extractor.extractText(startPageIndex: i);
        debugPrint(
          '_extractTextFromPDF: Page ${i + 1} text length: ${pageText.length}',
        );
        extractedText += pageText;
        if (i < document.pages.count - 1) extractedText += '\n\n';
      }

      document.dispose();
      debugPrint(
        '_extractTextFromPDF: PDF extraction completed. Total text length: ${extractedText.length}',
      );
      return extractedText.trim();
    } catch (e) {
      debugPrint('Error extracting text from PDF: $e');
      return null;
    }
  }

  /// Extract text from image using Google ML Kit OCR
  Future<String?> _extractTextFromImage(XFile image) async {
    try {
      debugPrint('_extractTextFromImage: Starting OCR processing...');

      // Create input image
      final inputImage = InputImage.fromFilePath(image.path);

      // Create text recognizer
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );

      // Process the image
      debugPrint('_extractTextFromImage: Processing image with ML Kit...');
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );

      // Extract text from all blocks
      String extractedText = '';
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          for (TextElement element in line.elements) {
            extractedText += '${element.text} ';
          }
          extractedText += '\n';
        }
        extractedText += '\n';
      }

      // Clean up
      textRecognizer.close();

      // Trim and clean the extracted text
      extractedText = extractedText.trim().replaceAll(
        RegExp(r'\n\s*\n'),
        '\n\n',
      );

      debugPrint(
        '_extractTextFromImage: OCR completed. Text length: ${extractedText.length}',
      );
      if (extractedText.isNotEmpty) {
        debugPrint(
          '_extractTextFromImage: First 100 chars: ${extractedText.substring(0, extractedText.length > 100 ? 100 : extractedText.length)}...',
        );
      }

      return extractedText.isNotEmpty ? extractedText : null;
    } catch (e) {
      debugPrint('_extractTextFromImage: Error during OCR: $e');
      return null;
    }
  }

  /// Clean up resources
  void dispose() {
    // No cleanup needed for simplified version
  }
}
