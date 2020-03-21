import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_links/uni_links.dart';
import 'playerWidget.dart';

import 'drawer.dart';
import 'identification.dart';
import 'nowPlaying.dart';
import 'utils.dart' show handleLink;

enum UniLinksType { string, uri }

class SongNowPlayingAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  final Future<SongNowPlaying> _songNowPlaying;

  SongNowPlayingAppBar(this._songNowPlaying, {Key key})
      : preferredSize = Size.fromHeight(kToolbarHeight),
        super(key: key);

  @override
  final Size preferredSize;

  @override
  _SongNowPlayingAppBarState createState() => _SongNowPlayingAppBarState();
}

class _SongNowPlayingAppBarState extends State<SongNowPlayingAppBar> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SongNowPlaying>(
      future: widget._songNowPlaying,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          SongNowPlaying songNowPlaying = snapshot.data;
          return AppBar(
              title: Text(songNowPlaying.title),
              bottom: PreferredSize(
                  child: Align(
                      alignment: FractionalOffset.bottomCenter,
                      child: Text(
                          '${songNowPlaying.artist} • ${songNowPlaying.year}  • ${songNowPlaying.program.name}')),
                  preferredSize: null));
        } else if (snapshot.hasError) {
          return AppBar(title: Text("Erreur"));
        }

        // By default, show a loading spinner
        return AppBar(title: Text("Chargement"));
      },
    );
  }
}

void main() => runApp(BideApp());

class BideApp extends StatefulWidget {
  @override
  _BideAppState createState() => _BideAppState();
}

class _BideAppState extends State<BideApp> with WidgetsBindingObserver {
  PlayerWidget _playerWidget;
  PlaybackState _playbackState;
  StreamSubscription _playbackStateSubscription;
  Future<SongNowPlaying> _songNowPLaying;
  Timer _timer;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    connect();
    autoLogin();
    initPlatformState();
    _songNowPLaying = fetchNowPlaying();
    _playerWidget = PlayerWidget(_songNowPLaying);
    _timer = Timer.periodic(Duration(seconds: 45), (Timer timer) async {
      setState(() {
        _songNowPLaying = fetchNowPlaying();
      });
    });
    super.initState();
  }

  // DEEP LINKING
  /////////////////////////////////////////////////////////////////////////
  String _deepLink;
  UniLinksType _type = UniLinksType.string;
  StreamSubscription _sub;

  Future<Null> initUniLinks() async {
    // Attach a listener to the stream
    _sub = getLinksStream().listen((String link) {
      // Parse the link and warn the user, if it is not correct
    }, onError: (err) {
      // Handle exception by warning the user their action did not succeed
    });
  }

  initPlatformState() async {
    if (_type == UniLinksType.string) {
      await initPlatformStateForStringUniLinks();
    } else {
      await initPlatformStateForUriUniLinks();
    }
  }

  /// An implementation using a [String] link
  initPlatformStateForStringUniLinks() async {
    // Attach a listener to the links stream
    _sub = getLinksStream().listen((String link) {
      if (!mounted) return;
      setState(() {
        _deepLink = link ?? null;
      });
    }, onError: (err) {
      print('Failed to get deep link: $err.');
      if (!mounted) return;
      setState(() {
        _deepLink = null;
      });
    });

    // Attach a second listener to the stream
    getLinksStream().listen((String link) {
      print('got link: $link');
    }, onError: (err) {
      print('got err: $err');
    });

    // Get the latest link
    String initialLink;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      initialLink = await getInitialLink();
      print('initial link: $initialLink');
    } on PlatformException {
      initialLink = 'Failed to get initial link.';
    } on FormatException {
      initialLink = 'Failed to parse the initial link as Uri.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _deepLink = initialLink;
    });
  }

  /// An implementation using the [Uri] convenience helpers
  initPlatformStateForUriUniLinks() async {
    // Attach a listener to the Uri links stream
    _sub = getUriLinksStream().listen((Uri uri) {
      if (!mounted) return;
      setState(() {
        _deepLink = uri?.toString() ?? null;
      });
    }, onError: (err) {
      print('Failed to get latest link: $err.');
      if (!mounted) return;
      setState(() {
        _deepLink = null;
      });
    });

    // Attach a second listener to the stream
    getUriLinksStream().listen((Uri uri) {
      print('got uri: ${uri?.path} ${uri?.queryParametersAll}');
    }, onError: (err) {
      print('got err: $err');
    });

    // Get the latest Uri
    Uri initialUri;
    String initialLink;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      initialUri = await getInitialUri();
      print('initial uri: ${initialUri?.path}'
          ' ${initialUri?.queryParametersAll}');
      initialLink = initialUri?.toString();
    } on PlatformException {
      initialUri = null;
      initialLink = 'Failed to get initial uri.';
    } on FormatException {
      initialUri = null;
      initialLink = 'Bad parse the initial link as Uri.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _deepLink = initialLink;
    });
  }

  /////////////////////////////////////////////////////////////////////////

  void autoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    bool rememberIdents = prefs.getBool('rememberIdents') ?? false;
    bool autoConnect = prefs.getBool('autoConnect') ?? false;

    if (rememberIdents && autoConnect) {
      var login = prefs.getString('login') ?? '';
      var password = prefs.getString('password') ?? '';

      sendIdentifiers(login, password);
    }
  }

  @override
  void dispose() {
    disconnect();
    WidgetsBinding.instance.removeObserver(this);
    if (_sub != null) _sub.cancel();
    _timer.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        connect();
        break;
      case AppLifecycleState.paused:
        disconnect();
        break;
      default:
        break;
    }
  }

  void connect() async {
    await AudioService.connect();
    if (_playbackStateSubscription == null) {
      _playbackStateSubscription = AudioService.playbackStateStream
          .listen((PlaybackState playbackState) {
        setState(() {
          _playbackState = playbackState;
        });
      });
    }
  }

  void disconnect() {
    if (_playbackStateSubscription != null) {
      _playbackStateSubscription.cancel();
      _playbackStateSubscription = null;
    }
    AudioService.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    Widget home;
    Widget body;

    //if the app is launched from deep linking, try to fetch the widget that
    //match the url
    if (_deepLink != null) {
      body = handleLink(_deepLink, context);
    }

    //no url match from deep link or not launched from deep link
    if (body == null)
      home = OrientationBuilder(builder: (context, orientation) {
        if (orientation == Orientation.portrait) {
          return Scaffold(
              appBar: SongNowPlayingAppBar(_songNowPLaying),
              bottomNavigationBar: BottomAppBar(child: _playerWidget),
              drawer: DrawerWidget(),
              body: NowPlayingWidget(_songNowPLaying));
        } else {
          return Scaffold(
              appBar: SongNowPlayingAppBar(_songNowPLaying),
              drawer: DrawerWidget(),
              body: Row(
                children: <Widget>[
                  Expanded(child: NowPlayingWidget(_songNowPLaying)),
                  Expanded(child: _playerWidget)
                ],
              ));
        }
      });
    else
      home = Scaffold(
          bottomNavigationBar: BottomAppBar(child: _playerWidget), body: body);

    return InheritedPlaybackState(
        playbackState: _playbackState,
        child: MaterialApp(
            title: 'Bide&Musique',
            theme: ThemeData(
              primarySwatch: Colors.orange,
              buttonColor: Colors.orangeAccent,
              secondaryHeaderColor: Colors.deepOrange,
              bottomAppBarColor: Colors.orange,
              canvasColor: Color(0xFFF5EEE5),
            ),
            home: home));
  }
}
