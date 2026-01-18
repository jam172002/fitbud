import 'dart:io';
import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:video_player/video_player.dart';

class FullScreenMedia extends StatefulWidget {
  final String path;
  final bool isVideo;

  /// Only needed for local bundled assets (assets/...).
  /// Network URLs should NOT use isAsset.
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

  bool get _isNetwork =>
      widget.path.startsWith('http://') || widget.path.startsWith('https://');

  @override
  void initState() {
    super.initState();

    if (widget.isVideo) {
      if (_isNetwork) {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.path))
          ..initialize().then((_) {
            if (!mounted) return;
            setState(() {});
            _videoController!.play();
          });
      } else if (widget.isAsset) {
        _videoController = VideoPlayerController.asset(widget.path)
          ..initialize().then((_) {
            if (!mounted) return;
            setState(() {});
            _videoController!.play();
          });
      } else {
        _videoController = VideoPlayerController.file(File(widget.path))
          ..initialize().then((_) {
            if (!mounted) return;
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

  Widget _buildImage() {
    if (_isNetwork) {
      return InteractiveViewer(
        minScale: 0.8,
        maxScale: 4.0,
        child: Image.network(
          widget.path,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stack) {
            return const Center(
              child: Text(
                'Failed to load image',
                style: TextStyle(color: Colors.white70),
              ),
            );
          },
        ),
      );
    }

    if (widget.isAsset) {
      return InteractiveViewer(
        minScale: 0.8,
        maxScale: 4.0,
        child: Image.asset(widget.path, fit: BoxFit.contain),
      );
    }

    return InteractiveViewer(
      minScale: 0.8,
      maxScale: 4.0,
      child: Image.file(File(widget.path), fit: BoxFit.contain),
    );
  }

  Widget _buildVideo() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: widget.isVideo ? _buildVideo() : _buildImage()),

          // BACK BUTTON
          Positioned(
            top: 40,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(
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
