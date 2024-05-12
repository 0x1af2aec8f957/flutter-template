import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../utils/common.dart';
import './MusicPlayLoading.dart';

/// 音频播放所需权限：https://github.com/ryanheise/just_audio/tree/minor/just_audio#platform-specific-configuration

class CustomAudio extends StatefulWidget {
  final String url;
  final double? width;
  final double radius;
  final Color? backgroundColor;
  final Map<String, String> headers;

  CustomAudio({
    super.key,
    required this.url,
    this.width,
    this.radius = 4,
    this.backgroundColor,
    this.headers = const <String, String>{},
  });

  @override
  State<CustomAudio> createState() => _CustomAudio();
}

class _CustomAudio extends State<CustomAudio> {
  final player = AudioPlayer();
  late final audioSource = LockCachingAudioSource(Uri.parse(widget.url), headers: widget.headers);

  Duration? audioDuration;
  bool get isValidAbsoluteUrl => Uri.parse(widget.url).isAbsolute;
  bool get isValidFileUrl => !isValidAbsoluteUrl || Uri.parse(widget.url).isScheme('FILE');
  bool get isValidAssetUrl => isValidFileUrl && widget.url.startsWith('assets/');

  Future<Duration?> handleInitAudioSource() { // 切换播放状态
    if (isValidAssetUrl) {
      return player.setAsset(widget.url);
    }

    if (isValidFileUrl) {
      return player.setFilePath(widget.url);
    }

    // return player.setUrl(widget.url, headers: widget.headers);
    return player.setAudioSource(audioSource);
  }

  Future<void> handleCheckPlayState() async { // 切换播放状态
    player.seek(Duration.zero)/* 重置播放时间 */.then((_) => setState(() {
      if (player.playing) {
       player.pause();
       return;
      }

      player.play().then((_) => player.stop());
    }));
  }

  @override
  void initState() {
    super.initState();
    handleInitAudioSource().then((Duration? _duration) => setState(() {
      audioDuration = _duration;
    }));
  }

  @override
  Widget build(BuildContext context) {

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: Container(
        width: widget.width,
        color: widget.backgroundColor,
        child: StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (_, snapshot) {
            final PlayerState? playState = snapshot.data;
            if (playState?.processingState == ProcessingState.loading) return SizedBox.square(dimension: 5, child: CircularProgressIndicator());

            return Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  color: Colors.white,
                  icon: Icon(playState?.playing == true ? Icons.pause : Icons.play_arrow, color: Colors.black),
                  onPressed: handleCheckPlayState,
                ),
               playState?.playing == true ? MusicPlayLoading(color: Colors.white) : Text("${audioDuration?.inSeconds ?? StringHelper.placeholder} ''", style: TextStyle(color: Colors.white)),
              ]
            );
          }
        ),
      ),
    );
  }

  @override
  void dispose() {
    // audioSource.clearCache();
    player..stop()..dispose();
    super.dispose();
  }
}