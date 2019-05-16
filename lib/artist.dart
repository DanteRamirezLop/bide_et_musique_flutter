import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'utils.dart';
import 'song.dart';
import 'dart:convert';

Future<Artist> fetchArtist(String artistId) async {
  var artist;
  final url = '$baseUri/artist/$artistId';

  final responseJson = await http.get(url);

  if (responseJson.statusCode == 200) {
    try {
      artist = Artist.fromJson(
          json.decode(utf8.decode(responseJson.bodyBytes)));
    } catch (e) {
      print('Error while decoding artist informations : ' + e.toString());
    }
  } else {
    throw Exception('Failed to load artist informations');
  }

  return artist;
}

String extractArtistId(str) {
  final idRegex = RegExp(r'/artist/(\d+).html');
  var match = idRegex.firstMatch(str);
  return match[1];
}


class Artist {
  String id;
  String alias;
  String firstName;
  String lastName;
  String site;
  List<Song> disco;

  Artist({this.id, this.alias, this.site, this.disco});

  factory Artist.fromJson(Map<String, dynamic> json) {
    var disco = <Song>[];
    for(var discoEntry in json['disco']){
      var song = Song();
      song.id = discoEntry['id'].toString();
      song.title = discoEntry['name'];
      disco.add(song);
    }

    return Artist(
        id: json['id'].toString(),
        alias: json['alias'],
        site: json['site'],
      disco: disco
    );
  }
}


class ArtistPageWidget extends StatelessWidget {
  final Future<Artist> artist;

  ArtistPageWidget({Key key, this.artist}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<Artist>(
        future: artist,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _buildView(context, snapshot.data);
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }

          var loadingMessage = 'Chargement';

          return Scaffold(
            appBar: AppBar(
              title: Text(loadingMessage),
            ),
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildView(BuildContext context, Artist artist) {
    var urlCover = '$baseUri/images/photos/ART${artist.id}.jpg';
    final _fontLyrics = TextStyle(fontSize: 20.0);

    var nestedScrollView = NestedScrollView(
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return <Widget>[
          SliverAppBar(
            backgroundColor: Theme.of(context).canvasColor,
            expandedHeight: 200.0,
            automaticallyImplyLeading: false,
            floating: true,
            flexibleSpace: FlexibleSpaceBar(
                background: Row(children: [
                  Expanded(
                      flex: 3,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                              child: InkWell(
                                  child: Image.network(urlCover))),
                          Expanded(child: Text(artist.alias)),
                        ],
                      ))
                ])),
          ),
        ];
      },
      body: Center(
          child: Container(
            child: Stack(children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  decoration:
                  BoxDecoration(color: Colors.grey.shade200.withOpacity(0.7)),
                ),
              ),
              SongListingWidget(artist.disco)
            ]),
            decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.fill,
                  alignment: FractionalOffset.topCenter,
                  image: NetworkImage(urlCover),
                )),
          )),
    );



    return Scaffold(
      appBar: AppBar(
        title: Text(stripTags(artist.alias)),
      ),
      body: nestedScrollView,
    );
  }
}