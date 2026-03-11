import Flutter
import UIKit
import AVFoundation
import Accelerate

public class AudioWaveformPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "audio_waveform_recorder",
            binaryMessenger: registrar.messenger()
        )
        let instance = AudioWaveformPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    // ── State ─────────────────────────────────────────────────────────────
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer:   AVAudioPlayer?
    private var currentFilePath: String?
    private var recordingStartTime: Date?

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]

        switch call.method {

        // ── Permissions ───────────────────────────────────────────────────
        case "hasMicPermission":
            result(AVAudioSession.sharedInstance().recordPermission == .granted)

        case "requestMicPermission":
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async { result(granted) }
            }

        // ── Recording ─────────────────────────────────────────────────────
        case "startRecording":
            let format      = args["format"]     as? String ?? "m4a"
            let sampleRate  = args["sampleRate"]  as? Double ?? 44100.0
            let bitRate     = args["bitRate"]     as? Int    ?? 128000
            let channels    = args["channels"]    as? Int    ?? 1
            let outputDir   = args["outputDir"]   as? String
            let fileName    = args["fileName"]    as? String

            do {
                let path = buildOutputPath(format: format, outputDir: outputDir, fileName: fileName)
                try startAudioRecorder(
                    path: path, format: format,
                    sampleRate: sampleRate, bitRate: bitRate, channels: channels
                )
                currentFilePath = path
                recordingStartTime = Date()
                result(path)
            } catch {
                result(FlutterError(code: "RECORD_ERROR", message: error.localizedDescription, details: nil))
            }

        case "pauseRecording":
            audioRecorder?.pause()
            result(nil)

        case "resumeRecording":
            audioRecorder?.record()
            result(nil)

        case "stopRecording":
            audioRecorder?.stop()
            let path     = currentFilePath ?? ""
            let url      = URL(fileURLWithPath: path)
            let size     = (try? FileManager.default.attributesOfItem(atPath: path)[.size] as? Int) ?? 0
            let duration = Int((Date().timeIntervalSince(recordingStartTime ?? Date())) * 1000)

            try? AVAudioSession.sharedInstance().setActive(false)
            audioRecorder = nil
            currentFilePath = nil

            result(["path": path, "durationMs": duration, "sizeBytes": size])

        case "cancelRecording":
            audioRecorder?.stop()
            audioRecorder = nil
            if let path = currentFilePath {
                try? FileManager.default.removeItem(atPath: path)
            }
            currentFilePath = nil
            try? AVAudioSession.sharedInstance().setActive(false)
            result(nil)

        case "getAmplitude":
            guard let recorder = audioRecorder else { result(0.0); return }
            recorder.updateMeters()
            // averagePower is in dBFS (-160 to 0). Convert to 0.0–1.0
            let dB      = recorder.averagePower(forChannel: 0)
            let minDB   = -60.0 as Float
            let normalised: Double
            if dB < minDB {
                normalised = 0.0
            } else if dB >= 0 {
                normalised = 1.0
            } else {
                normalised = Double((dB - minDB) / (0 - minDB))
            }
            result(normalised)

        // ── Playback ──────────────────────────────────────────────────────
        case "loadAudio":
            guard let path = args["path"] as? String else {
                result(FlutterError(code: "ARGS", message: "path required", details: nil))
                return
            }
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback)
                try AVAudioSession.sharedInstance().setActive(true)
                audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                audioPlayer?.prepareToPlay()
                let durationMs = Int((audioPlayer?.duration ?? 0) * 1000)
                result(["durationMs": durationMs])
            } catch {
                result(FlutterError(code: "LOAD_ERROR", message: error.localizedDescription, details: nil))
            }

        case "playAudio":
            audioPlayer?.play()
            result(nil)

        case "pauseAudio":
            audioPlayer?.pause()
            result(nil)

        case "stopAudio":
            audioPlayer?.stop()
            audioPlayer?.currentTime = 0
            result(nil)

        case "seekTo":
            let ms = args["positionMs"] as? Int ?? 0
            audioPlayer?.currentTime = Double(ms) / 1000.0
            result(nil)

        case "getPlaybackPosition":
            let ms = Int((audioPlayer?.currentTime ?? 0) * 1000)
            result(ms)

        case "setVolume":
            let vol = args["volume"] as? Float ?? 1.0
            audioPlayer?.volume = vol
            result(nil)

        case "setSpeed":
            let speed = args["speed"] as? Float ?? 1.0
            audioPlayer?.rate = speed
            result(nil)

        // ── Waveform extraction ───────────────────────────────────────────
        case "extractWaveform":
            guard let path = args["path"] as? String else {
                result(FlutterError(code: "ARGS", message: "path required", details: nil))
                return
            }
            let sampleCount = args["sampleCount"] as? Int ?? 200

            DispatchQueue.global(qos: .userInitiated).async {
                let samples = self.extractWaveform(from: path, sampleCount: sampleCount)
                DispatchQueue.main.async { result(samples) }
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // ── AVAudioRecorder setup ─────────────────────────────────────────────

    private func startAudioRecorder(
        path: String, format: String,
        sampleRate: Double, bitRate: Int, channels: Int
    ) throws {
        try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.defaultToSpeaker])
        try AVAudioSession.sharedInstance().setActive(true)

        let formatID: AudioFormatID
        let ext = format.lowercased()
        if ext == "wav" {
            formatID = kAudioFormatLinearPCM
        } else {
            formatID = kAudioFormatMPEG4AAC
        }

        let settings: [String: Any] = [
            AVFormatIDKey:              formatID,
            AVSampleRateKey:            sampleRate,
            AVNumberOfChannelsKey:      channels,
            AVEncoderBitRateKey:        bitRate,
            AVEncoderAudioQualityKey:   AVAudioQuality.high.rawValue,
            AVLinearPCMBitDepthKey:     16,
            AVLinearPCMIsBigEndianKey:  false,
            AVLinearPCMIsFloatKey:      false,
        ]

        audioRecorder = try AVAudioRecorder(
            url: URL(fileURLWithPath: path),
            settings: settings
        )
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.record()
    }

    // ── Output path builder ───────────────────────────────────────────────

    private func buildOutputPath(format: String, outputDir: String?, fileName: String?) -> String {
        let dir: URL
        if let d = outputDir {
            dir = URL(fileURLWithPath: d)
        } else {
            dir = FileManager.default.temporaryDirectory
        }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let name = fileName ?? "recording_\(Int(Date().timeIntervalSince1970))"
        return dir.appendingPathComponent("\(name).\(format)").path
    }

    // ── Waveform extraction ───────────────────────────────────────────────

    private func extractWaveform(from path: String, sampleCount: Int) -> [Double] {
        guard let file = try? AVAudioFile(forReading: URL(fileURLWithPath: path)),
              let format = AVAudioFormat(
                  commonFormat: .pcmFormatFloat32,
                  sampleRate: file.fileFormat.sampleRate,
                  channels: 1,
                  interleaved: false
              ) else {
            return Array(repeating: 0.0, count: sampleCount)
        }

        let frameCount = AVAudioFrameCount(file.length)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return Array(repeating: 0.0, count: sampleCount)
        }

        do {
            try file.read(into: buffer)
        } catch {
            return Array(repeating: 0.0, count: sampleCount)
        }

        guard let floatData = buffer.floatChannelData?[0] else {
            return Array(repeating: 0.0, count: sampleCount)
        }

        let totalSamples = Int(buffer.frameLength)
        let bucketSize   = max(1, totalSamples / sampleCount)

        var result = [Double]()
        for i in 0..<sampleCount {
            let start = i * bucketSize
            let end   = min(start + bucketSize, totalSamples)
            guard start < totalSamples else { result.append(0.0); continue }

            // RMS of the bucket using Accelerate
            var rms: Float = 0
            vDSP_rmsqv(floatData + start, 1, &rms, vDSP_Length(end - start))
            result.append(Double(min(rms, 1.0)))
        }

        return result
    }
}
