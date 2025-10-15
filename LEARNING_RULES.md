# Learning Rules for Nasometer Flutter Project

## Project Overview
This is a Flutter application called "Nasometer" that measures nasalance (nasal resonance) in real-time using audio processing. The app records audio from two microphones, applies bandpass filtering, and calculates nasalance percentages.

## Project Structure
```
nasometer/
├── lib/
│   └── main.dart          # Main application file with all classes
├── assets/
│   └── icon/
│       └── app_icon.png   # App icon
├── android/               # Android-specific configuration
├── ios/                   # iOS-specific configuration
├── pubspec.yaml          # Dependencies and project configuration
└── README.md             # Project documentation
```

## Key Components

### 1. Audio Processing Classes
- **BandpassFilter**: Implements FIR bandpass filtering for audio signals
- **NasalanceCalculator**: Calculates nasalance percentages from filtered audio
- **RunningStats**: Manages running statistics for nasalance data

### 2. UI Components
- **SettingsPage**: Configuration page for filter parameters
- **SimpleRecorder**: Real-time recording and display page
- **SummaryPage**: Results summary after recording
- **NasalanceGraphPainter**: Custom painter for contour mode display
- **NasalanceBarPainter**: Custom painter for bar mode display

### 3. Core Features
- Real-time audio recording from dual microphones
- Configurable bandpass filtering (low/high cutoff frequencies)
- Adjustable noise threshold and window size
- Two display modes: Contour Mode and Bar Mode
- Nasalance threshold for visual feedback
- Statistics calculation (average, max, min, standard deviation)
- **File Recording**: Saves stereo WAV files to device storage
- **Duration Support**: Accepts any recording duration (10 seconds to 100+ seconds)
- **File Accessibility**: Android saves to external storage for app accessibility
- **File Sharing**: Share recorded WAV files with other apps

## Coding Conventions

### 1. File Organization
- All code is currently in `lib/main.dart` (single file architecture)
- Consider refactoring into separate files for better maintainability

### 2. Naming Conventions
- Use camelCase for variables and methods
- Use PascalCase for class names
- Use descriptive names that reflect functionality

### 3. Audio Processing Rules
- Sample rate: 44100 Hz (original setting)
- Audio format: PCM16, 2 channels
- Buffer size: 8192 samples
- Window overlap: 50% for nasalance calculation

### 4. UI/UX Guidelines
- Use Material Design components
- Provide clear labels and hints for input fields
- Include validation and clamping for numerical inputs
- Show real-time feedback during recording
- Display comprehensive statistics in summary

## Dependencies
Key packages used:
- `flutter_sound`: Audio recording and playback
- `permission_handler`: Microphone permissions
- `shared_preferences`: Settings persistence
- `flutter_sound_platform_interface`: Audio platform interface
- `path_provider`: Device storage access for file recording
- `share_plus`: File sharing with other apps

## Configuration Parameters

### Default Values
- Low cutoff frequency: 80 Hz
- High cutoff frequency: 1000 Hz
- Noise threshold: 0.008
- Window size: 0.05 seconds (50ms)
- Nasalance threshold: 50.0%

### Constraints
- Low cutoff: 20-200 Hz
- High cutoff: 800-3000 Hz
- Noise threshold: 0.0-1.0
- Window size: 0.01-0.08 seconds
- Nasalance threshold: 0-100%

## Development Guidelines

### 1. Audio Processing
- Always validate audio buffer sizes before processing
- Handle edge cases for empty or invalid audio data
- Use appropriate error handling for audio operations
- Consider performance implications of real-time processing

### 2. UI Development
- Ensure responsive design for different screen sizes
- Provide clear visual feedback for user actions
- Implement proper state management for recording states
- Handle permission requests gracefully

### 3. Data Management
- Persist user settings using SharedPreferences
- Validate and clamp input values within acceptable ranges
- Provide meaningful default values
- Handle data persistence errors gracefully

### 4. Testing Considerations
- Test with various audio input qualities
- Verify filter performance across frequency ranges
- Test permission handling on different devices
- Validate statistics calculations with known data

## Platform-Specific Notes

### Android
- Requires microphone permission
- Uses Android-specific audio configuration
- Test on various Android versions and devices

### iOS
- Requires microphone permission
- Uses iOS-specific audio configuration
- Consider background audio limitations

### Web
- Limited audio capabilities
- May require different audio processing approach
- Test browser compatibility

## Future Improvements
1. **Code Organization**: Split main.dart into separate files
2. **State Management**: Implement proper state management (Provider/Bloc)
3. **Audio Processing**: Optimize real-time processing performance
4. **UI Enhancement**: Add more visualization options
5. **Data Export**: Add ability to export results
6. **Calibration**: Add audio calibration features
7. **Accessibility**: Improve accessibility features

## Common Issues and Solutions

### 1. Audio Recording Issues
- Check microphone permissions
- Verify audio source configuration
- Ensure proper buffer handling

### 2. Performance Issues
- Monitor real-time processing overhead
- Optimize filter calculations
- Consider reducing update frequency if needed

### 3. UI Responsiveness
- Use appropriate async operations
- Avoid blocking UI thread with heavy computations
- Implement proper loading states

## Security and Privacy
- Only request necessary permissions
- Handle audio data securely
- Don't store sensitive audio data unnecessarily
- Follow platform-specific privacy guidelines

## Documentation Standards
- Comment complex audio processing algorithms
- Document filter parameters and their effects
- Explain nasalance calculation methodology
- Provide usage instructions for end users

---

**Note**: This learning rules file should be updated as the project evolves. Keep it current with any architectural changes, new features, or modified requirements. 