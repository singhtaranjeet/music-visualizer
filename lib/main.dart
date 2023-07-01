import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: VisualiserWidget(),
    );
  }
}

class VisualiserWidget extends StatefulWidget {
  const VisualiserWidget({
    super.key,
  });

  @override
  State<VisualiserWidget> createState() => _VisualiserWidgetState();
}

class _VisualiserWidgetState extends State<VisualiserWidget> {
  final playerController = PlayerController();
  final justAudioPlayer = AudioPlayer();
  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    // Or directly extract from preparePlayer and initialise audio player
    await playerController.preparePlayer(
      path: 'assets/example_test.wav',
      shouldExtractWaveform: true,
      // noOfSamples: 100,
      // volume: 1.0,
    );
    playerController.startPlayer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: AudioFileWaveforms(
      playerController: playerController,
      enableSeekGesture: true,
      size: Size(MediaQuery.of(context).size.width, 100.0),
    ));
  }
}
