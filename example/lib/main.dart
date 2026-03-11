import 'package:audio_waveform_recorder/src/painters/waveform_painter.dart';
import 'package:audio_waveform_recorder/src/utils/duration_formatter.dart';
import 'package:flutter/material.dart';
import 'package:audio_waveform_recorder/audio_waveform_recorder.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Waveform Recorder Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const RecorderDemoPage(),
    );
  }
}

class RecorderDemoPage extends StatefulWidget {
  const RecorderDemoPage({super.key});

  @override
  State<RecorderDemoPage> createState() => _RecorderDemoPageState();
}

class _RecorderDemoPageState extends State<RecorderDemoPage> {
  RecordingResult? _lastRecording;
  WaveformStyle _style = WaveformStyle.bars;

  final _config = const RecorderConfig(
    format:         AudioFormat.m4a,
    sampleRate:     SampleRate.high44k,
    bitRate:        BitRate.medium128k,
    recordingColor: Color(0xFFE53935),
    playedColor:    Color(0xFF1E88E5),
    idleColor:      Color(0xFF607D8B),
    backgroundColor: Color(0xFF1A1A2E),
    barWidth:       3.0,
    barGap:         2.0,
    maxDuration:    Duration(minutes: 5),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Audio Waveform Recorder'),
        actions: [
          // Style switcher
          PopupMenuButton<WaveformStyle>(
            icon: const Icon(Icons.tune),
            onSelected: (s) => setState(() => _style = s),
            itemBuilder: (_) => [
              const PopupMenuItem(value: WaveformStyle.bars,   child: Text('Bars style')),
              const PopupMenuItem(value: WaveformStyle.mirror, child: Text('Mirror style')),
              const PopupMenuItem(value: WaveformStyle.line,   child: Text('Line style')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Recorder ────────────────────────────────────────────────
            const Text(
              'RECORDER',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            WaveformRecorderWidget(
              config: _config,
              style:  _style,
              waveformHeight: 80,
              showTimer: true,
              showMaxDuration: true,
              onRecordingComplete: (result) {
                setState(() => _lastRecording = result);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Saved! ${DurationFormatter.format(result.duration)} — '
                      '${DurationFormatter.formatBytes(result.fileSizeBytes)}',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              onRecordingCancelled: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Recording cancelled')),
                );
              },
            ),

            const SizedBox(height: 32),

            // ── Player ───────────────────────────────────────────────────
            if (_lastRecording != null) ...[
              const Text(
                'PLAYBACK',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),

              // Recording metadata card
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(children: [
                  const Icon(Icons.audio_file, color: Colors.indigo, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _lastRecording!.filePath.split('/').last,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${DurationFormatter.format(_lastRecording!.duration)}  •  '
                          '${DurationFormatter.formatBytes(_lastRecording!.fileSizeBytes)}  •  '
                          '${_lastRecording!.waveform.length} samples',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),

              WaveformPlayerWidget(
                filePath: _lastRecording!.filePath,
                waveform: _lastRecording!.waveform,
                config:   _config,
                style:    _style,
                waveformHeight:   80,
                showSpeedControl: true,
              ),
            ],

            const SizedBox(height: 32),

            // ── Standalone waveform example ───────────────────────────────
            if (_lastRecording != null) ...[
              const Text(
                'WAVEFORM ONLY (no controls)',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: WaveformPainterWidget(
                  waveform: _lastRecording!.waveform,
                  config:   _config.copyWith(idleColor: const Color(0xFF4CAF50)),
                  style:    WaveformStyle.mirror,
                  height:   48,
                ),
              ),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
