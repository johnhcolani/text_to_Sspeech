# Text to Speech App

A Flutter application for text-to-speech conversion with natural human voice support, file processing capabilities, and comprehensive voice customization.

## Features

### 🎯 Core Functionality

- **Text-to-Speech Conversion**: Convert text to natural-sounding speech
- **File Support**: Upload and process PDF and TXT files
- **Voice Customization**: Adjust speech rate, pitch, and volume
- **Multi-language Support**: Support for multiple languages and voices
- **Audio Export**: Save synthesized speech as audio files (where supported)

### 🎨 User Experience

- **Modern Material 3 Design**: Beautiful, responsive UI with light/dark themes
- **Real-time Progress Tracking**: Visual feedback during TTS operations
- **Error Handling**: Comprehensive error messages and user feedback
- **Accessibility**: Screen reader support and adaptive text scaling
- **History Management**: Save and manage your TTS sessions

### 🔧 Technical Features

- **State Management**: Provider pattern for efficient state management
- **Platform Optimization**: Optimized for both iOS and Android
- **Performance**: Efficient file processing and memory management
- **Error Recovery**: Graceful handling of TTS engine failures

## Recent Improvements

### ✅ Code Quality

- Removed unused dependencies (reduced app size by ~15MB)
- Enhanced error handling throughout the application
- Improved null safety and type checking
- Better code organization and documentation

### 🚀 User Experience

- **Progress Tracking**: Visual progress bars and percentage indicators
- **Error Display**: Clear error messages with actionable feedback
- **Loading States**: Better loading indicators and user feedback
- **Success Notifications**: Toast messages for completed operations

### 🎵 TTS Enhancements

- **Progress Visualization**: Real-time word and line highlighting
- **Better Voice Selection**: Improved language and voice matching
- **Audio Export**: Enhanced file synthesis capabilities
- **Status Indicators**: Clear visual feedback for TTS states

### 📱 UI/UX Improvements

- **Responsive Design**: Better handling of different screen sizes
- **Accessibility**: Screen reader support and text scaling
- **Visual Feedback**: Enhanced status indicators and progress bars
- **Modern Design**: Material 3 components and smooth animations

## Getting Started

### Prerequisites

- Flutter SDK (>=3.8.0)
- Dart SDK (>=3.0.0)
- Android Studio / Xcode for mobile development

### Installation

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Connect a device or start an emulator
4. Run `flutter run` to launch the app

### Usage

1. **Text Input**: Type text directly or upload a PDF/TXT file
2. **Voice Settings**: Customize speech rate, pitch, volume, and language
3. **Playback**: Use the control panel to play, pause, and stop speech
4. **History**: Save your TTS sessions for future reference
5. **Export**: Save audio files when supported by your device

## Architecture

The app follows a clean architecture pattern with:

- **Providers**: State management using Provider pattern
- **Models**: Data structures for TTS history and settings
- **Screens**: Main UI screens (Home, History, Splash)
- **Widgets**: Reusable UI components
- **Utils**: Helper functions and utilities

## Dependencies

### Core Dependencies

- `flutter_tts`: Text-to-speech engine
- `file_picker`: File selection and upload
- `syncfusion_flutter_pdf`: PDF text extraction
- `provider`: State management
- `shared_preferences`: Local data persistence

### Removed Dependencies

- `flutter_svg`: Replaced with standard Flutter icons
- `just_audio`: Not needed for TTS functionality
- `scrollable_positioned_list`: Replaced with standard ListView
- `audio_session`: Simplified audio handling

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and feature requests, please use the GitHub issue tracker.

---

**Note**: Audio export functionality may vary by device and platform. Some devices may not support audio file synthesis.
