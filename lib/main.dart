import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:simple_coverflow/simple_coverflow.dart';
import 'package:http/http.dart' as http;

import 'utils.dart';
import 'dart:async';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Sufficient Goldfish',
      theme: new ThemeData.light(), // switch to ThemeData.day() when available
      home: new MatchPage(),
    );
  }
}

class MatchPage extends StatefulWidget {
  @override
  State<MatchPage> createState() => new MatchPageState();
}

class MatchPageState extends State<MatchPage> {
  DocumentReference _myProfile;
  List<MatchData> _potentialMatches;
  Set<String> _nonMatches;
  final String cloudFunctionUrl =
      'https://us-central1-sufficientgoldfish.cloudfunctions.net/matchFish?id=';

  @override
  void initState() {
    super.initState();
    _potentialMatches = [];
    _nonMatches = new Set<String>();
    _myProfile = Firestore.instance.collection('profiles').document();
    fetchMatchData();
  }

  fetchMatchData() {
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Sufficient Goldfish'),
      ),
      body: body,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: new Builder(builder: buildFab),
    );
  }

  Widget buildFab(BuildContext context) {
    return new Container();
  }

  Future<Null> _saveLocation(BuildContext context) async {
  }

  Widget widgetBuilder(BuildContext context, int index) {
    return new Container();
  }


  disposeDismissed(int card, DismissDirection direction) {
  }
}

class ProfileCard extends StatelessWidget {
  final MatchData data;

  ProfileCard(this.data);

  @override
  Widget build(BuildContext context) {
    return new Card(
        child: new Container(
      padding: new EdgeInsets.all(16.0),
      child: new Column(children: <Widget>[
        new Expanded(flex: 1, child: showProfilePicture(data)),
        _showData(data.name, data.favoriteMusic, data.favoritePh),
      ]),
    ));
  }

  Widget _showData(String name, String music, String pH) {
    Text nameWidget = new Text(name,
        style: new TextStyle(fontWeight: FontWeight.bold, fontSize: 32.0));
    Text musicWidget = new Text('Favorite music: $music',
        style: new TextStyle(fontStyle: FontStyle.italic, fontSize: 16.0));
    Text phWidget = new Text('Favorite pH: $pH',
        style: new TextStyle(fontStyle: FontStyle.italic, fontSize: 16.0));
    List<Widget> children = [nameWidget, musicWidget, phWidget];
    return new Container();
  }

  Widget showProfilePicture(MatchData matchData) {
    return new Container();
  }
}

class FinderPage extends StatefulWidget {
  final double targetLatitude;
  final double targetLongitude;
  final AudioTools audioTools = new AudioTools();

  FinderPage(this.targetLatitude, this.targetLongitude);

  @override
  _FinderPageState createState() => new _FinderPageState(audioTools);
}

class _FinderPageState extends State<FinderPage> {
  LocationTools locationTools;
  AudioTools audioTools;
  double latitude = 0.0;
  double longitude = 0.0;
  double accuracy = 0.0;
  final String searchingAudio =
      'https://freesound.org/data/previews/28/28693_98464-lq.mp3';
  final String foundAudio =
      'https://freesound.org/data/previews/397/397354_4284968-lq.mp3';

  _FinderPageState(this.audioTools) {
    audioTools.initAudioLoop(searchingAudio);
  }

  void _updateLocation(Map<String, double> currentLocation) {
    setState(() {
      latitude = currentLocation['latitude'];
      longitude = currentLocation['longitude'];
      accuracy = currentLocation['accuracy'];
    });
  }

  double _getLocationDiff() {
    int milesBetweenLines = 69;
    int feetInMile = 5280;
    int desiredFeetRange = 15;
    double multiplier = 2 * milesBetweenLines * feetInMile / desiredFeetRange;
    double latitudeDiff = (latitude - widget.targetLatitude).abs() * multiplier;
    double longitudeDiff =
        (longitude - widget.targetLongitude).abs() * multiplier;
    if (latitudeDiff > 1) {
      latitudeDiff = 1.0;
    }
    if (longitudeDiff > 1) {
      longitudeDiff = 1.0;
    }
    double diff = (latitudeDiff + longitudeDiff) / 2;
    return diff;
  }

  Color _colorFromLocationDiff() {
    return Color.lerp(Colors.red, Colors.blue, _getLocationDiff());
  }

  @override
  Widget build(BuildContext context) {
    return new Container(
      color: _colorFromLocationDiff(),
      child: new Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            new Text(
              'Locate your match!',
              style: new TextStyle(
                  color: Colors.black,
                  fontSize: 32.0,
                  decoration: TextDecoration.none),
            ),
          ]),
    );
  }
}