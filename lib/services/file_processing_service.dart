import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' hide TextLine;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class FileProcessingService {
  static final FileProcessingService _instance =
      FileProcessingService._internal();
  factory FileProcessingService() => _instance;
  FileProcessingService._internal();

  final ImagePicker _imagePicker = ImagePicker();

  /// Open app settings if permissions are denied
  Future<void> openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      print('Error opening app settings: $e');
    }
  }

  /// Check current permission status without requesting
  Future<Map<Permission, PermissionStatus>> checkPermissionStatus() async {
    try {
      Map<Permission, PermissionStatus> statuses = {};

      if (Platform.isAndroid) {
        // Android permissions
        for (Permission permission in [
          Permission.storage,
          Permission.camera,
          Permission.photos,
          Permission.manageExternalStorage,
          Permission.videos,
          Permission.audio,
        ]) {
          statuses[permission] = await permission.status;
        }
      } else if (Platform.isIOS) {
        // iOS permissions
        for (Permission permission in [
          Permission.camera,
          Permission.photos,
          Permission.microphone,
        ]) {
          statuses[permission] = await permission.status;
        }
      }

      return statuses;
    } catch (e) {
      print('Error checking permission status: $e');
      return {};
    }
  }

  /// Request necessary permissions
  Future<bool> requestPermissions() async {
    try {
      List<Permission> permissions = [];

      if (Platform.isAndroid) {
        // Request all necessary permissions for Android
        // The system will handle which ones are actually needed
        permissions = [
          Permission.camera,
          Permission.photos,
          Permission.storage,
          Permission.manageExternalStorage,
        ];
      } else if (Platform.isIOS) {
        // iOS permissions - these are handled by the system when needed
        permissions = [
          Permission.camera,
          Permission.photos,
          Permission.microphone,
        ];
      }

      if (permissions.isEmpty) {
        return true; // iOS handles permissions automatically
      }

      print('Requesting permissions: $permissions');

      // Check current permission status first
      Map<Permission, PermissionStatus> statuses = await permissions.request();

      // Log permission statuses for debugging
      print('Permission statuses: $statuses');

      // For Android, we're more lenient - if camera and photos work, that's enough
      bool hasEssentialPermissions = false;
      if (Platform.isAndroid) {
        hasEssentialPermissions =
            statuses[Permission.camera]?.isGranted == true ||
            statuses[Permission.photos]?.isGranted == true;
      } else {
        hasEssentialPermissions = statuses.values.every(
          (status) => status.isGranted,
        );
      }

      if (!hasEssentialPermissions) {
        // Log which permissions were denied
        statuses.forEach((permission, status) {
          if (!status.isGranted) {
            print('Permission denied: $permission - $status');
          }
        });
      }

      return hasEssentialPermissions;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  /// Pick and process text files (TXT, PDF, DOC)
  Future<String?> pickAndProcessTextFile() async {
    try {
      print('pickAndProcessTextFile: Starting...');

      // On iOS, let the system handle permissions when needed
      // On Android, check permissions first but don't fail completely if they're denied
      if (Platform.isAndroid) {
        print('pickAndProcessTextFile: Checking Android permissions...');
        bool hasPermissions = await requestPermissions();
        print('pickAndProcessTextFile: Permissions granted: $hasPermissions');

        // Even if permissions are denied, try to open the file picker
        // The system might still allow it or show permission dialog
        if (!hasPermissions) {
          print(
            'pickAndProcessTextFile: Permissions denied, but trying file picker anyway...',
          );
        }
      }

      print('pickAndProcessTextFile: Opening file picker...');
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'pdf', 'doc', 'docx'],
      );

      print(
        'pickAndProcessTextFile: File picker result: ${result?.files.length ?? 0} files',
      );

      if (result != null && result.files.isNotEmpty) {
        String filePath = result.files.first.path!;
        print('pickAndProcessTextFile: Selected file: $filePath');
        String? extractedText = await _extractTextFromFile(File(filePath));
        print(
          'pickAndProcessTextFile: Extracted text length: ${extractedText?.length ?? 0}',
        );
        return extractedText;
      } else {
        print('pickAndProcessTextFile: No file selected or picker cancelled');
        return null;
      }
    } catch (e) {
      print('pickAndProcessTextFile: Error: $e');
      return '❌ **Error Processing File**\n\nAn error occurred while trying to process your file:\n\n$e\n\nPlease try again or contact support if the problem persists.';
    }
  }

  /// Pick and process image for OCR using Google ML Kit
  Future<String?> pickAndProcessImage({bool useCamera = false}) async {
    try {
      print('pickAndProcessImage: Starting... useCamera: $useCamera');

      // On iOS, let the system handle permissions when needed
      // On Android, check permissions first but don't fail completely if they're denied
      if (Platform.isAndroid) {
        print('pickAndProcessImage: Checking Android permissions...');
        bool hasPermissions = await requestPermissions();
        print('pickAndProcessImage: Permissions granted: $hasPermissions');

        // Even if permissions are denied, try to open the camera/photo picker
        // The system might still allow it or show permission dialog
        if (!hasPermissions) {
          print(
            'pickAndProcessImage: Permissions denied, but trying image picker anyway...',
          );
        }
      }

      print(
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

      print(
        'pickAndProcessImage: Image picker result: ${image?.path ?? 'null'}',
      );

      if (image != null) {
        print('pickAndProcessImage: Image selected: ${image.path}');

        // Extract text using OCR
        String? extractedText = await _extractTextFromImage(image);

        if (extractedText != null && extractedText.isNotEmpty) {
          print(
            'pickAndProcessImage: OCR successful. Text length: ${extractedText.length}',
          );
          return extractedText;
        } else {
          print('pickAndProcessImage: OCR failed or no text found');
          return '📸 **Image Selected Successfully!**\n\nFile: ${image.path}\n\n⚠️ **No Text Found**\n\nThe image was processed but no readable text was detected.\n\n**Possible reasons:**\n• Image doesn\'t contain text\n• Text is too blurry or small\n• Image quality is too low\n• Text is in an unsupported language\n\n**Try:**\n• Taking a clearer photo\n• Ensuring text is well-lit and readable\n• Using a higher resolution image';
        }
      } else {
        print('pickAndProcessImage: No image selected or picker cancelled');
        return null;
      }
    } catch (e) {
      print('pickAndProcessImage: Error: $e');
      return '❌ **Error Processing Image**\n\nAn error occurred while trying to ${useCamera ? 'take a photo' : 'access your photo library'}:\n\n$e\n\nPlease try again or contact support if the problem persists.';
    }
  }

  /// Extract text from various file types
  Future<String?> _extractTextFromFile(File file) async {
    try {
      String extension = file.path.split('.').last.toLowerCase();
      print('_extractTextFromFile: Processing file with extension: $extension');
      print('_extractTextFromFile: File path: ${file.path}');
      print('_extractTextFromFile: File exists: ${await file.exists()}');
      print('_extractTextFromFile: File size: ${await file.length()} bytes');

      String? extractedText;

      switch (extension) {
        case 'txt':
          print('_extractTextFromFile: Processing TXT file...');
          extractedText = await file.readAsString();
          break;

        case 'pdf':
          print('_extractTextFromFile: Processing PDF file...');
          extractedText = await _extractTextFromPDF(file);
          break;

        case 'doc':
        case 'docx':
          print('_extractTextFromFile: Processing Word document...');
          extractedText = await _extractTextFromWord(file);
          break;

        default:
          print('_extractTextFromFile: Unsupported file type: $extension');
          return null;
      }

      print(
        '_extractTextFromFile: Extraction completed. Text length: ${extractedText?.length ?? 0}',
      );
      if (extractedText != null && extractedText.isNotEmpty) {
        print(
          '_extractTextFromFile: First 100 chars: ${extractedText.substring(0, extractedText.length > 100 ? 100 : extractedText.length)}...',
        );
      }

      return extractedText;
    } catch (e) {
      print('Error extracting text from file: $e');
      return null;
    }
  }

  /// Extract text from PDF using Syncfusion
  Future<String?> _extractTextFromPDF(File file) async {
    try {
      print('_extractTextFromPDF: Starting PDF extraction...');
      PdfDocument document = PdfDocument(inputBytes: await file.readAsBytes());
      print(
        '_extractTextFromPDF: PDF document loaded. Pages: ${document.pages.count}',
      );

      String extractedText = '';

      for (int i = 0; i < document.pages.count; i++) {
        print('_extractTextFromPDF: Processing page ${i + 1}...');
        PdfTextExtractor extractor = PdfTextExtractor(document);
        String pageText = extractor.extractText(startPageIndex: i);
        print(
          '_extractTextFromPDF: Page ${i + 1} text length: ${pageText.length}',
        );
        extractedText += pageText;
        if (i < document.pages.count - 1) extractedText += '\n\n';
      }

      document.dispose();
      print(
        '_extractTextFromPDF: PDF extraction completed. Total text length: ${extractedText.length}',
      );
      return extractedText.trim();
    } catch (e) {
      print('Error extracting text from PDF: $e');
      return null;
    }
  }

  /// Extract text from Word documents (basic implementation)
  Future<String?> _extractTextFromWord(File file) async {
    try {
      // Basic text extraction for Word documents
      // This is a simplified implementation
      List<int> bytes = await file.readAsBytes();

      // Look for text content in the file
      String content = String.fromCharCodes(bytes);

      // Remove non-printable characters and extract readable text
      content = content.replaceAll(RegExp(r'[^\x20-\x7E\n\r\t]'), '');

      // Clean up extra whitespace
      content = content.replaceAll(RegExp(r'\s+'), ' ').trim();

      return content.isNotEmpty
          ? content
          : 'Text extraction from Word document not supported in this version.';
    } catch (e) {
      print('Error extracting text from Word document: $e');
      return 'Error extracting text from Word document: $e';
    }
  }

  /// Extract text from image using Google ML Kit OCR
  Future<String?> _extractTextFromImage(XFile image) async {
    try {
      print('_extractTextFromImage: Starting OCR processing...');

      // Create input image
      final inputImage = InputImage.fromFilePath(image.path);

      // Create text recognizer
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );

      // Process the image
      print('_extractTextFromImage: Processing image with ML Kit...');
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );

      // Extract text from all blocks
      String extractedText = '';
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          for (TextElement element in line.elements) {
            extractedText += element.text + ' ';
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

      print(
        '_extractTextFromImage: OCR completed. Text length: ${extractedText.length}',
      );
      if (extractedText.isNotEmpty) {
        print(
          '_extractTextFromImage: First 100 chars: ${extractedText.substring(0, extractedText.length > 100 ? 100 : extractedText.length)}...',
        );
      }

      return extractedText.isNotEmpty ? extractedText : null;
    } catch (e) {
      print('_extractTextFromImage: Error during OCR: $e');
      return null;
    }
  }

  /// Clean up resources
  void dispose() {
    // No cleanup needed for simplified version
  }
}
