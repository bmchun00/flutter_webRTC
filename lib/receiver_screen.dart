import 'package:client/receiver_detail.dart';
import 'package:client/signaling_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class ReceiverScreen extends StatefulWidget {
  @override
  _ReceiverScreenState createState() => _ReceiverScreenState();
}

class _ReceiverScreenState extends State<ReceiverScreen> {
  final _remoteRenderer = RTCVideoRenderer();
  late WebSocketReceiver webSocketManager;
  List<dynamic> _offer_list_id = [];
  List<dynamic> _offer_list_sdp = [];

  @override
  void initState() {
    super.initState();
    webSocketManager = WebSocketReceiver(
      onDataReceived: (idList, sdpList) {
        setState(() {
          _offer_list_id = idList;
          _offer_list_sdp = sdpList;
        });
      },
    );
    initRenderer();
    webSocketManager.getOfferListFromSignalingServer();
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
      body: ListView.builder(
        itemCount: _offer_list_id.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 2,
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              title: Text(_offer_list_id[index], style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Subtitle ${index + 1}"),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                // 클릭 시 수행할 액션
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ReceiverDetail(_offer_list_id[index], _offer_list_sdp[index]),
                ));
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          _offer_list_id = [];
          _offer_list_sdp = [];
          webSocketManager.getOfferListFromSignalingServer();
        },
        child: Icon(Icons.call_received),
      ),

    );
  }
}
