import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'utils.dart';
import 'song.dart';
import 'ident.dart';
import 'account.dart';

class ManageFavoritesWidget extends StatefulWidget {
  final Session session;

  ManageFavoritesWidget({Key key, this.session}) : super(key: key);

  @override
  _ManageFavoritesWidgetState createState() =>
      _ManageFavoritesWidgetState(this.session);
}

class _ManageFavoritesWidgetState extends State<ManageFavoritesWidget> {
  _ManageFavoritesWidgetState(this.session);
  Session session;
  Future<AccountInformations> accountInformations;

  List<Dismissible> _rows;

  @override
  void initState() {
    super.initState();
    accountInformations = fetchAccountSession(this.session);
    _rows = <Dismissible>[];
  }

  Dismissible _createSongTile(Song song, AccountInformations accountInformations){
    return Dismissible(
        key: Key(song.id),
        onDismissed: (direction) {
          _confirmDeletion(song, accountInformations);
        },
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.black12,
            child: Image(
                image:
                NetworkImage('$baseUri/images/thumb25/${song.id}.jpg')),
          ),
          title: Text(
            song.title,
          ),
          subtitle: Text(song.artist),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => SongPageWidget(
                        song: song,
                        songInformations: fetchSongInformations(song.id))));
          },
        ));
  }

  Future<void> _confirmDeletion(Song song, AccountInformations accountInformations) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Retirer un favoris'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Vraiment retirer cette chanson de vos favoris ? '),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Oui'),
              onPressed: () async {
                var accountId = session.id;
                var K = song.id;
                var direction = 'DS';

                final response = await session.post(
                    '$baseUri/account/$accountId.html', {
                  'K': K,
                  'Step': '',
                  direction + '.x': '1',
                  direction + '.y': '1'
                });

                if (response.statusCode == 200) {
                  setState(() {
                    accountInformations.favorites
                        .removeWhere((song) => song.id == K);
                  });
                }
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text('Non'),
              onPressed: () {
                int index = accountInformations.favorites.indexOf(song);

                setState(() {
                  _rows.insert(index, _createSongTile(song, accountInformations));
                });


                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildView(BuildContext context, Session session,
      AccountInformations accountInformations) {
    _rows.clear();
    for (Song song in accountInformations.favorites) {
      _rows.add(_createSongTile(song, accountInformations));
    }

    return ReorderableListView(
        children: _rows,
        onReorder: (int initialPosition, int targetPosition) async {
          var draggedSong = accountInformations.favorites[initialPosition];
          //update server
          var accountId = session.id;
          var K = draggedSong.id;
          var step = initialPosition - targetPosition;
          var direction = step < 0 ? 'down' : 'up';

          final response =
          await session.post('$baseUri/account/$accountId.html', {
            'K': K,
            'Step': step.abs().toString(),
            direction + '.x': '1',
            direction + '.y': '1'
          });

          if (response.statusCode == 200) {
            setState(() {
              accountInformations.favorites.removeAt(initialPosition);
              accountInformations.favorites.insert(targetPosition, draggedSong);
            });
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<AccountInformations>(
        future: accountInformations,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _buildView(context, session, snapshot.data);
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }

          // By default, show a loading spinner
          return CircularProgressIndicator();
        },
      ),
    );
  }
}