import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:simple_coverflow/simple_coverflow.dart';
import 'package:sensors/sensors.dart';

import 'utils.dart';

const baseAudio =
    'http://freesound.org/data/previews/243/243953_1565498-lq.mp3';
const dismissedAudio =
    'http://freesound.org/data/previews/398/398025_7586736-lq.mp3';
const savedAudio =
    'http://freesound.org/data/previews/189/189499_1970026-lq.mp3';
const baseName = 'base';
const dismissedName = 'dismissed';
const savedName = 'saved';
const reservedBy = 'reservedBy';

AudioTools audioTools = AudioTools();

Future<void> main() async {
  var deviceId = await DeviceTools.getDeviceId();
  runApp(MyApp(deviceId));
}

class MyApp extends StatelessWidget {
  final String deviceId;
  MyApp(this.deviceId);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sufficient Goldfish',
      theme: ThemeData.light(), // switch to ThemeData.day() when available
      home: FishPage(deviceId),
      debugShowCheckedModeBanner: false,
    );
  }
}

class FishPage extends StatefulWidget {
  final String deviceId;

  FishPage(this.deviceId);

  @override
  State<FishPage> createState() => FishPageState();
}

class FishPageState extends State<FishPage> {
  DocumentSnapshot _undoData;

  @override
  void initState() {
    super.initState();
    accelerometerEvents.listen((AccelerometerEvent event) {
      if (event.y.abs() >= 20 && _undoData != null) {
        // Shake-to-undo last action.
        _removeFish(_undoData);
        _undoData = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body = new FutureBuilder(future: new Future(() async {
      await audioTools.loadFile(baseAudio, baseName);
      await audioTools.loadFile(dismissedAudio, dismissedName);
      await audioTools.loadFile(savedAudio, savedName);
    }), builder: (context, AsyncSnapshot snapshot) {
      switch (snapshot.connectionState) {
        case ConnectionState.done:
          audioTools.initAudioLoop(baseName);
          return StreamBuilder<QuerySnapshot>(
              stream: Firestore.instance.collection('profiles').snapshots,
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData) {
                  var fishList =
                      snapshot.data.documents.where((DocumentSnapshot aDoc) {
                    return aDoc.data[reservedBy] == widget.deviceId ||
                        !aDoc.data.containsKey(reservedBy);
                  }).toList();
                  if (fishList.length > 0)
                    return new FishOptionsView(
                        fishList, widget.deviceId, _reserveFish, _removeFish);
                }
                return Center(
                    child:
                        const Text('There are plenty of fish in the sea...'));
              });
        default:
          return Center(
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                CircularProgressIndicator(),
                Text('Gone Fishing...'),
              ]));
      }
    });

    return Scaffold(
        appBar: AppBar(
          title: Text('Sufficient Goldfish'),
          backgroundColor: Colors.indigo,
        ),
        body: Container(
            decoration: new BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    colors: [Colors.blue, Colors.lightBlueAccent])),
            child: body));
  }

  void _removeFish(DocumentSnapshot fishOfInterest) {
    var existingData = fishOfInterest.data;
    existingData.remove(reservedBy);
    fishOfInterest.reference.setData(existingData);
  }

  void _reserveFish(DocumentSnapshot fishOfInterest) {
    var fishData = fishOfInterest.data;
    fishData[reservedBy] = widget.deviceId;
    fishOfInterest.reference.setData(fishData);
  }
}

class FishOptionsView extends StatelessWidget {
  final String deviceId;
  final List<DocumentSnapshot> _fishList;
  final Function onAddedCallback;
  final Function onRemovedCallback;

  // NB: This assumes _fishList != null && _fishList.length > 0.
  FishOptionsView(this._fishList, this.deviceId, this.onAddedCallback,
      this.onRemovedCallback);

  @override
  Widget build(BuildContext context) {
    return CoverFlow(
        itemBuilder: (_, int index) {
          var fishOfInterest = _fishList[index];
          var isReserved = fishOfInterest.data[reservedBy] == deviceId;
          return ProfileCard(
              FishData.parseData(fishOfInterest),
              () => onAddedCallback(fishOfInterest),
              () => onRemovedCallback(fishOfInterest),
              isReserved);
        },
        dismissedCallback: (int card, DismissDirection direction) =>
            onDismissed(card, direction),
        itemCount: _fishList.length);
  }

  onDismissed(int card, _) {
    audioTools.playAudio(dismissedName);
    DocumentSnapshot fishOfInterest = _fishList[card];
    //_undoData = fishOfInterest;
  }
}

class ProfileCard extends StatelessWidget {
  final FishData data;
  final Function onAddedCallback;
  final Function onRemovedCallback;
  final bool isReserved;

  ProfileCard(
      this.data, this.onAddedCallback, this.onRemovedCallback, this.isReserved);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isReserved ? Colors.white30 : Colors.white,
      child: Column(children: _getCardContents()),
    );
  }

  List<Widget> _getCardContents() {
    List<Widget> contents = <Widget>[
      _showProfilePicture(data),
      _showData(data.name, data.favoriteMusic, data.favoritePh),
    ];
    contents.add(Row(children: [
      Expanded(
          child: FlatButton.icon(
              color: isReserved ? Colors.red : Colors.green,
              icon: Icon(isReserved ? Icons.not_interested : Icons.check),
              label: Text(isReserved ? 'Remove' : 'Add'),
              onPressed: () {
                audioTools.playAudio(isReserved ? dismissedName : savedName);
                isReserved ? onRemovedCallback() : onAddedCallback();
              }))
    ]));
    return contents;
  }

  Widget _showData(String name, String music, String pH) {
    var subHeadingStyle =
        TextStyle(fontStyle: FontStyle.italic, fontSize: 16.0);
    Widget nameWidget = Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          name,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32.0),
          textAlign: TextAlign.center,
        ));
    Text musicWidget = Text('Favorite music: $music', style: subHeadingStyle);
    Text phWidget = Text('Favorite pH: $pH', style: subHeadingStyle);
    List<Widget> children = [nameWidget, musicWidget, phWidget];
    return Column(
        children: children
            .map((child) =>
                Padding(child: child, padding: EdgeInsets.only(bottom: 8.0)))
            .toList());
  }

  Widget _showProfilePicture(FishData fishData) {
    return Expanded(
      child: Image.network(
        fishData.profilePicture,
        fit: BoxFit.cover,
      ),
    );
  }
}
