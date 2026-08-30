package com.johnacolani.text_to_speech

import android.os.Bundle
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.Locale
import java.util.UUID

class MainActivity : FlutterActivity() {
    private val exportChannelName = "text_to_speech/android_audio_export"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            exportChannelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "synthesizeToWav" -> synthesizeToWav(call, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun synthesizeToWav(call: MethodCall, result: MethodChannel.Result) {
        val text = call.argument<String>("text")?.trim().orEmpty()
        if (text.isEmpty()) {
            result.error("INVALID_TEXT", "Text is required for audio export.", null)
            return
        }

        val voiceName = call.argument<String>("voiceName").orEmpty()
        val language = call.argument<String>("language").orEmpty()
        val requestedRate = (call.argument<Double>("rate") ?: 0.5).toFloat()
        val requestedPitch = (call.argument<Double>("pitch") ?: 1.0).toFloat()
        val requestedVolume = (call.argument<Double>("volume") ?: 1.0).toFloat()

        val audioDirectory = File(filesDir, "TTS_audio")
        if (!audioDirectory.exists() && !audioDirectory.mkdirs()) {
            result.error(
                "OUTPUT_DIRECTORY_FAILED",
                "Could not prepare the Android audio export folder.",
                null,
            )
            return
        }

        val outputFile = File(
            audioDirectory,
            "tts_export_${UUID.randomUUID()}.wav",
        )
        val utteranceId = "tts_export_${UUID.randomUUID()}"

        var ttsEngine: TextToSpeech? = null
        var completed = false

        fun finishSuccess() {
            if (completed) return
            completed = true
            runOnUiThread {
                if (outputFile.exists() && outputFile.length() > 256L) {
                    result.success(outputFile.absolutePath)
                } else {
                    result.error(
                        "AUDIO_FILE_MISSING",
                        "Android finished speech synthesis without creating a usable file.",
                        null,
                    )
                }
                ttsEngine?.shutdown()
            }
        }

        fun finishError(code: String, message: String, details: Any? = null) {
            if (completed) return
            completed = true
            runOnUiThread {
                if (outputFile.exists()) {
                    outputFile.delete()
                }
                result.error(code, message, details)
                ttsEngine?.shutdown()
            }
        }

        ttsEngine = TextToSpeech(applicationContext) { status ->
            val engine = ttsEngine
            if (status != TextToSpeech.SUCCESS || engine == null) {
                finishError(
                    "TTS_INIT_FAILED",
                    "Android text-to-speech engine could not be initialized.",
                )
                return@TextToSpeech
            }

            if (language.isNotEmpty()) {
                val locale = Locale.forLanguageTag(language)
                val languageResult = engine.setLanguage(locale)
                if (
                    languageResult == TextToSpeech.LANG_MISSING_DATA ||
                    languageResult == TextToSpeech.LANG_NOT_SUPPORTED
                ) {
                    finishError(
                        "LANGUAGE_UNAVAILABLE",
                        "The selected language is not available in the Android TTS engine.",
                    )
                    return@TextToSpeech
                }
            }

            if (voiceName.isNotEmpty()) {
                engine.voices
                    ?.firstOrNull { it.name == voiceName }
                    ?.let { engine.voice = it }
            }

            engine.setSpeechRate(requestedRate.coerceIn(0.1f, 4.0f))
            engine.setPitch(requestedPitch.coerceIn(0.5f, 2.0f))

            engine.setOnUtteranceProgressListener(
                object : UtteranceProgressListener() {
                    override fun onStart(utteranceId: String?) = Unit

                    override fun onDone(doneUtteranceId: String?) {
                        if (doneUtteranceId == utteranceId) {
                            finishSuccess()
                        }
                    }

                    @Deprecated("Deprecated in Java")
                    override fun onError(errorUtteranceId: String?) {
                        if (errorUtteranceId == utteranceId) {
                            finishError(
                                "TTS_SYNTHESIS_FAILED",
                                "Android could not synthesize the selected speech to a file.",
                            )
                        }
                    }

                    override fun onError(errorUtteranceId: String?, errorCode: Int) {
                        if (errorUtteranceId == utteranceId) {
                            finishError(
                                "TTS_SYNTHESIS_FAILED",
                                "Android could not synthesize the selected speech to a file.",
                                errorCode,
                            )
                        }
                    }
                },
            )

            val params = Bundle().apply {
                putFloat(TextToSpeech.Engine.KEY_PARAM_VOLUME, requestedVolume.coerceIn(0.0f, 1.0f))
            }

            val synthResult = engine.synthesizeToFile(
                text,
                params,
                outputFile,
                utteranceId,
            )

            if (synthResult != TextToSpeech.SUCCESS) {
                finishError(
                    "TTS_SYNTHESIS_START_FAILED",
                    "Android TTS engine rejected the file synthesis request.",
                    synthResult,
                )
            }
        }
    }
}
