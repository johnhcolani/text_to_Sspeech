# Text to Speech App

A beautiful Flutter application that converts text to natural human speech with support for PDF and text file uploads.

## Features

### 🎯 Core Functionality
- **Text-to-Speech**: Convert any text to natural human voice
- **File Support**: Upload and process PDF and TXT files
- **Natural Voice**: Uses device's built-in TTS engines for natural-sounding speech
- **Multi-language**: Support for multiple languages (English, Spanish, French, German, Italian, Portuguese, Japanese, Korean, Chinese)

### 🎛️ Voice Customization
- **Speech Rate**: Adjust from slow (0.1x) to fast (1.0x)
- **Pitch Control**: Modify voice pitch from low (0.5x) to high (2.0x)
- **Volume Control**: Adjust volume from 0% to 100%
- **Voice Selection**: Choose from available system voices
- **Language Selection**: Switch between different languages

### 🎨 Beautiful UI
- **Modern Design**: Material Design 3 with beautiful gradients
- **Responsive Layout**: Works on all screen sizes
- **Dark/Light Theme**: Automatic theme switching
- **Intuitive Controls**: Easy-to-use playback controls

### 📁 File Handling
- **PDF Processing**: Extract text from PDF documents
- **Text Files**: Read and process TXT files
- **Drag & Drop**: Easy file upload interface
- **Text Extraction**: Automatic text extraction from files

## Getting Started

### Prerequisites
- Flutter SDK (3.9.0 or higher)
- Android Studio / VS Code
- Android/iOS device or emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd text_to_speech
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## How to Use

### Basic Text-to-Speech
1. Open the app
2. Type or paste text in the text input field
3. Click the **Play** button to start speaking
4. Use **Pause**, **Resume**, and **Stop** controls as needed

### Uploading Files
1. Click **"Choose PDF/TXT"** button
2. Select a PDF or text file from your device
3. The app will automatically extract text from the file
4. Use the playback controls to listen to the extracted text

### Customizing Voice
1. Tap the **Voice Settings** icon (🎤) in the header
2. Adjust speech rate, pitch, and volume using the sliders
3. Select your preferred language and voice
4. Changes are applied immediately

### Voice Settings Explained

- **Speech Rate**: Controls how fast the text is spoken
  - 0.1x = Very slow (good for learning)
  - 0.5x = Slow (default)
  - 1.0x = Normal speed

- **Pitch**: Controls the voice tone
  - 0.5x = Low pitch (deeper voice)
  - 1.0x = Normal pitch (default)
  - 2.0x = High pitch (higher voice)

- **Volume**: Controls the output volume
  - 0.0 = Muted
  - 0.5 = Half volume
  - 1.0 = Full volume

## Technical Details

### Dependencies
- `flutter_tts`: Core text-to-speech functionality
- `file_picker`: File selection and upload
- `syncfusion_flutter_pdf`: PDF text extraction
- `provider`: State management
- `permission_handler`: File access permissions

### Architecture
- **Provider Pattern**: State management using Provider
- **Widget-based UI**: Modular, reusable components
- **Platform Integration**: Native TTS engine integration
- **Error Handling**: Graceful error handling for file operations

### Supported Platforms
- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

## Natural Human Voice

This app provides natural human voice through:

1. **Device TTS Engines**: Uses the device's built-in text-to-speech engines
   - **Android**: Google TTS, Samsung TTS, or other system engines
   - **iOS**: Apple's Siri TTS engine
   - **Windows**: Microsoft Speech API
   - **macOS**: Apple's Speech Synthesis

2. **Voice Quality**: Modern TTS engines provide very natural-sounding speech with:
   - Natural intonation and rhythm
   - Proper pronunciation
   - Emotional expression
   - Multiple voice options

3. **Language Support**: Each platform supports multiple languages with native-sounding voices

## Troubleshooting

### Common Issues

**"No text to speak" error**
- Make sure you have entered text or uploaded a file
- Check if the file contains extractable text

**Voice not working**
- Ensure your device has TTS enabled
- Check device volume settings
- Try restarting the app

**File upload issues**
- Ensure you have file access permissions
- Check if the file format is supported (PDF or TXT)
- Try with a smaller file first

### Performance Tips
- Large PDF files may take longer to process
- Very long texts may cause slight delays
- Close other apps to free up memory

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

If you encounter any issues or have questions, please open an issue on the repository.

---

**Enjoy your natural text-to-speech experience! 🎵**
