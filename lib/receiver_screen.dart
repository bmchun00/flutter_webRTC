import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class ReceiverScreen extends StatefulWidget {
  @override
  _ReceiverScreenState createState() => _ReceiverScreenState();
}

class _ReceiverScreenState extends State<ReceiverScreen> {
  final _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    initRenderer();
  }

  @override
  void dispose() {
    _remoteRenderer.dispose();
    super.dispose();
  }

  Future<void> initRenderer() async {
    await _remoteRenderer.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Receiver Stream'),
      ),
      body: RTCVideoView(_remoteRenderer),
      floatingActionButton: FloatingActionButton(
        onPressed: () => print("Implement receive offer logic here"),
        child: Icon(Icons.call_received),
      ),
    );
  }
}
