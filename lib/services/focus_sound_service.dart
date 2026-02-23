import 'package:just_audio/just_audio.dart';

class FocusSoundService {
  static final FocusSoundService _instance = FocusSoundService._internal();
  factory FocusSoundService() => _instance;
  FocusSoundService._internal();

  final AudioPlayer _player = AudioPlayer();
  String? _currentSound;

  final Map<String, String> sounds = {
    'Rain': 'https://assets.mixkit.co/active_storage/sfx/2357/2357-preview.mp3',
    'White Noise':
        'https://assets.mixkit.co/active_storage/sfx/2358/2358-preview.mp3',
    'Library':
        'https://assets.mixkit.co/active_storage/sfx/2359/2359-preview.mp3',
    'Brown Noise':
        'https://assets.mixkit.co/active_storage/sfx/2360/2360-preview.mp3',
  };

  Future<void> playSound(String soundName) async {
    if (_currentSound == soundName) {
      await stop();
      _currentSound = null;
      return;
    }

    final url = sounds[soundName];
    if (url != null) {
      try {
        await _player.setUrl(url);
        await _player.setLoopMode(LoopMode.one);
        _player.play();
        _currentSound = soundName;
      } catch (e) {
        print("Error playing sound: $e");
      }
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _currentSound = null;
  }

  String? get currentSound => _currentSound;
  bool get isPlaying => _player.playing;

  void dispose() {
    _player.dispose();
  }
}
