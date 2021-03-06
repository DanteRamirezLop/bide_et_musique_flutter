import 'dart:async';

import 'package:flutter/material.dart';

import '../models/program.dart';
import '../services/program.dart';
import '../utils.dart';
import 'program.dart';

class ThematicPageWidget extends StatefulWidget {
  final Future<List<ProgramLink>> programLinks;

  ThematicPageWidget({Key key, this.programLinks}) : super(key: key);

  @override
  _ThematicPageWidgetState createState() => _ThematicPageWidgetState();
}

class _ThematicPageWidgetState extends State<ThematicPageWidget> {
  TextEditingController controller = TextEditingController();
  bool _searchMode = false;
  String _searchInput = '';

  onSearchTextChanged(String text) async {
    setState(() {
      _searchInput = controller.text;
    });
  }

  Widget _switchSearchMode() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _searchMode = !_searchMode;
          controller.clear();
          setState(() {
            _searchInput = '';
          });
        });
      },
      child: Icon(
        Icons.filter_list,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: _searchMode == true
              ? TextField(
                  controller: controller,
                  autofocus: true,
                  decoration:
                      InputDecoration(hintText: 'Filtrer les thématiques'),
                  onChanged: onSearchTextChanged,
                )
              : Text('Thématiques'),
          actions: <Widget>[
            Padding(
                padding: EdgeInsets.only(right: 20.0),
                child: _switchSearchMode())
          ],
        ),
        body: Center(
          child: FutureBuilder<List<ProgramLink>>(
            future: widget.programLinks,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return _buildView(context, snapshot.data);
              } else if (snapshot.hasError) {
                return ErrorDisplay(snapshot.error);
              }

              return CircularProgressIndicator();
            },
          ),
        ));
  }

  Widget _buildView(BuildContext context, List<ProgramLink> programLinks) {
    programLinks = programLinks
        .where((programLink) =>
            programLink.name.toLowerCase().contains(_searchInput.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: programLinks.length,
      itemBuilder: (context, index) {
        return ListTile(
            title: Text(programLinks[index].name),
            subtitle: Text(programLinks[index].songCount),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ProgramPage(
                          program: fetchProgram(programLinks[index].id))));
            });
      },
    );
  }
}
