import 'dart:async';

import 'package:flutter/material.dart';

import '../models/account.dart';
import '../models/exchange.dart';
import '../services/account.dart';
import '../services/bidebox.dart';
import '../utils.dart';
import 'account.dart';

class BideBoxWidget extends StatelessWidget {
  final Future<List<Exchange>> exchanges;

  BideBoxWidget({Key key, this.exchanges}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<List<Exchange>>(
        future: this.exchanges,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _buildView(context, snapshot.data);
          } else if (snapshot.hasError) {
            return Center(
              child: ErrorDisplay(snapshot.error),
            );
          }

          return CircularProgressIndicator();
        },
      ),
    );
  }

  Widget _buildView(BuildContext context, List<Exchange> messages) {
    return ListView.builder(
        itemCount: messages.length,
        itemBuilder: (BuildContext context, int index) {
          Exchange message = messages[index];
          return ListTile(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AccountPage(
                            account: fetchAccount(message.recipient.id),
                            defaultPage: 2,
                          ))),
              title: Text(
                message.recipient.name,
              ),
              subtitle: Text('${message.sentCount} ${message.receivedCount}'),
              leading: GestureDetector(
                  onTap: () => showDialog(
                        context: context,
                        builder: (BuildContext context) =>
                            MessageEditor(message.recipient),
                      ),
                  child: Icon(Icons.mail)));
        });
  }
}

class MessageEditor extends StatefulWidget {
  final AccountLink _accountLink;

  MessageEditor(this._accountLink);

  @override
  _MessageEditorState createState() => _MessageEditorState();
}

class _MessageEditorState extends State<MessageEditor> {
  final _newMessageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
      actions: [
        RaisedButton.icon(
          icon: Icon(Icons.send),
          label: Text("Envoyer"),
          onPressed: () async {
            bool status = await sendMessage(
                _newMessageController.text, widget._accountLink.id);
            Navigator.of(context).pop(status);
          },
        )
      ],
      title: Text('Message pour ${widget._accountLink.name}'),
      content: TextFormField(
          maxLength: 500,
          maxLines: 5,
          controller: _newMessageController,
          decoration: InputDecoration(
            hintText: 'Entrez votre message ici',
          )),
    );
  }
}
