package com.example.audio_waveform_recorder

import android.Manifest
import android.content.pm.PackageManager
import android.media.*
import android.os.Build
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.io.RandomAccessFile
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.text.SimpleDateFormat
import java.util.*
import kotlin.math.abs
import kotlin.math.sqrt

class AudioWaveformPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel
    private var context: android.content.Context? = null

    // Recording
    private var mediaRecorder: MediaRecorder? = null
    private var currentFilePath: String? = null
    private var recordingStartTime: Long = 0L

    // Playback
    private var mediaPlayer: MediaPlayer? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "audio_waveform_recorder")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        mediaRecorder?.release()
        mediaPlayer?.release()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {

            // ── Permissions ──────────────────────────────────────────────
            "hasMicPermission" -> {
                val granted = ContextCompat.checkSelfPermission(
                    context!!,
                    Manifest.permission.RECORD_AUDIO
                ) == PackageManager.PERMISSION_GRANTED
                result.success(granted)
            }

            "requestMicPermission" -> {
                // Permission request must be done from Activity context.
                // Return current state — caller should use permission_handler pkg or
                // request from their Activity for full flow.
                val granted = ContextCompat.checkSelfPermission(
                    context!!,
                    Manifest.permission.RECORD_AUDIO
                ) == PackageManager.PERMISSION_GRANTED
                result.success(granted)
            }

            // ── Recording ────────────────────────────────────────────────
            "startRecording" -> {
                val format    = call.argument<String>("format") ?: "m4a"
                val sampleRate = call.argument<Int>("sampleRate") ?: 44100
                val bitRate    = call.argument<Int>("bitRate") ?: 128000
                val channels   = call.argument<Int>("channels") ?: 1
                val outputDir  = call.argument<String>("outputDir")
                val fileName   = call.argument<String>("fileName")

                try {
                    val path = buildOutputPath(format, outputDir, fileName)
                    startMediaRecorder(path, format, sampleRate, bitRate, channels)
                    currentFilePath = path
                    recordingStartTime = System.currentTimeMillis()
                    result.success(path)
                } catch (e: Exception) {
                    result.error("RECORD_ERROR", e.message, null)
                }
            }

            "pauseRecording" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    try { mediaRecorder?.pause(); result.success(null) }
                    catch (e: Exception) { result.error("PAUSE_ERROR", e.message, null) }
                } else {
                    result.error("UNSUPPORTED", "Pause requires Android 7+", null)
                }
            }

            "resumeRecording" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    try { mediaRecorder?.resume(); result.success(null) }
                    catch (e: Exception) { result.error("RESUME_ERROR", e.message, null) }
                } else {
                    result.error("UNSUPPORTED", "Resume requires Android 7+", null)
                }
            }

            "stopRecording" -> {
                try {
                    mediaRecorder?.stop()
                    mediaRecorder?.release()
                    mediaRecorder = null

                    val path = currentFilePath ?: ""
                    val file = File(path)
                    val durationMs = System.currentTimeMillis() - recordingStartTime

                    result.success(mapOf(
                        "path"       to path,
                        "durationMs" to durationMs.toInt(),
                        "sizeBytes"  to file.length().toInt(),
                    ))
                    currentFilePath = null
                } catch (e: Exception) {
                    result.error("STOP_ERROR", e.message, null)
                }
            }

            "cancelRecording" -> {
                try {
                    mediaRecorder?.stop()
                } catch (_) {}
                mediaRecorder?.release()
                mediaRecorder = null
                currentFilePath?.let { File(it).delete() }
                currentFilePath = null
                result.success(null)
            }

            "getAmplitude" -> {
                val recorder = mediaRecorder
                if (recorder == null) {
                    result.success(0.0)
                    return
                }
                try {
                    // maxAmplitude returns 0-32767
                    val raw = recorder.maxAmplitude
                    val normalised = raw / 32767.0
                    result.success(normalised)
                } catch (_) {
                    result.success(0.0)
                }
            }

            // ── Playback ─────────────────────────────────────────────────
            "loadAudio" -> {
                val path = call.argument<String>("path") ?: return result.error("ARGS", "path required", null)
                try {
                    mediaPlayer?.release()
                    mediaPlayer = MediaPlayer().apply {
                        setDataSource(path)
                        prepare()
                    }
                    result.success(mapOf("durationMs" to (mediaPlayer?.duration ?: 0)))
                } catch (e: Exception) {
                    result.error("LOAD_ERROR", e.message, null)
                }
            }

            "playAudio" -> {
                try { mediaPlayer?.start(); result.success(null) }
                catch (e: Exception) { result.error("PLAY_ERROR", e.message, null) }
            }

            "pauseAudio" -> {
                try { mediaPlayer?.pause(); result.success(null) }
                catch (e: Exception) { result.error("PAUSE_ERROR", e.message, null) }
            }

            "stopAudio" -> {
                try {
                    mediaPlayer?.stop()
                    mediaPlayer?.prepare() // reset to beginning
                    result.success(null)
                } catch (_) { result.success(null) }
            }

            "seekTo" -> {
                val ms = call.argument<Int>("positionMs") ?: 0
                try { mediaPlayer?.seekTo(ms); result.success(null) }
                catch (e: Exception) { result.error("SEEK_ERROR", e.message, null) }
            }

            "getPlaybackPosition" -> {
                result.success(mediaPlayer?.currentPosition ?: 0)
            }

            "setVolume" -> {
                val vol = (call.argument<Double>("volume") ?: 1.0).toFloat()
                mediaPlayer?.setVolume(vol, vol)
                result.success(null)
            }

            "setSpeed" -> {
                val speed = (call.argument<Double>("speed") ?: 1.0).toFloat()
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    mediaPlayer?.playbackParams = mediaPlayer?.playbackParams?.setSpeed(speed)
                        ?: PlaybackParams().setSpeed(speed)
                }
                result.success(null)
            }

            // ── Waveform extraction ───────────────────────────────────────
            "extractWaveform" -> {
                val path        = call.argument<String>("path") ?: return result.error("ARGS", "path required", null)
                val sampleCount = call.argument<Int>("sampleCount") ?: 200

                Thread {
                    try {
                        val samples = extractWaveformFromFile(path, sampleCount)
                        channel.invokeMethod("_waveformResult", null) // not used
                        result.success(samples)
                    } catch (e: Exception) {
                        result.error("WAVEFORM_ERROR", e.message, null)
                    }
                }.start()
            }

            else -> result.notImplemented()
        }
    }

    // ── MediaRecorder setup ───────────────────────────────────────────────

    private fun startMediaRecorder(
        path: String, format: String,
        sampleRate: Int, bitRate: Int, channels: Int
    ) {
        mediaRecorder?.release()
        mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            MediaRecorder(context!!)
        } else {
            @Suppress("DEPRECATION")
            MediaRecorder()
        }

        mediaRecorder?.apply {
            setAudioSource(MediaRecorder.AudioSource.MIC)
            setOutputFormat(when (format) {
                "wav"  -> MediaRecorder.OutputFormat.DEFAULT
                "ogg"  -> MediaRecorder.OutputFormat.OGG
                else   -> MediaRecorder.OutputFormat.MPEG_4
            })
            setAudioEncoder(when (format) {
                "ogg"  -> MediaRecorder.AudioEncoder.VORBIS
                else   -> MediaRecorder.AudioEncoder.AAC
            })
            setAudioSamplingRate(sampleRate)
            setAudioEncodingBitRate(bitRate)
            setAudioChannels(channels)
            setOutputFile(path)
            prepare()
            start()
        }
    }

    // ── File path builder ─────────────────────────────────────────────────

    private fun buildOutputPath(format: String, outputDir: String?, fileName: String?): String {
        val dir = outputDir?.let { File(it) }
            ?: context!!.cacheDir
        dir.mkdirs()
        val name = fileName ?: "recording_${SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())}"
        return "${dir.absolutePath}/$name.$format"
    }

    // ── Waveform extraction from audio file ───────────────────────────────

    private fun extractWaveformFromFile(path: String, sampleCount: Int): List<Double> {
        val extractor = MediaExtractor()
        extractor.setDataSource(path)

        // Find audio track
        var audioTrackIndex = -1
        var format: MediaFormat? = null
        for (i in 0 until extractor.trackCount) {
            val f = extractor.getTrackFormat(i)
            if (f.getString(MediaFormat.KEY_MIME)?.startsWith("audio/") == true) {
                audioTrackIndex = i
                format = f
                break
            }
        }

        if (audioTrackIndex < 0 || format == null) {
            extractor.release()
            return List(sampleCount) { 0.0 }
        }

        extractor.selectTrack(audioTrackIndex)

        val codec = MediaCodec.createDecoderByType(
            format.getString(MediaFormat.KEY_MIME)!!
        )
        codec.configure(format, null, null, 0)
        codec.start()

        val rawSamples = mutableListOf<Short>()
        val bufferInfo = MediaCodec.BufferInfo()
        var inputDone = false
        var outputDone = false

        while (!outputDone) {
            if (!inputDone) {
                val inputIdx = codec.dequeueInputBuffer(10000)
                if (inputIdx >= 0) {
                    val buf = codec.getInputBuffer(inputIdx)!!
                    val size = extractor.readSampleData(buf, 0)
                    if (size < 0) {
                        codec.queueInputBuffer(inputIdx, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                        inputDone = true
                    } else {
                        codec.queueInputBuffer(inputIdx, 0, size, extractor.sampleTime, 0)
                        extractor.advance()
                    }
                }
            }

            val outputIdx = codec.dequeueOutputBuffer(bufferInfo, 10000)
            if (outputIdx >= 0) {
                val buf = codec.getOutputBuffer(outputIdx)!!
                val shorts = buf.order(ByteOrder.LITTLE_ENDIAN).asShortBuffer()
                while (shorts.hasRemaining()) rawSamples.add(shorts.get())
                codec.releaseOutputBuffer(outputIdx, false)
                if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                    outputDone = true
                }
            }
        }

        codec.stop()
        codec.release()
        extractor.release()

        // Bucket into sampleCount chunks, compute RMS of each
        if (rawSamples.isEmpty()) return List(sampleCount) { 0.0 }
        val bucketSize = maxOf(1, rawSamples.size / sampleCount)
        return (0 until sampleCount).map { i ->
            val start = i * bucketSize
            val end   = minOf(start + bucketSize, rawSamples.size)
            if (start >= rawSamples.size) return@map 0.0
            var sum = 0.0
            for (j in start until end) sum += rawSamples[j] * rawSamples[j].toDouble()
            val rms = sqrt(sum / (end - start))
            (rms / Short.MAX_VALUE).coerceIn(0.0, 1.0)
        }
    }
}
