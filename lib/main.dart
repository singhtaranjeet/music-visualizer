import 'dart:io';
import 'dart:math';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter/ffprobe_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wav/wav.dart';

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
  // final justAudioPlayer = AudioPlayer();
  final fileName = "m1.wav";
  late final assetsPath = 'assets/$fileName';
  final audioPlayer = AudioPlayer();
  List<double> spectrogram = [];
  @override
  void initState() {
    super.initState();

    init();
  }

  Future<void> init() async {
    await audioPlayer.setAudioSource(AudioSource.asset(assetsPath));
    // Or directly extract from preparePlayer and initialise audio player
    // await playerController.preparePlayer(
    //   path: 'assets/example_test.wav',
    //   shouldExtractWaveform: true,
    //   // noOfSamples: 100,
    //   // volume: 1.0,
    // );
    // playerController.startPlayer();
    audioPlayer.sequenceStateStream.listen((event) {
      print(event?.shuffleIndices);
    },
        // onError: () => print("Error"),
        onDone: () {
      print("done");
    });
    await audioPlayer.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          SquigglyWaveform(
            samples: spectrogram,
            height: 200,
            width: MediaQuery.of(context).size.width,
          ),
          FilledButton(
              onPressed: () async {
                Directory tempDir = await getLibraryDirectory();
                String tempPath = tempDir.path;
                final filePath = "$tempPath/$fileName";
                final file = File(filePath);
                final outFile = File("$tempPath/out.raw");
                if (!file.existsSync()) {
                  ByteData data = await rootBundle.load(assetsPath);
                  print("Asset Loaded");
                  List<int> bytes = data.buffer
                      .asUint8List(data.offsetInBytes, data.lengthInBytes);
                  print("File creation started");
                  final file = await File(filePath).writeAsBytes(bytes);
                  print("File Created");
                }
                print("File Exists");

                FFprobeKit.getMediaInformation(file.path).then((session) async {
                  final information = session.getMediaInformation();
                  if (information == null) {
                    // CHECK THE FOLLOWING ATTRIBUTES ON ERROR
                    final state = FFmpegKitConfig.sessionStateToString(
                        await session.getState());
                    final returnCode = await session.getReturnCode();
                    final failStackTrace = await session.getFailStackTrace();
                    final duration = await session.getDuration();
                    final output = await session.getOutput();
                  }
                  outFile.deleteSync();
                  FFmpegKit.execute(
                          '-i $filePath -f s16le -ar 44100 -ac 1 ${outFile.path}')
                      .then((session) async {
                    final output = session.getOutput();
                    final rawAudioData = outFile.readAsBytesSync();
                    print(rawAudioData.length);
                    // Create an array of frequencies.

                    // print(rawAudioData);
                    // final fft = FFT(rawAudioData.length);
                    // Create an array of frequencies.
                    // final frequencies =
                    //     List<double>.filled(rawAudioData.length, 0);
                    // // Calculate the FFT of the raw audio data.
                    // for (int i = 0; i < rawAudioData.length; i++) {
                    //   frequencies[i] = cos(2 * pi * i / rawAudioData.length);
                    // }
                    // print(frequencies.length);
                    ByteData data = await rootBundle.load(assetsPath);
                    final wav = Wav.read(data.buffer.asUint8List());
                    final v = wav.toMono();
                    List<int> bytes = data.buffer
                        .asUint8List(data.offsetInBytes, data.lengthInBytes);
                    final frequencies = loadparseJson(bytes);
                    print(frequencies.length);
                    print(v.length);
                    setState(() {
                      spectrogram = v;
                    });
                    // final frequencies = fft(rawAudioData);
                    // Print the frequencies to the console.
                    // for (int i = 0; i < frequencies.length; i++) {
                    //   print(frequencies[i]);
                    // }
                  });
                });
              },
              child: Text("Print")),
        ],
      ),
    );
  }

  List<double> loadparseJson(List<int> points) {
    List<int> filteredData = [];
    // Change this value to number of audio samples you want.
    // Values between 256 and 1024 are good for showing [RectangleWaveform] and [SquigglyWaveform]
    // While the values above them are good for showing [PolygonWaveform]
    const int samples = 256;
    final double blockSize = points.length / samples;

    for (int i = 0; i < samples; i++) {
      final double blockStart =
          blockSize * i; // the location of the first sample in the block
      int sum = 0;
      for (int j = 0; j < blockSize; j++) {
        sum = sum +
            points[(blockStart + j).toInt()]
                .toInt(); // find the sum of all the samples in the block
      }
      filteredData.add((sum / blockSize)
          .round() // take the average of the block and add it to the filtered data
          .toInt()); // divide the sum by the block size to get the average
    }
    final maxNum = filteredData.reduce((a, b) => max(a.abs(), b.abs()));

    final double multiplier = pow(maxNum, -1).toDouble();

    return filteredData.map<double>((e) => (e * multiplier)).toList();
  }
}
