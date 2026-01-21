# Nasometer

A Flutter mobile application for real-time nasalance measurement and analysis. Nasalance is the ratio of nasal acoustic energy to total (nasal + oral) acoustic energy, expressed as a percentage. This tool is useful for speech therapy, voice analysis, and research applications.

## Features

- **Real-time Nasalance Measurement**: Continuously calculates and displays nasalance percentage from dual-microphone audio input
- **Dual Display Modes**:
  - **Contour Mode**: Line graph showing nasalance values over time
  - **Bar Mode**: Real-time bar chart displaying the current nasalance value
- **Configurable FIR Bandpass Filter**: Customizable frequency range (default: 80-1000 Hz) with Hann windowing
- **Adjustable Parameters**:
  - Low and high cutoff frequencies
  - Noise threshold for energy gating
  - Analysis window size
  - Nasalance threshold for visual feedback
- **Statistical Analysis**: Displays average, maximum, minimum, and standard deviation of nasalance values
- **Cross-platform**: Supports both Android and iOS

## Technical Details

### Audio Processing

- **Sample Rate**: 44.1 kHz
- **Audio Format**: PCM16, 2 channels (stereo)
- **Filter Type**: FIR (Finite Impulse Response) bandpass filter with Hann window
- **Filter Design**: Windowed sinc method for bandpass filtering
- **Window Function**: Hann (Hanning) window
- **Processing**: Real-time causal filtering suitable for live audio processing

### Nasalance Calculation

The nasalance percentage is calculated using the formula:

```
Nasalance (%) = 100 × (Nasal Energy) / (Nasal Energy + Oral Energy)
```

- Energy is calculated as the sum of squared sample values within each analysis window
- Values below the noise threshold are excluded from calculations
- Analysis windows use 50% overlap for smoother results

## Requirements

- Flutter SDK >= 3.4.4
- Dart SDK >= 3.4.4
- Android Studio / Xcode (for platform-specific builds)
- Microphone permissions (automatically requested)

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/nasometer.git
cd nasometer
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
flutter run
```

## Usage

1. **Configure Settings**: Adjust filter parameters, noise threshold, window size, and display mode on the settings page
2. **Start Recording**: Tap "Start Recording" to begin audio capture and real-time analysis
3. **View Results**: Observe the real-time nasalance graph or bar chart
4. **Stop Recording**: Tap "Stop Recording" to end the session
5. **Review Statistics**: View the summary page with calculated statistics

### Default Settings

- **Low Cutoff Frequency**: 80 Hz
- **High Cutoff Frequency**: 1000 Hz
- **Noise Threshold**: 0.008
- **Window Size**: 0.05 seconds (50 ms)
- **Nasalance Threshold**: 50%

### Parameter Constraints

- Low Cutoff: 20-200 Hz
- High Cutoff: 800-3000 Hz
- Noise Threshold: 0.0-1.0
- Window Size: 0.01-0.08 seconds
- Nasalance Threshold: 0-100%

## Project Structure

```
nasometer/
├── lib/
│   └── main.dart          # Main application code
├── android/               # Android-specific configuration
├── ios/                   # iOS-specific configuration
├── assets/                # App icons and resources
├── pubspec.yaml          # Dependencies and project configuration
└── README.md             # This file
```

## Dependencies

- `flutter_sound`: Audio recording and playback
- `permission_handler`: Microphone permission management
- `shared_preferences`: Settings persistence
- `flutter_sound_platform_interface`: Audio platform interface

## Architecture

### Key Components

- **BandpassFilter**: Implements FIR bandpass filtering using windowed sinc method
- **NasalanceCalculator**: Calculates nasalance percentages from filtered audio signals
- **RunningStats**: Manages running statistics for nasalance data
- **SettingsPage**: Configuration interface for filter parameters
- **SimpleRecorder**: Real-time recording and visualization page
- **SummaryPage**: Results summary with statistical analysis

## Development

### Building for Release

**Android:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

## License

[Specify your license here]

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Acknowledgments

This project implements nasalance measurement algorithms commonly used in speech pathology and voice analysis research.

## Contact

[Your contact information]
