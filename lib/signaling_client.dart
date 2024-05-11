import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class SignalingClient {
  WebSocketChannel? _channel;
  String _url;
  String?_id;
  List<Map<String, dynamic>> offers = []; //리시버에만 해당

  SignalingClient(this._url);

  void connect() {
    _channel = WebSocketChannel.connect(Uri.parse(_url));
    _channel!.stream.listen(_onMessageReceived);
  }

  void _onMessageReceived(dynamic message) { //세션 키와 answer, ICE를 받을 수 있음, offer도
    try{
      Map<String, dynamic> msg = jsonDecode(message);
      if(msg['type'] == 'sessionId') _id = msg['sessionId'];
      else if(msg['type'] == 'answer') print('answer 받음');
      else if(msg['type'] == 'candidate') print('candidate 받음');
      else if(msg['type'] == 'streamers') print('offer들 : '+msg['sdp']);
    }
    catch(e){
      print(e);
      print("Message received from signaling server: $message");
    }
  }

  void sendOfferToSignalingServer(RTCSessionDescription description) {
    var message = {
      'type': 'offer',
      'sdp': description.sdp
    };
    _channel!.sink.add(jsonEncode(message));
    print("Offer sent to signaling server");
  }

  void sendCandidateToSignalingServer(RTCIceCandidate candidate) {
    var message = {
      'type': 'candidate',
      'candidate': {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      }
    };
    _channel!.sink.add(jsonEncode(message));
    print("Candidate sent to signaling server");
  }

  void getOfferListFromSignalingServer(){
    var message = {
      'type': 'streamers'
    };
    _channel!.sink.add(jsonEncode(message));
  }

  void disconnect() {
    _channel?.sink.close();
  }
}