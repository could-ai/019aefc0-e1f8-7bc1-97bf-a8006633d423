import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceChangerScreen extends StatefulWidget {
  const VoiceChangerScreen({super.key});

  @override
  State<VoiceChangerScreen> createState() => _VoiceChangerScreenState();
}

class _VoiceChangerScreenState extends State<VoiceChangerScreen> {
  late AudioRecorder _audioRecorder;
  late AudioPlayer _audioPlayer;
  String? _recordedPath;
  bool _isRecording = false;
  bool _isPlaying = false;
  
  // Efekt listesi
  final List<Map<String, dynamic>> _effects = [
    {'name': 'Normal', 'rate': 1.0, 'icon': Icons.person},
    {'name': 'Helyum', 'rate': 1.5, 'icon': Icons.air}, // Yüksek perde/hız
    {'name': 'Dev', 'rate': 0.7, 'icon': Icons.accessibility_new}, // Düşük perde/hız
    {'name': 'Sincap', 'rate': 2.0, 'icon': Icons.pets}, // Çok yüksek hız
    {'name': 'Ağır Çekim', 'rate': 0.5, 'icon': Icons.speed}, // Çok yavaş
  ];

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _audioPlayer = AudioPlayer();

    // Oynatma bittiğinde durumu güncelle
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
      });
    });
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      // İzinleri kontrol et
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mikrofon izni gerekli!')),
          );
        }
        return;
      }

      // Kayıt dosya yolunu hazırla
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/my_voice_recording.m4a';

      // Kaydı başlat
      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() {
          _isRecording = true;
          _recordedPath = null; // Yeni kayıt başladığında eski yolu temizle
        });
      }
    } catch (e) {
      debugPrint('Kayıt hatası: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _recordedPath = path;
      });
    } catch (e) {
      debugPrint('Durdurma hatası: $e');
    }
  }

  Future<void> _playRecording(double rate) async {
    if (_recordedPath == null) return;

    try {
      // Eğer zaten çalıyorsa durdur
      await _audioPlayer.stop();

      // Dosya kaynağını ayarla
      await _audioPlayer.setSourceDeviceFile(_recordedPath!);
      
      // Hızı (ve dolaylı olarak perdeyi) ayarla
      await _audioPlayer.setPlaybackRate(rate);
      
      // Oynat
      await _audioPlayer.resume();
      
      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      debugPrint('Oynatma hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Oynatma hatası: $e')),
        );
      }
    }
  }

  Future<void> _stopPlayback() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ses Değiştirici'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          // Kayıt Durumu Göstergesi
          Container(
            height: 150,
            width: 150,
            decoration: BoxDecoration(
              color: _isRecording ? Colors.red.shade100 : Colors.grey.shade200,
              shape: BoxShape.circle,
              border: Border.all(
                color: _isRecording ? Colors.red : Colors.grey,
                width: 4,
              ),
            ),
            child: Icon(
              _isRecording ? Icons.mic : Icons.mic_none,
              size: 80,
              color: _isRecording ? Colors.red : Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _isRecording 
              ? 'Kaydediliyor...' 
              : (_recordedPath != null ? 'Kayıt Hazır!' : 'Kaydetmek için basılı tutun'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 30),
          
          // Kayıt Butonu
          GestureDetector(
            onLongPressStart: (_) => _startRecording(),
            onLongPressEnd: (_) => _stopRecording(),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(Icons.fiber_manual_record, color: Colors.white, size: 40),
            ),
          ),
          const SizedBox(height: 10),
          const Text('Basılı Tutarak Kaydet', style: TextStyle(color: Colors.grey)),
          
          const Divider(height: 50),
          
          // Efekt Listesi
          Expanded(
            child: _recordedPath == null
                ? const Center(child: Text('Önce bir ses kaydedin'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _effects.length,
                    itemBuilder: (context, index) {
                      final effect = _effects[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Icon(effect['icon'], size: 32, color: Colors.deepPurple),
                          title: Text(effect['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Hız: ${effect['rate']}x'),
                          trailing: IconButton(
                            icon: const Icon(Icons.play_circle_fill, size: 40, color: Colors.green),
                            onPressed: () => _playRecording(effect['rate']),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          if (_isPlaying)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _stopPlayback,
                icon: const Icon(Icons.stop),
                label: const Text('Oynatmayı Durdur'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
