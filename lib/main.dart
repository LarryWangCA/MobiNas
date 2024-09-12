import 'dart:async';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';


const theSource = AudioSource.microphone;

// Default filter settings
double defaultLowCutoff = 80;
double defaultHighCutoff = 1000;
double defaultNoiseThreshold = 0.008;
double defaultWindowSize = 0.05; // 50ms
double defaultNasalanceThreshold = 50.0; // Nasalance threshold for contour mode
// Example constraints
const double minLowCutoff = 20.0;
const double maxLowCutoff = 200.0;
const double minHighCutoff = 800.0;
const double maxHighCutoff = 3000.0;
const double minNoiseThreshold = 0.0;
const double maxNoiseThreshold = 1.0;
const double minWindowSize = 0.01; // 10 ms
const double maxWindowSize = 0.08; // 80 ms

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nasalance Display',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SettingsPage(),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  final _lowCutoffController = TextEditingController();
  final _highCutoffController = TextEditingController();
  final _noiseThresholdController = TextEditingController();
  final _windowSizeController = TextEditingController();
  final _nasalanceThresholdController = TextEditingController();

  final _lowCutoffFocusNode = FocusNode();
  final _highCutoffFocusNode = FocusNode();
  final _noiseThresholdFocusNode = FocusNode();
  final _windowSizeFocusNode = FocusNode();
  final _nasalanceThresholdFocusNode = FocusNode();

  String _selectedMode = 'Contour Mode'; // Default mode

  @override
  void initState() {
    super.initState();
    _setupFocusListeners();
    _loadSettings(); // Load saved settings when the app starts
  }

  @override
  void dispose() {
    _lowCutoffController.dispose();
    _highCutoffController.dispose();
    _noiseThresholdController.dispose();
    _windowSizeController.dispose();
    _nasalanceThresholdController.dispose();

    _lowCutoffFocusNode.dispose();
    _highCutoffFocusNode.dispose();
    _noiseThresholdFocusNode.dispose();
    _windowSizeFocusNode.dispose();
    _nasalanceThresholdFocusNode.dispose();

    super.dispose();
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      _lowCutoffController.text =
          (prefs.getDouble('lowCutoff') ?? defaultLowCutoff).toString();
      _highCutoffController.text =
          (prefs.getDouble('highCutoff') ?? defaultHighCutoff).toString();
      _noiseThresholdController.text =
          (prefs.getDouble('noiseThreshold') ?? defaultNoiseThreshold)
              .toString();
      _windowSizeController.text =
          (prefs.getDouble('windowSize') ?? defaultWindowSize).toString();
      _nasalanceThresholdController.text =
          (prefs.getDouble('nasalanceThreshold') ?? defaultNasalanceThreshold)
              .toString();
      _selectedMode = prefs.getString('selectedMode') ?? 'Contour Mode';
    });
  }

  Future<void> _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(
        'lowCutoff', double.parse(_lowCutoffController.text));
    await prefs.setDouble(
        'highCutoff', double.parse(_highCutoffController.text));
    await prefs.setDouble(
        'noiseThreshold', double.parse(_noiseThresholdController.text));
    await prefs.setDouble(
        'windowSize', double.parse(_windowSizeController.text));
    await prefs.setDouble('nasalanceThreshold',
        double.parse(_nasalanceThresholdController.text));
    await prefs.setString('selectedMode', _selectedMode);
  }

  void _setupFocusListeners() {
    _lowCutoffFocusNode.addListener(() {
      if (!_lowCutoffFocusNode.hasFocus) {
        _clampAndCorrectValues();
      }
    });
    _highCutoffFocusNode.addListener(() {
      if (!_highCutoffFocusNode.hasFocus) {
        _clampAndCorrectValues();
      }
    });
    _noiseThresholdFocusNode.addListener(() {
      if (!_noiseThresholdFocusNode.hasFocus) {
        _clampAndCorrectValues();
      }
    });
    _windowSizeFocusNode.addListener(() {
      if (!_windowSizeFocusNode.hasFocus) {
        _clampAndCorrectValues();
      }
    });
    _nasalanceThresholdFocusNode.addListener(() {
      if (!_nasalanceThresholdFocusNode.hasFocus) {
        _clampAndCorrectValues();
      }
    });
  }

  void _clampAndCorrectValues() {
    setState(() {
      double lowCutoff =
      (double.tryParse(_lowCutoffController.text) ?? defaultLowCutoff)
          .clamp(minLowCutoff, maxLowCutoff);
      double highCutoff =
      (double.tryParse(_highCutoffController.text) ?? defaultHighCutoff)
          .clamp(minHighCutoff, maxHighCutoff);
      double noiseThreshold =
      (double.tryParse(_noiseThresholdController.text) ??
          defaultNoiseThreshold)
          .clamp(minNoiseThreshold, maxNoiseThreshold);
      double windowSize =
      (double.tryParse(_windowSizeController.text) ?? defaultWindowSize)
          .clamp(minWindowSize, maxWindowSize);
      double nasalanceThreshold =
      (double.tryParse(_nasalanceThresholdController.text) ??
          defaultNasalanceThreshold)
          .clamp(0.0, 100.0);

      // Update controllers with clamped values
      _lowCutoffController.text = lowCutoff.toString();
      _highCutoffController.text = highCutoff.toString();
      _noiseThresholdController.text = noiseThreshold.toString();
      _windowSizeController.text = windowSize.toString();
      _nasalanceThresholdController.text = nasalanceThreshold.toString();

      _saveSettings(); // Save settings when values are clamped and corrected
    });
  }

  void _startRecording() {
    _clampAndCorrectValues(); // Clamp and correct values before starting recording

    double lowCutoff = double.parse(_lowCutoffController.text);
    double highCutoff = double.parse(_highCutoffController.text);
    double noiseThreshold = double.parse(_noiseThresholdController.text);
    double windowSize = double.parse(_windowSizeController.text);
    double nasalanceThreshold =
    double.parse(_nasalanceThresholdController.text);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SimpleRecorder(
          lowCutoff: lowCutoff,
          highCutoff: highCutoff,
          noiseThreshold: noiseThreshold,
          windowSize: windowSize,
          nasalanceThreshold: nasalanceThreshold,
          selectedMode: _selectedMode, // Pass the selected mode to the recorder
          onFinishRecording: (averageNasalance, maxNasalance, minNasalance,
              standardDeviation) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => SummaryPage(
                  averageNasalance: averageNasalance,
                  maxNasalance: maxNasalance,
                  minNasalance: minNasalance,
                  standardDeviation: standardDeviation,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context)
                .unfocus(); // Dismiss keyboard when tapping outside text fields
            _clampAndCorrectValues(); // Clamp and correct values when focus is lost
          },
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _lowCutoffController,
                    focusNode: _lowCutoffFocusNode,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Low Cutoff Frequency (Hz)',
                      hintText: defaultLowCutoff.toString(),
                    ),
                  ),
                  TextField(
                    controller: _highCutoffController,
                    focusNode: _highCutoffFocusNode,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'High Cutoff Frequency (Hz)',
                      hintText: defaultHighCutoff.toString(),
                    ),
                  ),
                  TextField(
                    controller: _noiseThresholdController,
                    focusNode: _noiseThresholdFocusNode,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Noise Threshold',
                      hintText: defaultNoiseThreshold.toString(),
                    ),
                  ),
                  TextField(
                    controller: _windowSizeController,
                    focusNode: _windowSizeFocusNode,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Window Size (s)',
                      hintText: defaultWindowSize.toString(),
                    ),
                  ),
                  TextField(
                    controller: _nasalanceThresholdController,
                    focusNode: _nasalanceThresholdFocusNode,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Nasalance Threshold (%)',
                      hintText: defaultNasalanceThreshold.toString(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButton<String>(
                    value: _selectedMode,
                    items: <String>['Contour Mode', 'Bar Mode']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedMode = newValue!;
                        _saveSettings(); // Save the selected mode when changed
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: _startRecording,
                      child: const Text('Start Recording'),
                    ),
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).size.height *
                          0.2), // Add extra space at the bottom
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class BandpassFilter {
  final double lowCutoff;
  final double highCutoff;
  final double transitionWidth;
  final int sampleRate;
  late List<double> filterCoefficients;

  BandpassFilter({
    required this.lowCutoff,
    required this.highCutoff,
    required this.transitionWidth,
    required this.sampleRate,
  }) {
    int order = (sampleRate / transitionWidth).round();
    filterCoefficients = _designBandpassFilter(order);
  }

  List<double> _designBandpassFilter(int order) {
    List<double> hannWindow = _hannWindow(order + 1);
    List<double> bpFilter = _fir1(order, [lowCutoff, highCutoff], hannWindow);
    return bpFilter;
  }

  List<double> _hannWindow(int n) {
    List<double> window = List<double>.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      window[i] = 0.5 * (1 - cos(2 * pi * i / (n - 1)));
    }
    return window;
  }

  List<double> _fir1(int order, List<double> cutoff, List<double> window) {
    List<double> coefficients = List<double>.filled(order + 1, 0.0);
    double fcLow = cutoff[0] / (sampleRate / 2);
    double fcHigh = cutoff[1] / (sampleRate / 2);

    for (int i = 0; i <= order; i++) {
      if (i - order / 2 == 0) {
        coefficients[i] = 2 * (fcHigh - fcLow);
      } else {
        coefficients[i] = (sin(2 * pi * fcHigh * (i - order / 2)) -
            sin(2 * pi * fcLow * (i - order / 2))) /
            (pi * (i - order / 2));
      }
      coefficients[i] *= window[i];
    }
    return coefficients;
  }

  List<double> apply(List<double> input) {
    List<double> output = List<double>.filled(input.length, 0.0);
    for (int i = 0; i < input.length; i++) {
      for (int j = 0; j < filterCoefficients.length; j++) {
        if (i - j >= 0) {
          output[i] += filterCoefficients[j] * input[i - j];
        }
      }
    }
    return output;
  }
}

class NasalanceCalculator {
  final int sampleRate;
  final double windowSize; // in seconds
  final double noiseThreshold; // threshold for determining silent part

  NasalanceCalculator({
    required this.sampleRate,
    required this.windowSize,
    required this.noiseThreshold,
  });

  List<double> calculateNasalance(
      List<double> filteredNasal, List<double> filteredOral) {
    int winSizeSamples = (windowSize * sampleRate).round();
    List<double> nasalanceData = [];

    List<List<double>> noseBuffers = _buffer(
        filteredNasal, winSizeSamples, winSizeSamples ~/ 2); // 50% overlap
    List<List<double>> oralBuffers = _buffer(
        filteredOral, winSizeSamples, winSizeSamples ~/ 2); // 50% overlap

    for (int i = 0; i < noseBuffers.length; i++) {
      double nasalEnergy = _calculateEnergy(noseBuffers[i]);
      double oralEnergy = _calculateEnergy(oralBuffers[i]);
      double totalEnergy = nasalEnergy + oralEnergy;

      double nasalance = 0.0;

      if (totalEnergy < noiseThreshold) {
        nasalance = 0.0;
      } else {
        nasalance = 100 * nasalEnergy / totalEnergy;
      }

      nasalanceData.add(nasalance);
    }

    return nasalanceData;
  }

  List<List<double>> _buffer(
      List<double> signal, int winSizeSamples, int overlap) {
    int step = winSizeSamples - overlap;
    int bufferCount = ((signal.length - overlap) / step).ceil();

    List<List<double>> buffers = List.generate(bufferCount, (_) {
      return List<double>.filled(winSizeSamples, 0.0);
    });

    for (int i = 0; i < bufferCount; i++) {
      int start = i * step;
      for (int j = 0; j < winSizeSamples; j++) {
        if (start + j < signal.length) {
          buffers[i][j] = signal[start + j];
        }
      }
    }

    return buffers;
  }

  double _calculateEnergy(List<double> buffer) {
    double energy = 0.0;
    for (var value in buffer) {
      energy += value * value;
    }
    return energy;
  }
}

class SimpleRecorder extends StatefulWidget {
  final double lowCutoff;
  final double highCutoff;
  final double noiseThreshold;
  final double windowSize;
  final double nasalanceThreshold;
  final String selectedMode;
  final Function(double averageNasalance, double maxNasalance,
      double minNasalance, double standardDeviation) onFinishRecording;

  const SimpleRecorder({
    super.key,
    required this.lowCutoff,
    required this.highCutoff,
    required this.noiseThreshold,
    required this.windowSize,
    required this.nasalanceThreshold,
    required this.selectedMode,
    required this.onFinishRecording,
  });

  @override
  State<SimpleRecorder> createState() => _SimpleRecorderState();
}

class _SimpleRecorderState extends State<SimpleRecorder> {
  FlutterSoundRecorder? _mRecorder = FlutterSoundRecorder();
  bool _mRecorderIsInited = false;
  StreamSubscription<Uint8List>? _recordingSubscription;
  bool _isRecordingStarted = false; // A flag to indicate when actual recording starts

  double currentWindowSize = defaultWindowSize; // Set default window size (in seconds)

  // To accumulate waveform data for both channels
  List<double> accumulatedMic1Data = [];
  List<double> accumulatedMic2Data = [];

  // To store nasalance values (only for real-time display)
  List<double> nasalanceData = [];

  // Running statistics object to accumulate statistics across windows
  RunningStats nasalanceStats = RunningStats();

  @override
  void initState() {
    super.initState();
    openTheRecorder().then((value) {
      setState(() {
        _mRecorderIsInited = true;
      });
      startRecording(); // Automatically start recording when the page is loaded
    });
  }

  @override
  void dispose() {
    _mRecorder!.closeRecorder();
    _mRecorder = null;
    _recordingSubscription?.cancel();
    super.dispose();
  }

  Future<void> openTheRecorder() async {
    if (!kIsWeb) {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw RecordingPermissionException('Microphone permission not granted');
      }
    }
    await _mRecorder!.openRecorder();
    _mRecorderIsInited = true;
  }

  void startRecording() async {
    if (!_mRecorderIsInited) return;

    StreamController<Uint8List> recordingController = StreamController<Uint8List>();
    _recordingSubscription = recordingController.stream.listen((buffer) {
      if (_isRecordingStarted) {
        _processAudioBuffer(buffer); // Process audio only after the initial delay
      }
    });

    await _mRecorder!.startRecorder(
      toStream: recordingController.sink,
      codec: Codec.pcm16,
      audioSource: theSource,
      numChannels: 2,
      sampleRate: 44100,
      bufferSize: 8192,
    );

    // Introduce a 2-second delay before actually starting to process audio
    await Future.delayed(Duration(seconds: 2));

    // Mark the recording as fully started
    setState(() {
      _isRecordingStarted = true;
    });
  }

  void _processAudioBuffer(Uint8List buffer) {
    ByteData byteData = ByteData.sublistView(buffer);

    for (int i = 0; i < byteData.lengthInBytes; i += 4) {
      int sampleMic1 = byteData.getInt16(i, Endian.little);
      int sampleMic2 = byteData.getInt16(i + 2, Endian.little);

      accumulatedMic1Data.add(sampleMic1 / 32768.0);
      accumulatedMic2Data.add(sampleMic2 / 32768.0);
    }

    // Calculate the required number of samples based on the window size
    int requiredSamples = (currentWindowSize * 44100).round();

    // Check if enough data has been accumulated for processing
    if (accumulatedMic1Data.length >= requiredSamples &&
        accumulatedMic2Data.length >= requiredSamples) {
      BandpassFilter filter = BandpassFilter(
        lowCutoff: widget.lowCutoff,
        highCutoff: widget.highCutoff,
        transitionWidth: 100,
        sampleRate: 44100,
      );

      List<double> filteredMic1Data = filter.apply(accumulatedMic1Data);
      List<double> filteredMic2Data = filter.apply(accumulatedMic2Data);

      NasalanceCalculator calculator = NasalanceCalculator(
        sampleRate: 44100,
        windowSize: widget.windowSize,
        noiseThreshold: widget.noiseThreshold,
      );

      List<double> nasalanceResults =
      calculator.calculateNasalance(filteredMic1Data, filteredMic2Data);

      // Update running statistics for each window, filtering out zero values
      for (double result in nasalanceResults) {
        if (result > 0) {
          nasalanceStats.addData(result); // Add only non-zero data
        }
      }

      // Clear the accumulated data after processing
      accumulatedMic1Data.clear();
      accumulatedMic2Data.clear();

      setState(() {
        nasalanceData.addAll(nasalanceResults);

        // Limit the number of values displayed on the graph
        if (nasalanceData.length > 100) {
          nasalanceData.removeRange(0, nasalanceData.length - 100);
        }
      });
    }
  }

  void stopRecording() async {
    await _mRecorder!.stopRecorder();
    _recordingSubscription?.cancel();

    if (!mounted) {
      return; // Guard against using context if the widget is not mounted
    }

    // Reset the recording state
    setState(() {
      _isRecordingStarted = false;
    });

    // Retrieve the final running statistics, only for non-zero values
    double averageNasalance = nasalanceStats.getAverage();
    double maxNasalance = nasalanceStats.getMax();
    double minNasalance = nasalanceStats.getMin();
    double standardDeviation = nasalanceStats.getStandardDeviation();

    widget.onFinishRecording(
        averageNasalance, maxNasalance, minNasalance, standardDeviation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Nasalance Graph'),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 17, // 85% of the screen height
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CustomPaint(
                  painter: widget.selectedMode == 'Contour Mode'
                      ? NasalanceGraphPainter(nasalanceData, widget.nasalanceThreshold)
                      : NasalanceBarPainter(nasalanceData, widget.nasalanceThreshold),
                  child: Container(),
                ),
              ),
            ),
            Expanded(
              flex: 3, // 15% of the screen height for the button
              child: Center(
                child: ElevatedButton(
                  onPressed: stopRecording,
                  child: const Text('Stop Recording'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// RunningStats class for managing running statistics
class RunningStats {
  int count = 0;
  double sum = 0.0;
  double sumOfSquares = 0.0;
  double maxValue = double.negativeInfinity;
  double minValue = double.infinity;

  void addData(double value) {
    // Only add non-zero values
    if (value > 0) {
      count++;
      sum += value;
      sumOfSquares += value * value;

      if (value > maxValue) {
        maxValue = value;
      }

      if (value < minValue) {
        minValue = value;
      }
    }
  }

  double getAverage() {
    return count > 0 ? sum / count : 0.0;
  }

  double getMax() {
    return maxValue == double.negativeInfinity ? 0.0 : maxValue;
  }

  double getMin() {
    return minValue == double.infinity ? 0.0 : minValue;
  }

  double getStandardDeviation() {
    if (count > 1) {
      double mean = getAverage();
      return sqrt((sumOfSquares / count) - (mean * mean));
    }
    return 0.0;
  }
}

// Contour display mode
class NasalanceGraphPainter extends CustomPainter {
  final List<double> nasalanceData;
  final double nasalanceThreshold;

  NasalanceGraphPainter(this.nasalanceData, this.nasalanceThreshold);

  @override
  void paint(Canvas canvas, Size size) {
    Paint solidPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0;

    Paint dotPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..style = PaintingStyle.fill;

    Paint gridPaint = Paint()
      ..color = Colors.brown.withOpacity(0.3)
      ..strokeWidth = 1.0;

    TextPainter textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    double maxValue = 100.0;
    double leftMargin = 40.0; // Add a margin to the left

    // Adjust the size for the grid to account for the left margin
    double adjustedWidth = size.width - leftMargin;

    // Define a consistent grid spacing for both horizontal and vertical lines
    double gridSpacing = size.height / 10; // 10 grid lines on the Y-axis

    // Draw grid background (horizontal and vertical lines)
    for (double y = 0; y <= size.height; y += gridSpacing) {
      canvas.drawLine(Offset(leftMargin, y), Offset(size.width, y), gridPaint);

      // Draw Y-axis labels corresponding to grid lines
      String label = '${(maxValue - (y / size.height) * maxValue).round()}%';
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(color: Colors.black, fontSize: 12),
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(leftMargin - 30, y - textPainter.height / 2));
    }

    for (double x = leftMargin; x <= size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Draw Y-axis
    Paint axisPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0;

    canvas.drawLine(Offset(leftMargin, 0), Offset(leftMargin, size.height),
        axisPaint); // Y-axis only

    // Draw nasalance graph
    if (nasalanceData.isNotEmpty) {
      double widthStep = adjustedWidth / nasalanceData.length;

      for (int i = 0; i < nasalanceData.length - 1; i++) {
        double x1 = leftMargin + i * widthStep;
        double y1 = size.height - (nasalanceData[i] / maxValue * size.height);
        double x2 = leftMargin + (i + 1) * widthStep;
        double y2 =
            size.height - (nasalanceData[i + 1] / maxValue * size.height);

        if (nasalanceData[i] > nasalanceThreshold) {
          // Draw as dot if above threshold
          canvas.drawCircle(Offset(x1, y1), 1.0, dotPaint);
        } else if (nasalanceData[i] > 0) {
          // Connect with a line if both points are below threshold
          if (nasalanceData[i + 1] <= nasalanceThreshold &&
              nasalanceData[i + 1] > 0) {
            canvas.drawLine(Offset(x1, y1), Offset(x2, y2), solidPaint);
          }
        }
      }

      // Draw the last point if it's above the threshold
      if (nasalanceData.last > nasalanceThreshold) {
        double xLast = leftMargin + (nasalanceData.length - 1) * widthStep;
        double yLast =
            size.height - (nasalanceData.last / maxValue * size.height);
        canvas.drawCircle(Offset(xLast, yLast), 1.0, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

//Bar graph display mode
class NasalanceBarPainter extends CustomPainter {
  final List<double> nasalanceData;
  final double nasalanceThreshold;

  NasalanceBarPainter(this.nasalanceData, this.nasalanceThreshold);

  @override
  void paint(Canvas canvas, Size size) {
    Paint barPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    Paint gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1.0;

    TextPainter textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    double maxValue = 100.0;
    double leftMargin = 40.0; // Add a margin to the left

    // Draw grid lines and Y-axis labels
    for (double y = 0; y <= size.height; y += size.height / 10) {
      canvas.drawLine(Offset(leftMargin, y), Offset(size.width, y), gridPaint);
      String label = '${(maxValue - (y / size.height) * maxValue).round()}%';
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(color: Colors.black, fontSize: 12),
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(leftMargin - 30, y - textPainter.height / 2));
    }

    // Draw Y-axis
    Paint axisPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0;
    canvas.drawLine(
        Offset(leftMargin, 0), Offset(leftMargin, size.height), axisPaint);

    // Draw the bar for the last nasalance value
    if (nasalanceData.isNotEmpty) {
      double nasalance = nasalanceData.last;
      double barHeight = nasalance / maxValue * size.height;

      canvas.drawRect(
        Rect.fromLTWH(leftMargin, size.height - barHeight,
            size.width - leftMargin, barHeight),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SummaryPage extends StatelessWidget {
  final double averageNasalance;
  final double maxNasalance;
  final double minNasalance;
  final double standardDeviation;

  const SummaryPage({super.key,
    required this.averageNasalance,
    required this.maxNasalance,
    required this.minNasalance,
    required this.standardDeviation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Result Summary'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Average Nasalance: ${averageNasalance.toStringAsFixed(2)}%',
                style: const TextStyle(fontSize: 20),
              ),
              Text(
                'Max Nasalance: ${maxNasalance.toStringAsFixed(2)}%',
                style: const TextStyle(fontSize: 20),
              ),
              Text(
                'Min Nasalance: ${minNasalance.toStringAsFixed(2)}%',
                style: const TextStyle(fontSize: 20),
              ),
              Text(
                'Standard Deviation: ${standardDeviation.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                        context); // Navigate back to the settings page
                  },
                  child: const Text('Back to Settings'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
