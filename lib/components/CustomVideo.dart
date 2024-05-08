import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// 视频播放所需权限：https://github.com/flutter/packages/tree/main/packages/video_player/video_player#installation
/// 缓存进度：https://github.com/flutter/flutter/issues/28094

class CustomVideo extends StatefulWidget {
  final String url;
  final double? width;
  final double radius;
  final Map<String, String> headers;
  VideoPlayerOptions? videoPlayerOptions;

  CustomVideo({
    super.key,
    required this.url,
    this.width,
    this.radius = 4,
    this.headers = const <String, String>{},
    this.videoPlayerOptions,
  });

  @override
  State<CustomVideo> createState() => _CustomVideo();
}

class _CustomVideo extends State<CustomVideo> {
  late final VideoPlayerController controller = isValidAssetUrl ? VideoPlayerController.asset(
    widget.url,
    videoPlayerOptions: widget.videoPlayerOptions
  ) : isValidFileUrl ? VideoPlayerController.file(
    File(widget.url),
    videoPlayerOptions: widget.videoPlayerOptions
  ) : VideoPlayerController.networkUrl(
    Uri.parse(widget.url),
    httpHeaders: widget.headers,
    videoPlayerOptions: widget.videoPlayerOptions
  )/* ..initialize().then((_) {
    // 确保在视频初始化后，按下播放按钮之前显示第一帧
    setState(() {});
  }) */;

  bool get isValidAbsoluteUrl => Uri.parse(widget.url).isAbsolute;
  bool get isValidFileUrl => !isValidAbsoluteUrl || Uri.parse(widget.url).isScheme('FILE');
  bool get isValidAssetUrl => isValidFileUrl && widget.url.startsWith('assets/');

  void handleCheckPlayState() { // 切换播放状态
    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
        return;
      }

      controller.play();
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: SizedBox(
        width: widget.width,
        child: FutureBuilder(
          future: controller.initialize(),
          builder: (_, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return Center(child: CircularProgressIndicator());
        
            return Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
                Positioned(
                  child: IconButton(
                    onPressed: handleCheckPlayState,
                    icon: Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
                  )
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}