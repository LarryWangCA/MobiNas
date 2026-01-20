import 'dart:async';
import 'dart:typed_data';
import 'dart:math';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

const theSource = AudioSource.microphone;

// Default filter settings
double defaultLowCutoff = 200;
double defaultHighCutoff = 800;
double defaultNoiseThreshold = 0.008;
double defaultWindowSize = 0.05; // 50ms
double defaultNasalanceThreshold = 50.0; // Nasalance threshold for contour mode
// Example constraints
const double minLowCutoff = 50.0;
const double maxLowCutoff = 300.0;
const double minHighCutoff = 750.0;
const double maxHighCutoff = 1000.0;
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
    await prefs.setDouble('lowCutoff', double.parse(_lowCutoffController.text));
    await prefs.setDouble(
        'highCutoff', double.parse(_highCutoffController.text));
    await prefs.setDouble(
        'noiseThreshold', double.parse(_noiseThresholdController.text));
    await prefs.setDouble(
        'windowSize', double.parse(_windowSizeController.text));
    await prefs.setDouble(
        'nasalanceThreshold', double.parse(_nasalanceThresholdController.text));
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
              standardDeviation, filePath) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => SummaryPage(
                  averageNasalance: averageNasalance,
                  maxNasalance: maxNasalance,
                  minNasalance: minNasalance,
                  standardDeviation: standardDeviation,
                  recordingFilePath: filePath,
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
  final int sampleRate;
  final int order;
  late List<double> bCoefficients; // Numerator coefficients
  late List<double> aCoefficients; // Denominator coefficients

  BandpassFilter({
    required this.lowCutoff,
    required this.highCutoff,
    required this.sampleRate,
    this.order = 2, // Default to 2nd order like MATLAB
  }) {
    _designButterworthBandpass();
  }

  void _designButterworthBandpass() {
    // Normalize cutoff frequencies (MATLAB style normalization)
    double fcLow = lowCutoff / (sampleRate / 2);
    double fcHigh = highCutoff / (sampleRate / 2);
    
    // Design Butterworth bandpass filter using MATLAB equivalent approach
    var filterCoeffs = _butterworthBandpass(order, fcLow, fcHigh);
    bCoefficients = filterCoeffs['b']!;
    aCoefficients = filterCoeffs['a']!;
  }

  Map<String, List<double>> _butterworthBandpass(int n, double wLow, double wHigh) {
    // For 2nd order Butterworth bandpass, use direct design
    if (n == 2) {
      return _butterworth2ndOrderBandpass(wLow, wHigh);
    }
    
    // For other orders, use generic design
    return _genericButterworthBandpass(n, wLow, wHigh);
  }

  Map<String, List<double>> _butterworth2ndOrderBandpass(double wLow, double wHigh) {
    // Direct 2nd order Butterworth bandpass design
    // This approximates MATLAB's butter(2, [wLow wHigh], 'bandpass')
    
    double w0 = sqrt(wLow * wHigh); // Center frequency
    double bw = wHigh - wLow; // Bandwidth
    
    // Normalize by Nyquist frequency
    double w0Norm = w0;
    double bwNorm = bw;
    
    // 2nd order Butterworth bandpass coefficients
    // These are approximate coefficients for a 2nd order bandpass
    List<double> b = [bwNorm, 0.0, -bwNorm];
    List<double> a = [1.0, -2.0 * cos(w0Norm * pi), 1.0];
    
    // Normalize by a[0] (which is 1.0 in this case)
    return {'b': b, 'a': a};
  }

  Map<String, List<double>> _genericButterworthBandpass(int n, double wLow, double wHigh) {
    // Generic Butterworth bandpass design for arbitrary order
    // This is a simplified implementation
    
    double w0 = sqrt(wLow * wHigh);
    double bw = wHigh - wLow;
    
    // Simplified bandpass coefficients
    List<double> b = List<double>.filled(2 * n + 1, 0.0);
    List<double> a = List<double>.filled(2 * n + 1, 0.0);
    
    // Set up basic bandpass structure
    b[0] = bw;
    b[b.length - 1] = -bw;
    a[0] = 1.0;
    a[1] = -2.0 * cos(w0 * pi);
    a[a.length - 1] = 1.0;
    
    return {'b': b, 'a': a};
  }

  List<double> apply(List<double> input) {
    // Apply causal filtering (forward pass only)
    return _filter(bCoefficients, aCoefficients, input);
  }

  List<double> applyZeroPhase(List<double> input) {
    // Apply zero-phase filtering (forward + backward, like MATLAB's filtfilt)
    List<double> forwardFiltered = _filter(bCoefficients, aCoefficients, input);
    List<double> reversed = forwardFiltered.reversed.toList();
    List<double> backwardFiltered = _filter(bCoefficients, aCoefficients, reversed);
    return backwardFiltered.reversed.toList();
  }

  List<double> _filter(List<double> b, List<double> a, List<double> input) {
    List<double> output = List<double>.filled(input.length, 0.0);
    
    for (int n = 0; n < input.length; n++) {
      // Calculate output sample using difference equation
      // y[n] = b[0]*x[n] + b[1]*x[n-1] + ... - a[1]*y[n-1] - a[2]*y[n-2] - ...
      
      double sum = 0.0;
      
      // Feedforward terms (b coefficients)
      for (int i = 0; i < b.length; i++) {
        if (n - i >= 0) {
          sum += b[i] * input[n - i];
        }
      }
      
      // Feedback terms (a coefficients, excluding a[0])
      for (int i = 1; i < a.length; i++) {
        if (n - i >= 0) {
          sum -= a[i] * output[n - i];
        }
      }
      
      // Normalize by a[0]
      if (a.isNotEmpty) {
        sum /= a[0];
      }
      
      output[n] = sum;
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
      double nasalRMS = _calculateEnergy(noseBuffers[i]);  // RMS nasal energy
      double oralRMS = _calculateEnergy(oralBuffers[i]);   // RMS oral energy
      double totalEnergy = nasalRMS * nasalRMS + oralRMS * oralRMS;  // Total energy (sum of RMS squares)

      double nasalance = 0.0;

      if (totalEnergy < noiseThreshold) {
        nasalance = 0.0;
      } else {
        // RMS-based nasalance calculation to match MATLAB: rn / (rn + ro)
        nasalance = 100 * nasalRMS / (nasalRMS + oralRMS + 1e-10);  // Add small epsilon to avoid division by zero
      }

      nasalanceData.add(nasalance);
    }

    return nasalanceData;
  }

  // New method to return both nasalance and energy values for MAD calculation
  Map<String, List<double>> calculateNasalanceWithEnergy(
      List<double> filteredNasal, List<double> filteredOral) {
    int winSizeSamples = (windowSize * sampleRate).round();
    List<double> nasalanceData = [];
    List<double> energyData = [];

    List<List<double>> noseBuffers = _buffer(
        filteredNasal, winSizeSamples, winSizeSamples ~/ 2); // 50% overlap
    List<List<double>> oralBuffers = _buffer(
        filteredOral, winSizeSamples, winSizeSamples ~/ 2); // 50% overlap

    for (int i = 0; i < noseBuffers.length; i++) {
      double nasalRMS = _calculateEnergy(noseBuffers[i]);  // RMS nasal energy
      double oralRMS = _calculateEnergy(oralBuffers[i]);   // RMS oral energy
      double totalEnergy = nasalRMS * nasalRMS + oralRMS * oralRMS;  // Total energy (sum of RMS squares)

      double nasalance = 0.0;

      if (totalEnergy < noiseThreshold) {
        nasalance = 0.0;
      } else {
        // RMS-based nasalance calculation to match MATLAB: rn / (rn + ro)
        nasalance = 100 * nasalRMS / (nasalRMS + oralRMS + 1e-10);  // Add small epsilon to avoid division by zero
      }

      nasalanceData.add(nasalance);
      energyData.add(totalEnergy);
    }

    return {'nasalance': nasalanceData, 'energy': energyData};
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
    double sumOfSquares = 0.0;
    for (var value in buffer) {
      sumOfSquares += value * value;
    }
    // Return RMS (sqrt of mean of squares) to match MATLAB implementation
    return sqrt(sumOfSquares / buffer.length);
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
      double minNasalance, double standardDeviation, String? filePath) onFinishRecording;

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
  FlutterSoundRecorder? _fileRecorder = FlutterSoundRecorder(); // New recorder for file
  bool _mRecorderIsInited = false;
  bool _fileRecorderIsInited = false; // New flag for file recorder
  StreamSubscription<Uint8List>? _recordingSubscription;
  bool _isRecordingStarted =
      false; // A flag to indicate when actual recording starts

  double currentWindowSize =
      defaultWindowSize; // Set default window size (in seconds)

  // To accumulate waveform data for both channels
  List<double> accumulatedMic1Data = [];
  List<double> accumulatedMic2Data = [];

  // To store nasalance values (only for real-time display)
  List<double> nasalanceData = [];

  // Running statistics object to accumulate statistics across windows
  RunningStats nasalanceStats = RunningStats();

  // File recording variables
  String? _recordingFilePath;
  DateTime? _recordingStartTime;

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
    // Ensure recorders are properly closed
    if (_mRecorder != null) {
      _mRecorder!.closeRecorder();
      _mRecorder = null;
    }
    if (_fileRecorder != null && _fileRecorderIsInited) {
      _fileRecorder!.closeRecorder();
      _fileRecorder = null;
    }
    _recordingSubscription?.cancel();
    super.dispose();
  }

  Future<void> openTheRecorder() async {
    try {
      if (!kIsWeb) {
        var status = await Permission.microphone.request();
        if (status != PermissionStatus.granted) {
          throw RecordingPermissionException('Microphone permission not granted');
        }
        
        // Request storage permissions for Android
        if (Platform.isAndroid) {
          var storageStatus = await Permission.storage.request();
        if (storageStatus != PermissionStatus.granted) {
          // Storage permission not granted, using internal storage
        }
        }
      }
      
      // Initialize both recorders
      await _mRecorder!.openRecorder();
      await _fileRecorder!.openRecorder();
      
      _mRecorderIsInited = true;
      _fileRecorderIsInited = true;
      
      // Set up file path for recording
      await _setupRecordingFilePath();
      
    } catch (e) {
      // Fallback: initialize only the main recorder
      await _mRecorder!.openRecorder();
      _mRecorderIsInited = true;
      _fileRecorderIsInited = false; // Disable file recording if it fails
    }
  }


  Future<void> _setupRecordingFilePath() async {
    try {
      Directory directory;
      
      // Use external storage on Android for accessibility by other apps
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      } else {
        // Use internal storage for iOS (more secure)
        directory = await getApplicationDocumentsDirectory();
      }
      
      final now = DateTime.now();
      final formatted =
          '${now.year.toString().padLeft(4, '0')}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}';
      _recordingFilePath = '${directory.path}/nasometer_recording_$formatted.pcm';
    } catch (e) {
      // Error setting up recording file path
    }
  }

  void startRecording() async {
    if (!_mRecorderIsInited) return;

    try {
      // Start file recording first (only if file recorder is available)
      if (_fileRecorderIsInited && _recordingFilePath != null) {
        await _fileRecorder!.startRecorder(
          toFile: _recordingFilePath,
          codec: Codec.pcm16,
          audioSource: theSource,
          numChannels: 2,
          sampleRate: 44100, // Match original nasalance calculation
        );
        _recordingStartTime = DateTime.now();
      }

      // Start stream recording for real-time processing
      StreamController<Uint8List> recordingController =
          StreamController<Uint8List>();
      _recordingSubscription = recordingController.stream.listen((buffer) {
        if (_isRecordingStarted) {
          _processAudioBuffer(
              buffer); // Process audio only after the initial delay
        }
      });

      await _mRecorder!.startRecorder(
        toStream: recordingController.sink,
        codec: Codec.pcm16WAV,
        audioSource: theSource,
        numChannels: 2,
        sampleRate: 44100,
      );

      // Introduce a 5-second delay before actually starting to process audio
      await Future.delayed(const Duration(seconds: 5));

      // Mark the recording as fully started
      setState(() {
        _isRecordingStarted = true;
      });
    } catch (e) {
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        sampleRate: 44100,
        order: 2, // 2nd order Butterworth like MATLAB
      );

      // Use causal filtering to match MATLAB's filter() function (real-time feasible)
      List<double> filteredMic1Data = filter.apply(accumulatedMic1Data);
      List<double> filteredMic2Data = filter.apply(accumulatedMic2Data);

      NasalanceCalculator calculator = NasalanceCalculator(
        sampleRate: 44100,
        windowSize: widget.windowSize,
        noiseThreshold: widget.noiseThreshold,
      );

      // Use the new method that returns both nasalance and energy values
      Map<String, List<double>> resultsWithEnergy =
          calculator.calculateNasalanceWithEnergy(filteredMic1Data, filteredMic2Data);
      
      List<double> nasalanceResults = resultsWithEnergy['nasalance']!;
      List<double> energyResults = resultsWithEnergy['energy']!;

      // Update running statistics for each window, including energy values for MAD calculation
      for (int i = 0; i < nasalanceResults.length; i++) {
        double result = nasalanceResults[i];
        double energy = energyResults[i];
        nasalanceStats.addData(result, energy);
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
    try {
      // Stop both recorders
      await _mRecorder!.stopRecorder();
      if (_fileRecorderIsInited && _fileRecorder != null) {
        await _fileRecorder!.stopRecorder();
      }
      _recordingSubscription?.cancel();
      
      // Wait a moment for file handles to be released
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Force garbage collection to release file handles
      if (_fileRecorder != null) {
        _fileRecorder = null;
      }
    } catch (e) {
      // Handle any cleanup errors
    }

    if (!mounted) {
      return; // Guard against using context if the widget is not mounted
    }

    // Reset the recording state
    setState(() {
      _isRecordingStarted = false;
    });

    // Calculate recording duration
    Duration? recordingDuration;
    if (_recordingStartTime != null) {
      recordingDuration = DateTime.now().difference(_recordingStartTime!);
    }

    // Retrieve the final running statistics using MAD-based robust mean
    double averageNasalance = nasalanceStats.getRobustMean(); // Use MAD-based robust mean like MATLAB
    double maxNasalance = nasalanceStats.getMax();
    double minNasalance = nasalanceStats.getMin();
    double standardDeviation = nasalanceStats.getStandardDeviation();

    // Don't show recording result here anymore - let the user decide in SummaryPage
    // _showRecordingResult(recordingDuration);

    widget.onFinishRecording(
        averageNasalance, maxNasalance, minNasalance, standardDeviation, _recordingFilePath);
  }

  void _showRecordingResult(Duration? duration) {
    String message = '';
    if (duration != null) {
      if (duration.inSeconds >= 100) {
        message = 'Long recording completed successfully!\nDuration: ${duration.inSeconds} seconds\nFile: ${_recordingFilePath?.split('/').last}\n✅ App supports recordings up to 100+ seconds';
      } else {
        message = 'Recording saved successfully!  \nDuration: ${duration.inSeconds} seconds\nFile: ${_recordingFilePath?.split('/').last}';
      }
    } else {
      message = 'Recording completed but duration could not be calculated.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        backgroundColor: duration != null && duration.inSeconds >= 100 ? Colors.green : Colors.blue,
        action: SnackBarAction(
          label: 'Share',
          onPressed: () => _shareRecordingFile(),
        ),
      ),
    );
  }

  void _shareRecordingFile() {
    if (_recordingFilePath != null) {
      Share.shareXFiles([XFile(_recordingFilePath!)], text: 'Nasometer Recording');
    }
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
                      ? NasalanceGraphPainter(
                          nasalanceData, widget.nasalanceThreshold)
                      : NasalanceBarPainter(
                          nasalanceData, widget.nasalanceThreshold),
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

  // For MAD-based robust energy gating
  List<double> allNasalanceValues = [];
  List<double> allEnergyValues = [];

  void addData(double value, double energy) {
    // Store all values for MAD calculation
    allNasalanceValues.add(value);
    allEnergyValues.add(energy);
    
    // Only add non-zero values to simple statistics
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

  // MAD-based robust mean calculation (PANM-like)
  double getRobustMean() {
    if (allEnergyValues.isEmpty) return 0.0;
    
    // Calculate MAD-based threshold
    double kMAD = 2.5;
    double medianEnergy = _calculateMedian(allEnergyValues);
    double madEnergy = _calculateMAD(allEnergyValues);
    double threshold = medianEnergy + kMAD * madEnergy;
    
    // Find frames that pass the MAD threshold and have non-zero nasalance
    List<int> keepIndices = [];
    for (int i = 0; i < allEnergyValues.length; i++) {
      if (allEnergyValues[i] > threshold && allNasalanceValues[i] > 0) {
        keepIndices.add(i);
      }
    }
    
    // If no frames pass, use 60th percentile as fallback
    if (keepIndices.isEmpty) {
      double percentile60 = _calculatePercentile(allEnergyValues, 60);
      for (int i = 0; i < allEnergyValues.length; i++) {
        if (allEnergyValues[i] > percentile60 && allNasalanceValues[i] > 0) {
          keepIndices.add(i);
        }
      }
    }
    
    // Calculate mean of nasalance values for selected frames
    if (keepIndices.isNotEmpty) {
      double sum = 0.0;
      for (int idx in keepIndices) {
        sum += allNasalanceValues[idx];
      }
      double robustMean = sum / keepIndices.length;
      
      // Ensure robust mean is within min-max bounds
      double minVal = getMin();
      double maxVal = getMax();
      if (minVal > 0 && maxVal > 0) {
        robustMean = robustMean.clamp(minVal, maxVal);
      }
      
      return robustMean;
    }
    
    // If still no valid frames, return regular average of non-zero values
    return getAverage();
  }

  // Helper method to calculate median
  double _calculateMedian(List<double> values) {
    List<double> sorted = List.from(values)..sort();
    int n = sorted.length;
    if (n % 2 == 1) {
      return sorted[n ~/ 2];
    } else {
      return (sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2.0;
    }
  }

  // Helper method to calculate MAD (Median Absolute Deviation)
  double _calculateMAD(List<double> values) {
    double median = _calculateMedian(values);
    List<double> deviations = values.map((v) => (v - median).abs()).toList();
    return _calculateMedian(deviations);
  }

  // Helper method to calculate percentile
  double _calculatePercentile(List<double> values, double percentile) {
    List<double> sorted = List.from(values)..sort();
    double index = (percentile / 100.0) * (sorted.length - 1);
    int lower = index.floor();
    int upper = index.ceil();
    
    if (lower == upper) {
      return sorted[lower];
    } else {
      double weight = index - lower;
      return sorted[lower] * (1 - weight) + sorted[upper] * weight;
    }
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

class SummaryPage extends StatefulWidget {
  final double averageNasalance;
  final double maxNasalance;
  final double minNasalance;
  final double standardDeviation;
  final String? recordingFilePath;

  const SummaryPage({
    super.key,
    required this.averageNasalance,
    required this.maxNasalance,
    required this.minNasalance,
    required this.standardDeviation,
    required this.recordingFilePath,
  });

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  bool _fileSaved = false;
  late TextEditingController _fileNameController;
  late String _originalFileName;
  late String _directoryPath;

  @override
  void initState() {
    super.initState();
    // Extract original filename and directory from full path
    if (widget.recordingFilePath != null) {
      String fullPath = widget.recordingFilePath!;
      _directoryPath = fullPath.substring(0, fullPath.lastIndexOf('/'));
      _originalFileName = fullPath.substring(fullPath.lastIndexOf('/') + 1);
      // Remove extension for editing
      _originalFileName = _originalFileName.replaceAll('.pcm', '');
      _fileNameController = TextEditingController(text: _originalFileName);
    } else {
      _originalFileName = 'nasometer_recording';
      _directoryPath = '';
      _fileNameController = TextEditingController(text: _originalFileName);
    }
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  void _deleteRecording() async {
    if (widget.recordingFilePath != null) {
      try {
        File file = File(widget.recordingFilePath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Error deleting file
      }
    }
  }

  Future<void> _renameRecordingFile() async {
    if (widget.recordingFilePath != null) {
      try {
        String newFileName = _fileNameController.text.trim();
        // Use original filename if user didn't provide one
        if (newFileName.isEmpty) {
          newFileName = _originalFileName;
        }
        // Ensure we have .pcm extension
        if (!newFileName.endsWith('.pcm')) {
          newFileName += '.pcm';
        }
        
        String newFilePath = '$_directoryPath/$newFileName';
        File oldFile = File(widget.recordingFilePath!);
        
        if (await oldFile.exists()) {
          await oldFile.rename(newFilePath);
        }
      } catch (e) {
        // Error renaming file
      }
    }
  }

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
                'Average Nasalance: ${widget.averageNasalance.toStringAsFixed(2)}%',
                style: const TextStyle(fontSize: 20),
              ),
              Text(
                'Max Nasalance: ${widget.maxNasalance.toStringAsFixed(2)}%',
                style: const TextStyle(fontSize: 20),
              ),
              Text(
                'Min Nasalance: ${widget.minNasalance.toStringAsFixed(2)}%',
                style: const TextStyle(fontSize: 20),
              ),
              Text(
                'Standard Deviation: ${widget.standardDeviation.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 30),
              if (!_fileSaved) ...[
                const Text(
                  'Choose what to do with the recording:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _fileNameController,
                  decoration: const InputDecoration(
                    labelText: 'File Name (optional)',
                    hintText: 'Leave empty to use default name',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 20),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          // Determine the final filename
                          String finalFileName = _fileNameController.text.trim();
                          if (finalFileName.isEmpty) {
                            finalFileName = _originalFileName;
                          }
                          if (!finalFileName.endsWith('.pcm')) {
                            finalFileName += '.pcm';
                          }
                          
                          await _renameRecordingFile();
                          setState(() {
                            _fileSaved = true;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Recording saved as: $finalFileName'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Save Recording'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          _deleteRecording();
                          setState(() {
                            _fileSaved = true;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Recording discarded'),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Discard'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Navigate back to the settings page
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
