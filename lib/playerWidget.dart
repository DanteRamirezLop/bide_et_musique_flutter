import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import 'player.dart';

class InheritedPlaybackState extends InheritedWidget {
  const InheritedPlaybackState(
      {Key key, @required this.playbackState, @required Widget child})
      : super(key: key, child: child);

  final PlaybackState playbackState;

  static PlaybackState of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<InheritedPlaybackState>()
        .playbackState;
  }

  @override
  bool updateShouldNotify(InheritedPlaybackState old) =>
      playbackState != old.playbackState;
}

class SongPositionSlider extends StatefulWidget {
  final PlaybackState _playerState;
  final double _duration;

  SongPositionSlider(this._playerState, this._duration);

  @override
  _SongPositionSliderState createState() => _SongPositionSliderState();
}

class _SongPositionSliderState extends State<SongPositionSlider> {
  final BehaviorSubject<double> _dragPositionSubject =
      BehaviorSubject.seeded(null);

  String _formatSongDuration(int ms) {
    Duration duration = Duration(milliseconds: ms);
    String twoDigits(int n) {
      if (n >= 10) return "$n";
      return "0$n";
    }

    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    double seekPos;
    return StreamBuilder(
        stream: Rx.combineLatest2<double, double, double>(
            _dragPositionSubject.stream,
            Stream.periodic(Duration(milliseconds: 200)),
            (dragPosition, _) => dragPosition),
        builder: (context, snapshot) {
          double position =
              snapshot.data ?? widget._playerState.currentPosition.toDouble();

          Widget text =
              Text(_formatSongDuration(widget._playerState.currentPosition));

          Widget slider = Slider(
              inactiveColor: Colors.grey,
              activeColor: Colors.red,
              min: 0.0,
              max: widget._duration,
              value: seekPos ?? max(0.0, min(position, widget._duration)),
              onChanged: (value) {
                _dragPositionSubject.add(value);
              },
              onChangeEnd: (value) {
                AudioService.seekTo(value.toInt());
                seekPos = value;
                _dragPositionSubject.add(null);
              });
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[text, slider],
          );
        });
  }
}

class PlayerWidget extends StatefulWidget {
  final Orientation orientation;

  PlayerWidget(this.orientation);

  @override
  _PlayerWidgetState createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget>
    with WidgetsBindingObserver {
  @override
  Widget build(BuildContext context) {
    final playbackState = InheritedPlaybackState.of(context);
    double duration = AudioService.currentMediaItem?.duration?.toDouble();
    if (playbackState?.basicState == BasicPlaybackState.buffering ||
        playbackState?.basicState == BasicPlaybackState.connecting) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black)),
          stopButton(48),
        ],
      );
    } else {
      List<Widget> controls = <Widget>[
        Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              playbackState?.basicState == BasicPlaybackState.paused
                  ? playButton(48)
                  : pauseButton(48),
              stopButton(48)
            ]),
        if (duration != null)
          Container(
            height: 20,
            child: SongPositionSlider(playbackState, duration),
          )
      ];

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: playbackState?.basicState == BasicPlaybackState.playing ||
                playbackState?.basicState == BasicPlaybackState.paused ||
                playbackState?.basicState == BasicPlaybackState.buffering
            ? [
                widget.orientation == Orientation.portrait
                    ? Row(
                        children: controls,
                      )
                    : Column(
                        children: controls,
                      )
              ]
            : [
                Padding(
                    padding: const EdgeInsets.all(8),
                    child: RadioStreamButton())
              ],
      );
    }
  }
}

class RadioStreamButton extends StatelessWidget {
  RadioStreamButton();

  Widget build(BuildContext context) {
    String buttonText = "Écouter la radio";

    return RaisedButton.icon(
      icon: Icon(Icons.radio, size: 40),
      label: Text(buttonText,
          style: TextStyle(
            fontSize: 20.0,
          )),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      onPressed: () async {
        bool success = await AudioService.start(
          backgroundTaskEntrypoint: audioPlayerTaskEntrypoint,
          resumeOnClick: true,
          androidNotificationChannelName: 'Bide&Musique',
          notificationColor: 0xFFFFFFFF,
          androidNotificationIcon: 'mipmap/ic_launcher',
        );
        if (success) {
          await AudioService.customAction('resetSong');
          await AudioService.play();
          await AudioService.customAction('setNotification');
        }
      },
    );
  }
}

IconButton playButton(double iconSize) => IconButton(
      icon: Icon(Icons.play_arrow),
      iconSize: iconSize,
      onPressed: AudioService.play,
    );

IconButton pauseButton(double iconSize) => IconButton(
      icon: Icon(Icons.pause),
      iconSize: iconSize,
      onPressed: AudioService.pause,
    );

IconButton stopButton(double iconSize) => IconButton(
      icon: Icon(Icons.stop),
      iconSize: iconSize,
      onPressed: AudioService.stop,
    );
