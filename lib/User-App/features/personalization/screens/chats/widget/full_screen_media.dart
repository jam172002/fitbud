import 'dart:io';
import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:video_player/video_player.dart';

class FullScreenMedia extends StatefulWidget {
  final String path;
  final bool isVideo;
  final bool isAsset;

  const FullScreenMedia({
    super.key,
    required this.path,
    required this.isVideo,
    this.isAsset = false,
  });

  @override
  State<FullScreenMedia> createState() => _FullScreenMediaState();
}

class _FullScreenMediaState extends State<FullScreenMedia> {
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();

    if (widget.isVideo) {
      if (widget.isAsset) {
        // If ever needed in future
        _videoController = VideoPlayerController.asset(widget.path)
          ..initialize().then((_) {
            setState(() {});
            _videoController!.play();
          });
      } else {
        _videoController = VideoPlayerController.file(File(widget.path))
          ..initialize().then((_) {
            setState(() {});
            _videoController!.play();
          });
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: widget.isVideo
                ? (_videoController != null &&
                          _videoController!.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        )
                      : const CircularProgressIndicator())
                : widget.isAsset
                ? Image.asset(widget.path, fit: BoxFit.contain)
                : Image.file(File(widget.path), fit: BoxFit.contain),
          ),

          // BACK BUTTON
          Positioned(
            top: 40,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(
                LucideIcons.chevron_left,
                color: XColors.primary,
                size: 25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
