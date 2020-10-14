import 'dart:async';
import 'dart:math';

import 'package:Beats/API/saavn.dart';
import 'package:Beats/model/player.dart';
import 'package:Beats/style/appColors.dart';
import 'package:Beats/utils/constants.dart';
import 'package:Beats/ui/player/widgets/visualizer.dart';
import 'package:audio_session/audio_session.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:just_audio/just_audio.dart';

class NowPlaying3 extends StatefulWidget {
  final String songId;
  final bool newSong;
  const NowPlaying3({Key key, @required this.songId, this.newSong = false})
      : super(key: key);
  @override
  _NowPlaying3State createState() => _NowPlaying3State(songId, newSong);
}

class _NowPlaying3State extends State<NowPlaying3> {
  final String songId;
  final bool newSong;

  _NowPlaying3State(this.songId, this.newSong);

  // Future createPlaylist() async {
  //   SongDetails song = await fetchSongDetails(songId);
  //   _playlist = ConcatenatingAudioSource(children: [
  //     AudioSource.uri(Uri.parse(song.kUrl),
  //         tag: AudioMetadata(
  //           album: song.album,
  //           title: song.title,
  //           artwork: song.image,
  //         ))
  //   ]);
  //   return _playlist;
  // }

  bool change = false;
  bool volume = false;

  @override
  void initState() {
    super.initState();
    if (player == null) {
      player = AudioPlayer();
    }
    if (newSong && player.playing) {
      player.stop();
    }
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ));
    _init();
  }

  _init() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.music());
    if (newSong || playlist == null) {
      song = await fetchSongDetails(songId);
      playlist = ConcatenatingAudioSource(children: [
        AudioSource.uri(Uri.parse(song.kUrl),
            tag: AudioMetadata(
              album: song.album,
              title: song.title,
              artwork: song.image,
            ))
      ]);
      try {
        await player.load(playlist);
        setState(() {
          player.play();
          miniPlayer.add(true);
        });
      } catch (e) {
        // catch load errors: 404, invalid url ...
        print("An error occured $e");
      }
    }
    currentSongId = songId;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: playlist != null
            ? Column(
                children: [
                  GestureDetector(
                    onHorizontalDragDown: (details) {
                      Navigator.pop(context);
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.0),
                          height: 5.0,
                          width: 50.0,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(40.0),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(10.0),
                          height: 20.0,
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  StreamBuilder<SequenceState>(
                    stream: player.sequenceStateStream,
                    builder: (context, snapshot) {
                      final state = snapshot.data;
                      if (state?.sequence?.isEmpty ?? true) return SizedBox();
                      final metadata = state.currentSource.tag as AudioMetadata;
                      return Column(
                        children: [
                          SizedBox(height: 40.0),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              PlayDisc(metadata: metadata),
                              Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                              Container(
                                height: 30,
                                width: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 40.0, bottom: 10.0),
                            child: Text(
                              metadata.title ?? '',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 30.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(bottom: 20.0),
                            child: Text(
                              metadata.album ?? '',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: StreamBuilder<Duration>(
                      stream: player.durationStream,
                      builder: (context, snapshot) {
                        final duration = snapshot.data ?? Duration.zero;
                        return StreamBuilder<Duration>(
                          stream: player.positionStream,
                          builder: (context, snapshot) {
                            var position = snapshot.data ?? Duration.zero;
                            if (position > duration) {
                              position = duration;
                            }
                            return SeekBar(
                              duration: duration,
                              position: position,
                              onChangeEnd: (newPosition) {
                                player.seek(newPosition);
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 30.0),
                  ControlButtons(player),
                  Spacer(),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0)),
                    margin:
                        EdgeInsets.symmetric(horizontal: 40.0, vertical: 40.0),
                    child: Container(
                      height: 80.0,
                      width: MediaQuery.of(context).size.width,
                      margin: EdgeInsets.symmetric(horizontal: 30.0),
                      child: !change
                          ? Row(
                              children: [
                                IconButton(
                                  icon:
                                      Icon(MaterialCommunityIcons.volume_high),
                                  onPressed: () {
                                    Timer(Duration(seconds: 3), () {
                                      change = !change;
                                      setState(() {});
                                    });
                                    setState(() {
                                      volume = true;
                                      change = !change;
                                    });
                                  },
                                ),
                                Spacer(),
                                IconButton(
                                  icon: Icon(Icons.playlist_play),
                                  onPressed: null,
                                ),
                                Spacer(),
                                StreamBuilder<double>(
                                  stream: player.speedStream,
                                  builder: (context, snapshot) => IconButton(
                                    icon: Text(
                                        "${snapshot.data?.toStringAsFixed(1)}x",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    onPressed: () {
                                      Timer(Duration(seconds: 3), () {
                                        change = !change;
                                        setState(() {});
                                      });
                                      setState(() {
                                        volume = false;
                                        change = !change;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            )
                          : _showSlider(
                              context: context,
                              divisions: 10,
                              min: volume ? 0.0 : 0.5,
                              max: volume ? 1.0 : 1.5,
                              stream: volume
                                  ? player.volumeStream
                                  : player.speedStream,
                              onChanged:
                                  volume ? player.setVolume : player.setSpeed,
                            ),
                    ),
                  ),
                  // Container(
                  //   height: 240.0,
                  //   child: StreamBuilder<SequenceState>(
                  //     stream: player.sequenceStateStream,
                  //     builder: (context, snapshot) {
                  //       final state = snapshot.data;
                  //       final sequence = state?.sequence ?? [];
                  //       return ListView.builder(
                  //         itemCount: sequence.length,
                  //         itemBuilder: (context, index) => Material(
                  //           color: index == state.currentIndex
                  //               ? Colors.grey.shade300
                  //               : null,
                  //           child: ListTile(
                  //             title: Text(sequence[index].tag.title),
                  //             onTap: () {
                  //               player.seek(Duration.zero, index: index);
                  //             },
                  //           ),
                  //         ),
                  //       );
                  //     },
                  //   ),
                  // ),
                ],
              )
            : Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class PlayDisc extends StatefulWidget {
  const PlayDisc({
    Key key,
    @required this.metadata,
  }) : super(key: key);

  final AudioMetadata metadata;

  @override
  _PlayDiscState createState() => _PlayDiscState();
}

class _PlayDiscState extends State<PlayDisc>
    with SingleTickerProviderStateMixin {
  AnimationController controller;
  Animation<double> animation;

  @override
  void initState() {
    super.initState();
    controller =
        AnimationController(duration: Duration(seconds: 15), vsync: this);
    animation = Tween(begin: 0.0, end: 360.0).animate(controller)
      ..addListener(() {
        if (player.playing) setState(() {});
      });
    controller.repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.rotate(
          //angle: angle,
          angle: (pi / 180) * (animation.value),
          alignment: Alignment.center,
          child: Container(
            height: 250,
            width: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: CachedNetworkImageProvider(widget.metadata.artwork),
              ),
            ),
          ),
        );
      },
    );
  }
}

class Visuallizer extends StatefulWidget {
  const Visuallizer({
    Key key,
  }) : super(key: key);

  @override
  _VisuallizerState createState() => _VisuallizerState();
}

class _VisuallizerState extends State<Visuallizer> {
  Timer t;
  @override
  void initState() {
    super.initState();
    t = Timer.periodic(const Duration(milliseconds: 500), (Timer t) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    if (t != null && t.isActive) {
      t.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      width: 350,
      child: player.playing ? Vis() : SizedBox.shrink(),
    );
  }
}

class ControlButtons extends StatelessWidget {
  final AudioPlayer player;

  ControlButtons(this.player);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<LoopMode>(
            stream: player.loopModeStream,
            builder: (context, snapshot) {
              var loopMode = snapshot.data ?? LoopMode.off;
              List<Widget> icons = [
                Center(child: Icon(Icons.loop, color: Colors.grey)),
                Center(
                    child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.loop_rounded, color: accent),
                    Text('1',
                        style: TextStyle(
                          fontSize: 6.0,
                          color: accent,
                          fontWeight: FontWeight.bold,
                        )),
                  ],
                )),
                Center(child: Icon(Icons.loop_rounded, color: accent)),
              ];
              const cycleModes = [
                LoopMode.off,
                LoopMode.all,
                LoopMode.one,
              ];
              final index = cycleModes.indexOf(loopMode);
              return IconButton(
                icon: icons[index],
                onPressed: () {
                  player.setLoopMode(cycleModes[
                      (cycleModes.indexOf(loopMode) + 1) % cycleModes.length]);
                },
              );
            },
          ),
          Spacer(),
          StreamBuilder<SequenceState>(
            stream: player.sequenceStateStream,
            builder: (context, snapshot) => IconButton(
              icon: Icon(Icons.skip_previous),
              onPressed: player.hasPrevious ? player.seekToPrevious : null,
            ),
          ),
          Spacer(),
          Container(
            height: 65,
            width: 65,
            child: StreamBuilder<PlayerState>(
              stream: player.playerStateStream,
              builder: (context, snapshot) {
                final playerState = snapshot.data;
                final processingState = playerState?.processingState;
                final playing = playerState?.playing;
                if (processingState == ProcessingState.loading ||
                    processingState == ProcessingState.buffering) {
                  return FloatingActionButton(
                    backgroundColor: accent,
                    onPressed: null,
                    child: CircularProgressIndicator(
                      backgroundColor: Colors.black,
                    ),
                  );
                } else if (playing != true) {
                  return FloatingActionButton(
                    backgroundColor: accent,
                    child: Icon(Icons.play_arrow),
                    onPressed: player.play,
                  );
                } else if (processingState != ProcessingState.completed) {
                  return FloatingActionButton(
                    backgroundColor: accent,
                    child: Icon(Icons.pause),
                    onPressed: player.pause,
                  );
                } else {
                  return FloatingActionButton(
                    backgroundColor: accent,
                    child: Icon(Icons.replay),
                    onPressed: () => player.seek(Duration.zero, index: 0),
                  );
                }
              },
            ),
          ),
          Spacer(),
          StreamBuilder<SequenceState>(
            stream: player.sequenceStateStream,
            builder: (context, snapshot) => IconButton(
              icon: Icon(Icons.skip_next),
              onPressed: player.hasNext ? player.seekToNext : null,
            ),
          ),
          Spacer(),
          StreamBuilder<bool>(
            stream: player.shuffleModeEnabledStream,
            builder: (context, snapshot) {
              final shuffleModeEnabled = snapshot.data ?? false;
              return IconButton(
                icon: shuffleModeEnabled
                    ? Icon(Icons.shuffle, color: accent)
                    : Icon(Icons.shuffle, color: Colors.grey),
                onPressed: () {
                  player.setShuffleModeEnabled(!shuffleModeEnabled);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class SeekBar extends StatefulWidget {
  final Duration duration;
  final Duration position;
  final ValueChanged<Duration> onChanged;
  final ValueChanged<Duration> onChangeEnd;

  SeekBar({
    @required this.duration,
    @required this.position,
    this.onChanged,
    this.onChangeEnd,
  });

  @override
  _SeekBarState createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double _dragValue;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SliderTheme(
          data: SliderThemeData(
            thumbShape: SliderComponentShape.noOverlay,
            inactiveTrackColor: Colors.grey[500],
            activeTrackColor: accent,
          ),
          child: Slider(
            min: 0.0,
            max: widget.duration.inMilliseconds.toDouble(),
            value: min(_dragValue ?? widget.position.inMilliseconds.toDouble(),
                widget.duration.inMilliseconds.toDouble()),
            onChanged: (value) {
              setState(() {
                _dragValue = value;
              });
              if (widget.onChanged != null) {
                widget.onChanged(Duration(milliseconds: value.round()));
              }
            },
            onChangeEnd: (value) {
              if (widget.onChangeEnd != null) {
                widget.onChangeEnd(Duration(milliseconds: value.round()));
              }
              _dragValue = null;
            },
          ),
        ),
        // Positioned(
        //   right: 25.0,
        //   bottom: 0.0,
        //   child: Text(
        //       RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
        //               .firstMatch("$_remaining")
        //               ?.group(1) ??
        //           '$_remaining',
        //       style: Theme.of(context).textTheme.caption),
        // ),
        Positioned(
          right: 25.0,
          bottom: 0.0,
          child: Text('$_remaining'.substring(3, 7),
              style: Theme.of(context).textTheme.caption),
        ),
        Positioned(
          left: 25.0,
          bottom: 0.0,
          child: Text(widget.duration.toString().substring(3, 7),
              style: Theme.of(context).textTheme.caption),
        ),
      ],
    );
  }

  Duration get _remaining => widget.duration - widget.position;
}

_showSlider(
    {BuildContext context,
    int divisions,
    double min,
    double max,
    String valueSuffix = '',
    Stream<double> stream,
    ValueChanged<double> onChanged}) {
  return StreamBuilder<double>(
    stream: stream,
    builder: (context, snapshot) => Container(
      height: 100.0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${snapshot.data?.toStringAsFixed(1)}$valueSuffix',
            style: TextStyle(
              fontFamily: 'Fixed',
              fontWeight: FontWeight.w400,
              fontSize: 20.0,
            ),
          ),
          Slider(
            divisions: divisions,
            min: min,
            max: max,
            value: snapshot.data ?? 1.0,
            onChanged: onChanged,
          ),
        ],
      ),
    ),
  );
}

class AudioMetadata {
  final String album;
  final String title;
  final String artwork;

  AudioMetadata({this.album, this.title, this.artwork});
}