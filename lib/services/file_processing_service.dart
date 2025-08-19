import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' hide TextLine;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

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
        // Android permissions
        permissions = [
          Permission.storage,
          Permission.camera,
          Permission.photos,
          Permission.manageExternalStorage,
          Permission.videos,
          Permission.audio,
        ];
      } else if (Platform.isIOS) {
        // iOS permissions - these are handled by the system when needed
        // We don't need to request them explicitly with permission_handler
        permissions = [
          Permission.camera,
          Permission.photos,
          Permission.microphone,
        ];
      }

      if (permissions.isEmpty) {
        return true; // iOS handles permissions automatically
      }

      // Check current permission status first
      Map<Permission, PermissionStatus> statuses = await permissions.request();

      // Log permission statuses for debugging
      print('Permission statuses: $statuses');
      
      bool allGranted = statuses.values.every((status) => status.isGranted);
      
      if (!allGranted) {
        // Log which permissions were denied
        statuses.forEach((permission, status) {
          if (!status.isGranted) {
            print('Permission denied: $permission - $status');
          }
        });
      }

      return allGranted;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  /// Pick and process text files (TXT, PDF, DOC)
  Future<String?> pickAndProcessTextFile() async {
    try {
      // On iOS, let the system handle permissions when needed
      // On Android, check permissions first
      if (Platform.isAndroid && !await requestPermissions()) {
        return '❌ **Permission Required**\n\nTo upload files, please grant the following permissions:\n\n1. **Storage Access** - To read files from your device\n2. **Photo Library** - To access saved documents\n\n**How to enable:**\n• Go to Settings > Privacy & Security > Files and Folders\n• Enable access for this app\n• Or go to Settings > Apps > Text to Speech > Permissions\n\n**Alternative:** You can still type text manually in the text field above.';
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.isNotEmpty) {
        String filePath = result.files.first.path!;
        return await _extractTextFromFile(File(filePath));
      }
      return null;
    } catch (e) {
      return '❌ **Error Processing File**\n\nAn error occurred while trying to process your file:\n\n$e\n\nPlease try again or contact support if the problem persists.';
    }
  }

  /// Pick and process image for OCR (simplified - just returns placeholder)
  Future<String?> pickAndProcessImage({bool useCamera = false}) async {
    try {
      // On iOS, let the system handle permissions when needed
      // On Android, check permissions first
      if (Platform.isAndroid && !await requestPermissions()) {
        return '❌ **Permission Required**\n\nTo ${useCamera ? 'take photos' : 'access photos'}, please grant the following permissions:\n\n1. **Camera** - To take photos (if using camera)\n2. **Photo Library** - To access saved images\n\n**How to enable:**\n• Go to Settings > Privacy & Security > Camera\n• Go to Settings > Privacy & Security > Photos\n• Enable access for this app\n• Or go to Settings > Apps > Text to Speech > Permissions\n\n**Note:** OCR functionality has been temporarily removed to fix build issues.\n\n**Alternative:** You can still:\n• Upload text files (TXT, PDF, DOC)\n• Type text manually\n• Use the anti-stuttering TTS features';
      }

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

      if (image != null) {
        // Since OCR is removed, return a placeholder message
        return '📸 **Image Selected Successfully!**\n\nFile: ${image.path}\n\n⚠️ **OCR Temporarily Unavailable**\n\nOCR functionality has been temporarily removed to fix build issues.\n\n✅ **What Still Works:**\n• Upload text files (TXT, PDF, DOC)\n• Type text manually\n• Anti-stuttering TTS features\n• MP3 file generation\n• Smooth offline playback\n\n🔄 **OCR Coming Soon:**\nWe\'re working on bringing back image text extraction with improved performance.';
      }
      return null;
    } catch (e) {
      return '❌ **Error Processing Image**\n\nAn error occurred while trying to ${useCamera ? 'take a photo' : 'access your photo library'}:\n\n$e\n\nPlease try again or contact support if the problem persists.';
    }
  }

  /// Extract text from various file types
  Future<String?> _extractTextFromFile(File file) async {
    try {
      String extension = file.path.split('.').last.toLowerCase();

      switch (extension) {
        case 'txt':
          return await file.readAsString();

        case 'pdf':
          return await _extractTextFromPDF(file);

        case 'doc':
        case 'docx':
          return await _extractTextFromWord(file);

        default:
          return null;
      }
    } catch (e) {
      print('Error extracting text from file: $e');
      return null;
    }
  }

  /// Extract text from PDF using Syncfusion
  Future<String?> _extractTextFromPDF(File file) async {
    try {
      PdfDocument document = PdfDocument(inputBytes: await file.readAsBytes());
      String extractedText = '';

      for (int i = 0; i < document.pages.count; i++) {
        PdfTextExtractor extractor = PdfTextExtractor(document);
        extractedText += extractor.extractText(startPageIndex: i);
        if (i < document.pages.count - 1) extractedText += '\n\n';
      }

      document.dispose();
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

  /// Clean up resources
  void dispose() {
    // No cleanup needed for simplified version
  }
}
