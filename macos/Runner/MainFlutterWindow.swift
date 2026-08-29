import Cocoa
import FlutterMacOS
import AVFoundation

class MainFlutterWindow: NSWindow {
  private let exportSynthesizer = AVSpeechSynthesizer()
  private var exportAudioFile: AVAudioFile?
  private var exportInProgress = false

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    let audioExportChannel = FlutterMethodChannel(
      name: "text_to_speech/macos_audio_export",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )

    audioExportChannel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(
          FlutterError(
            code: "WINDOW_UNAVAILABLE",
            message: "The macOS window is no longer available.",
            details: nil
          )
        )
        return
      }

      switch call.method {
      case "synthesizeToWav":
        self.synthesizeToWav(arguments: call.arguments, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  private func synthesizeToWav(
    arguments: Any?,
    result: @escaping FlutterResult
  ) {
    guard #available(macOS 10.15, *) else {
      result(
        FlutterError(
          code: "UNSUPPORTED_MACOS",
          message: "Audio export requires macOS 10.15 or newer.",
          details: nil
        )
      )
      return
    }

    guard !exportInProgress else {
      result(
        FlutterError(
          code: "EXPORT_BUSY",
          message: "Another audio export is already being prepared.",
          details: nil
        )
      )
      return
    }

    guard
      let args = arguments as? [String: Any],
      let text = args["text"] as? String,
      !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
      result(
        FlutterError(
          code: "INVALID_ARGUMENTS",
          message: "Text is required for audio export.",
          details: nil
        )
      )
      return
    }

    let voiceName = args["voiceName"] as? String ?? ""
    let language = args["language"] as? String ?? ""
    let requestedRate = Float(
      args["rate"] as? Double ?? Double(AVSpeechUtteranceDefaultSpeechRate)
    )
    let requestedPitch = Float(args["pitch"] as? Double ?? 1.0)
    let requestedVolume = Float(args["volume"] as? Double ?? 1.0)

    let fileManager = FileManager.default
    let outputURL: URL

    do {
      let applicationSupport = try fileManager.url(
        for: .applicationSupportDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true
      )
      let audioDirectory = applicationSupport
        .appendingPathComponent("TextToSpeech", isDirectory: true)
        .appendingPathComponent("TTS_audio", isDirectory: true)

      try fileManager.createDirectory(
        at: audioDirectory,
        withIntermediateDirectories: true,
        attributes: nil
      )

      outputURL = audioDirectory.appendingPathComponent(
        "tts_export_\(UUID().uuidString).wav"
      )
    } catch {
      result(
        FlutterError(
          code: "OUTPUT_DIRECTORY_FAILED",
          message: "Could not prepare the audio export folder.",
          details: error.localizedDescription
        )
      )
      return
    }

    let utterance = AVSpeechUtterance(string: text)
    let voices = AVSpeechSynthesisVoice.speechVoices()

    if !voiceName.isEmpty {
      utterance.voice = voices.first(where: { voice in
        voice.name == voiceName &&
          (language.isEmpty ||
            voice.language.caseInsensitiveCompare(language) == .orderedSame)
      }) ?? voices.first(where: { $0.name == voiceName })
    }

    if utterance.voice == nil && !language.isEmpty {
      utterance.voice = AVSpeechSynthesisVoice(language: language)
    }

    utterance.rate = min(
      max(requestedRate, AVSpeechUtteranceMinimumSpeechRate),
      AVSpeechUtteranceMaximumSpeechRate
    )
    utterance.pitchMultiplier = min(max(requestedPitch, 0.5), 2.0)
    utterance.volume = min(max(requestedVolume, 0.0), 1.0)

    exportAudioFile = nil
    exportInProgress = true
    var completed = false

    func finish(_ value: Any?) {
      if completed { return }
      completed = true
      exportAudioFile = nil
      exportInProgress = false

      DispatchQueue.main.async {
        result(value)
      }
    }

    exportSynthesizer.write(utterance) { buffer in
      guard !completed else { return }

      guard let pcmBuffer = buffer as? AVAudioPCMBuffer else {
        finish(
          FlutterError(
            code: "INVALID_AUDIO_BUFFER",
            message: "macOS returned an unsupported audio buffer.",
            details: nil
          )
        )
        return
      }

      if pcmBuffer.frameLength == 0 {
        if fileManager.fileExists(atPath: outputURL.path) {
          finish(outputURL.path)
        } else {
          finish(
            FlutterError(
              code: "AUDIO_FILE_MISSING",
              message: "macOS finished speech synthesis without creating a file.",
              details: nil
            )
          )
        }
        return
      }

      do {
        if self.exportAudioFile == nil {
          self.exportAudioFile = try AVAudioFile(
            forWriting: outputURL,
            settings: pcmBuffer.format.settings
          )
        }

        try self.exportAudioFile?.write(from: pcmBuffer)
      } catch {
        finish(
          FlutterError(
            code: "AUDIO_WRITE_FAILED",
            message: "Could not write the synthesized speech to WAV.",
            details: error.localizedDescription
          )
        )
      }
    }
  }
}
