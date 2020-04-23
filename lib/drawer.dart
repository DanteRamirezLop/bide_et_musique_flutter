import 'package:flutter/material.dart';

import 'song.dart';
import 'about.dart';
import 'forums.dart';
import 'identification.dart';
import 'manageAccount.dart';
import 'newSongs.dart';
import 'nowSong.dart';
import 'pochettoscope.dart';
import 'randomSong.dart';
import 'schedule.dart';
import 'search.dart';
import 'session.dart';
import 'settings.dart';
import 'thematics.dart';
import 'titles.dart';
import 'trombidoscope.dart';
import 'wall.dart';

class DrawerWidget extends StatefulWidget {
  @override
  _DrawerWidgetState createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  String _accountTitle;

  @override
  void initState() {
    super.initState();
    _setAccountTitle();
  }

  _setAccountTitle() {
    setState(() {
      _accountTitle = Session.accountLink.id == null
          ? 'Connexion'
          : '${Session.accountLink.name}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: ListView(
      children: <Widget>[
        SizedBox(
          height: 120.0,
          child: DrawerHeader(
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.fitWidth,
                    image: AssetImage('assets/bm_logo_white.png'),
                  ),
                ),
                child: Container(),
              ),
              decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.fitWidth,
                  image: AssetImage('assets/bandeau.png'),
                ),
              )),
        ),
        ListTile(
          title: Text(_accountTitle),
          leading: Icon(Icons.account_circle),
          trailing: Session.accountLink.id == null ? null : DisconnectButton(),
          onTap: () {
            Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => IdentificationWidget()))
                .then((_) => _setAccountTitle());
          },
        ),
        Divider(),
        ListTile(
          title: Text('Titres'),
          leading: Icon(Icons.queue_music),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => TitlesWidget()));
          },
        ),
        ListTile(
          title: Text('Programmation'),
          leading: Icon(Icons.calendar_view_day),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        ScheduleWidget(schedule: fetchSchedule())));
          },
        ),
        ListTile(
          title: Text('Thématiques'),
          leading: Icon(Icons.photo_album),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        ThematicPageWidget(programLinks: fetchThematics())));
          },
        ),
        ListTile(
          title: Text('Morceau du moment'),
          leading: Icon(Icons.access_alarms),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        NowSongsWidget(nowSongs: fetchNowSongs())));
          },
        ),
        ListTile(
          title: Text('Morceau au pif'),
          leading: Icon(Icons.shuffle),
          onTap: () {
            fetchRandomSongId().then((id) => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => SongPageWidget(
                        songLink: SongLink(id: id), song: fetchSong(id)))));
          },
        ),
        ListTile(
          title: Text('Recherche'),
          leading: Icon(Icons.search),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => SearchWidget()));
          },
        ),
        Divider(),
        ListTile(
          title: Text('Mur des messages'),
          leading: Icon(Icons.comment),
          onTap: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => WallWidget()));
          },
        ),
        ListTile(
          title: Text('Forums'),
          leading: Icon(Icons.forum),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => ForumWidget()));
          },
        ),
        Divider(),
        ListTile(
          title: Text('Pochettoscope'),
          leading: Icon(Icons.image),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => PochettoscopeWidget()));
          },
        ),
        ListTile(
          title: Text('Trombidoscope'),
          leading: Icon(Icons.face),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => TrombidoscopeWidget()));
          },
        ),
        Divider(),
        ListTile(
          title: Text('Nouvelles entrées'),
          leading: Icon(Icons.fiber_new),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => SongsWidget(songs: fetchNewSongs())));
          },
        ),
        ListTile(
          title: Text('Options'),
          leading: Icon(Icons.settings),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => SettingsPage()));
          },
        ),
        ListTile(
          title: Text('À propos'),
          leading: Icon(Icons.info),
          onTap: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => AboutPage()));
          },
        ),
      ],
    ));
  }
}
