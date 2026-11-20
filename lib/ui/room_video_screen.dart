import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/touch_up.dart';
import '../logic/video_moments.dart';
import '../storage/photo_store.dart';
import 'photo_annotator.dart';
import 'theme.dart';

/// Vidéo relue à l'écran : lecture, pause, position. Remplaçable dans les tests.
abstract class RoomVideo implements Listenable {
  Future<void> initialize();
  Widget view();
  Duration get position;
  Duration get length;
  bool get playing;
  Future<void> play();
  Future<void> pause();
  Future<void> seekTo(Duration pAt);
  void dispose();
}

/// Vidéo lue par le lecteur du téléphone.
class PlayerRoomVideo extends ChangeNotifier implements RoomVideo {
  PlayerRoomVideo(String pPath)
    : _controller = kIsWeb
          ? VideoPlayerController.networkUrl(Uri.parse(pPath))
          : VideoPlayerController.file(File(pPath)) {
    _controller.addListener(notifyListeners);
  }

  final VideoPlayerController _controller;

  @override
  Future<void> initialize() => _controller.initialize();

  @override
  Widget view() => AspectRatio(
    aspectRatio: _controller.value.aspectRatio,
    child: VideoPlayer(_controller),
  );

  @override
  Duration get position => _controller.value.position;

  @override
  Duration get length => _controller.value.duration;

  @override
  bool get playing => _controller.value.isPlaying;

  @override
  Future<void> play() => _controller.play();

  @override
  Future<void> pause() => _controller.pause();

  @override
  Future<void> seekTo(Duration pAt) => _controller.seekTo(pAt);

  @override
  void dispose() {
    _controller.removeListener(notifyListeners);
    _controller.dispose();
    super.dispose();
  }
}

/// Image de la vidéo [pVideo] à [pAt], en JPEG ; null si elle n'a pas pu être lue.
typedef FrameGrabber = Future<Uint8List?> Function(String pVideo, Duration pAt);

Future<Uint8List?> grabFrame(String pVideo, Duration pAt) async {
  Uint8List? rFrame;
  try {
    rFrame = await VideoThumbnail.thumbnailData(
      video: pVideo,
      imageFormat: ImageFormat.JPEG,
      timeMs: pAt.inMilliseconds,
      maxWidth: 1600,
      quality: 75,
    );
  } on Exception {
    rFrame = null;
  }

  return rFrame;
}

/// Filme la pièce avec l'appareil du téléphone, puis ouvre la relecture ; renvoie les
/// reprises repérées, ou null si rien n'a été filmé.
Future<List<TouchUp>?> filmRoom(BuildContext pContext) async {
  final vVideo = await ImagePicker().pickVideo(
    source: ImageSource.camera,
    maxDuration: const Duration(minutes: 3),
  );
  if (vVideo == null || !pContext.mounted) {
    return null;
  }

  return Navigator.push<List<TouchUp>>(
    pContext,
    MaterialPageRoute(
      builder: (_) => RoomVideoScreen(videoPath: vVideo.path, video: PlayerRoomVideo(vVideo.path)),
    ),
  );
}

/// Relecture de la vidéo d'une pièce : à chaque défaut vu, « Repérer ici » garde l'image,
/// on y entoure ce qu'il faut reprendre, et chaque moment devient une reprise.
class RoomVideoScreen extends StatefulWidget {
  const RoomVideoScreen({
    super.key,
    required this.videoPath,
    required this.video,
    this.grab = grabFrame,
    this.annotate = annotatePhoto,
    this.keep = keepPhoto,
  });

  final String videoPath;
  final RoomVideo video;
  final FrameGrabber grab;
  final Future<List<PhotoMark>?> Function(BuildContext, String, List<PhotoMark>) annotate;
  final Future<String> Function(String pName, List<int> pBytes) keep;

  @override
  State<RoomVideoScreen> createState() => _RoomVideoScreenState();
}

class _RoomVideoScreenState extends State<RoomVideoScreen> {
  late final Future<void> _ready = widget.video.initialize();
  final _moments = <VideoMoment>[];
  bool _busy = false;
  bool _failed = false;

  @override
  void dispose() {
    widget.video.dispose();
    super.dispose();
  }

  Future<void> _mark() async {
    final vText = AppLocalizations.of(context);
    await widget.video.pause();
    final vAt = widget.video.position;
    setState(() {
      _busy = true;
      _failed = false;
    });
    final vFrame = await widget.grab(widget.videoPath, vAt);
    if (!mounted) {
      return;
    }
    if (vFrame == null) {
      setState(() {
        _busy = false;
        _failed = true;
      });
      return;
    }
    final vPath = await widget.keep('video-${DateTime.now().millisecondsSinceEpoch}.jpg', vFrame);
    if (!mounted) {
      return;
    }
    final vMarks = await widget.annotate(context, vPath, const []);
    if (!mounted) {
      return;
    }
    final vLabel = await _askLabel(vText);
    setState(() {
      _busy = false;
      if (vLabel != null) {
        _moments.add((at: vAt, label: vLabel, photoPath: vPath, marks: vMarks ?? const []));
      }
    });
  }

  Future<String?> _askLabel(AppLocalizations pText) {
    final vController = TextEditingController(text: pText.videoDefaultLabel);

    return showDialog<String>(
      context: context,
      builder: (pDialogContext) => AlertDialog(
        title: Text(pText.touchUpLabel),
        content: TextField(controller: vController, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(pDialogContext), child: Text(pText.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(
              pDialogContext,
              vController.text.trim().isEmpty ? pText.videoDefaultLabel : vController.text.trim(),
            ),
            child: Text(pText.save),
          ),
        ],
      ),
    ).whenComplete(vController.dispose);
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(vText.videoTitle)),
      body: FutureBuilder<void>(
        future: _ready,
        builder: (pContext, pSnapshot) {
          if (pSnapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: IconLine(Icons.error_outline, vText.videoUnreadable),
            );
          }
          if (pSnapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListenableBuilder(
            listenable: widget.video,
            builder: (pContext, _) {
              final vLength = widget.video.length.inMilliseconds;
              final vAt = widget.video.position.inMilliseconds.clamp(0, vLength);

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Text(vText.videoHelp, style: vTheme.textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: widget.video.view()),
                  Row(
                    children: [
                      IconButton(
                        tooltip: widget.video.playing ? vText.videoPause : vText.videoPlay,
                        onPressed: () =>
                            widget.video.playing ? widget.video.pause() : widget.video.play(),
                        icon: Icon(widget.video.playing ? Icons.pause : Icons.play_arrow),
                      ),
                      Expanded(
                        child: Slider(
                          value: vLength == 0 ? 0 : vAt / vLength,
                          onChanged: (pValue) => widget.video.seekTo(
                            Duration(milliseconds: (pValue * vLength).round()),
                          ),
                        ),
                      ),
                      Text(formatVideoTime(widget.video.position)),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: _busy ? null : _mark,
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: Text(vText.videoMark),
                  ),
                  if (_failed)
                    IconLine(
                      Icons.error_outline,
                      vText.videoFrameFailed,
                      color: vTheme.colorScheme.error,
                    ),
                  for (final vMoment in _moments)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: SizedBox(
                        width: 64,
                        child: MarkedPhoto(path: vMoment.photoPath, marks: vMoment.marks),
                      ),
                      title: Text(vMoment.label),
                      subtitle: Text(vText.videoMomentAt(formatVideoTime(vMoment.at))),
                      onTap: () => widget.video.seekTo(vMoment.at),
                      trailing: IconButton(
                        tooltip: vText.delete,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => setState(() => _moments.remove(vMoment)),
                      ),
                    ),
                  if (_moments.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: FilledButton.tonalIcon(
                        onPressed: () {
                          final vId = DateTime.now().microsecondsSinceEpoch;
                          Navigator.pop(
                            context,
                            touchUpsFromMoments(
                              _moments,
                              vText.videoMomentAt,
                              (pIndex) => '$vId-$pIndex',
                            ),
                          );
                        },
                        icon: const Icon(Icons.playlist_add),
                        label: Text(vText.videoAdd(_moments.length)),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(vText.videoHint, style: vTheme.textTheme.bodySmall),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
