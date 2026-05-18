import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../welcome/widgets/background_glow.dart';

class CameraRecordScreen extends StatefulWidget {
  const CameraRecordScreen({super.key});

  @override
  State<CameraRecordScreen> createState() => _CameraRecordScreenState();
}

class _CameraRecordScreenState extends State<CameraRecordScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];

  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isInitializing = true;
  bool _isRecording = false;
  bool _isCountingDown = false;
  bool _isMusicEnabled = true;

  int _countdown = 3;
  int _recordingSeconds = 0;

  Timer? _recordingTimer;
  StreamSubscription<void>? _audioCompleteSubscription;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        throw Exception('No camera found');
      }

      final backCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.low,
        enableAudio: true,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        _isInitializing = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isInitializing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the camera.'),
        ),
      );
    }
  }

  Future<void> _startCountdownAndRecording() async {
    if (_cameraController == null) return;
    if (!_cameraController!.value.isInitialized) return;
    if (_isRecording || _isCountingDown) return;

    setState(() {
      _isCountingDown = true;
      _countdown = 3;
    });

    for (int i = 3; i >= 1; i--) {
      if (!mounted) return;

      setState(() {
        _countdown = i;
      });

      await Future.delayed(const Duration(seconds: 1));
    }

    if (!mounted) return;

    setState(() {
      _isCountingDown = false;
    });

    await _startRecording();
  }

  Future<void> _startRecording() async {
  if (_cameraController == null) return;
  if (!_cameraController!.value.isInitialized) return;

  try {
    await _cameraController!.startVideoRecording();

    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
    });

    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() {
        _recordingSeconds++;
      });
    });

    if (_isMusicEnabled) {
      await _audioPlayer.stop();

      _audioCompleteSubscription?.cancel();

      _audioCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) async {
        await Future.delayed(const Duration(seconds: 2));

        if (!mounted) return;
        if (!_isRecording) return;
        if (_cameraController == null) return;
        if (!_cameraController!.value.isRecordingVideo) return;

        await _stopRecording();
      });

      await _audioPlayer.play(
        AssetSource('audio/dance_beat_house.mp3'),
        position: const Duration(seconds: 8),
      );
    }
  } catch (_) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not start recording.'),
      ),
    );
  }
}

  Future<void> _stopRecording() async {
  if (_cameraController == null) return;
  if (!_cameraController!.value.isRecordingVideo) return;

  try {
    _recordingTimer?.cancel();
    _audioCompleteSubscription?.cancel();
    _audioCompleteSubscription = null;

    await _audioPlayer.stop();

    final XFile recordedFile = await _cameraController!.stopVideoRecording();

    if (!mounted) return;

    setState(() {
      _isRecording = false;
    });

    Navigator.pop(context, recordedFile);
  } catch (_) {
    if (!mounted) return;

    setState(() {
      _isRecording = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not stop recording.'),
      ),
    );
  }
}

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    if (_cameraController == null) return;
    if (_isRecording || _isCountingDown) return;

    final currentCamera = _cameraController!.description;

    final newCamera = _cameras.firstWhere(
      (camera) => camera.lensDirection != currentCamera.lensDirection,
      orElse: () => _cameras.first,
    );

    setState(() {
      _isInitializing = true;
    });

    await _cameraController!.dispose();

    _cameraController = CameraController(
      newCamera,
      ResolutionPreset.low,
      enableAudio: true,
    );

    await _cameraController!.initialize();

    if (!mounted) return;

    setState(() {
      _isInitializing = false;
    });
  }

  String _formatRecordingTime() {
    final minutes = (_recordingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_recordingSeconds % 60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  @override
void dispose() {
  _recordingTimer?.cancel();
  _audioCompleteSubscription?.cancel();
  _audioPlayer.stop();
  _audioPlayer.dispose();
  _cameraController?.dispose();
  super.dispose();
}

  @override
  Widget build(BuildContext context) {
    final cameraController = _cameraController;

    return Scaffold(
      body: Stack(
        children: [
          const BackgroundGlow(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: _isRecording || _isCountingDown
                            ? null
                            : () {
                                Navigator.pop(context);
                              },
                        style: IconButton.styleFrom(
                          backgroundColor:
                              AppColors.surface.withValues(alpha: 0.78),
                          padding: const EdgeInsets.all(12),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textPrimary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          _isRecording
                              ? 'Recording ${_formatRecordingTime()}'
                              : 'Record your dance',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed:
                            _isRecording || _isCountingDown ? null : _switchCamera,
                        style: IconButton.styleFrom(
                          backgroundColor:
                              AppColors.surface.withValues(alpha: 0.78),
                          padding: const EdgeInsets.all(12),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        icon: const Icon(
                          Icons.cameraswitch_rounded,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: _isInitializing ||
                                cameraController == null ||
                                !cameraController.value.isInitialized
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.secondary,
                                ),
                              )
                            : Stack(
                                fit: StackFit.expand,
                                children: [
                                  CameraPreview(cameraController),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black.withValues(alpha: 0.18),
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.38),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (_isCountingDown)
                                    Center(
                                      child: Text(
                                        _countdown.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 110,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  if (_isRecording)
                                    Positioned(
                                      top: 18,
                                      left: 18,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(alpha: 0.85),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _formatRecordingTime(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    left: 18,
                                    right: 18,
                                    bottom: 18,
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.black.withValues(alpha: 0.35),
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                      child: const Text(
                                        'Keep your full body visible and stay inside the frame.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          height: 1.4,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isRecording || _isCountingDown
                              ? null
                              : () {
                                  setState(() {
                                    _isMusicEnabled = !_isMusicEnabled;
                                  });
                                },
                          icon: Icon(
                            _isMusicEnabled
                                ? Icons.music_note_rounded
                                : Icons.music_off_rounded,
                          ),
                          label: Text(
                            _isMusicEnabled ? 'Music On' : 'Music Off',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            backgroundColor:
                                AppColors.surface.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isCountingDown
                              ? null
                              : _isRecording
                                  ? _stopRecording
                                  : _startCountdownAndRecording,
                          icon: Icon(
                            _isRecording
                                ? Icons.stop_rounded
                                : Icons.fiber_manual_record_rounded,
                          ),
                          label: Text(
                            _isRecording ? 'Stop' : 'Start',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isRecording ? Colors.red : AppColors.primary,
                            foregroundColor: AppColors.textPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}