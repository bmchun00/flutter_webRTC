import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter/foundation.dart';

class WebSocketReceiver {
  late WebSocketChannel channel;
  Function(List<dynamic>,List<dynamic>)? onDataReceived;
  String? _id;

  WebSocketReceiver({this.onDataReceived}) {
    channel = WebSocketChannel.connect(
      Uri.parse('ws://localhost:6789'),
    );

    channel.stream.listen((data) {
      Map<String, dynamic>? msg = jsonDecode(data);
      if(msg?['type']=='sessionId') _id = msg?['sessionId'];
      else if(msg?['type']=='streamers'){
        // 콜백 함수를 통해 데이터 처리
        List<dynamic> idList = msg?['id'];
        List<dynamic> sdpList = msg?['sdp'];
        if (onDataReceived != null) {
          onDataReceived!(idList, sdpList);
        }
      }
      else print(msg);
    });
  }

  void getOfferListFromSignalingServer(){
    var message = {
      'type': 'streamers'
    };
    channel.sink.add(jsonEncode(message));
  }

  void dispose() {
    channel.sink.close();
  }
}

class SignalingClient {
  WebSocketChannel? _channel;
  String _url;
  String?_id;
  Function? _sendCandi;

  SignalingClient(this._url, this._sendCandi);

  void connect() {
    _channel = WebSocketChannel.connect(Uri.parse(_url));
    _channel!.stream.listen(_onMessageReceived);
  }

  Map<String, String>? _onMessageReceived(dynamic message) { //세션 키와 answer, ICE를 받을 수 있음, offer도
    try{
      Map<String, dynamic> msg = jsonDecode(message);
      if(msg['type'] == 'sessionId') _id = msg['sessionId'];
      else if(msg['type'] == 'answer'){
        if(_sendCandi != null){
          _sendCandi!(msg['my_id']);
        }
      }
      else if(msg['type'] == 'candidate') print('candidate 받음');
    }
    catch(e){
      print(e);
      print("Message received from signaling server: $message");
    }
    return null;
  }

  void sendOfferToSignalingServer(RTCSessionDescription description) {
    var message = {
      'type': 'offer',
      'sdp': description.sdp
    };
    _channel!.sink.add(jsonEncode(message));
    print("Offer sent to signaling server");
  }

  void sendAnswerToSignalingServer(RTCSessionDescription description, String target_id) {
    var message = {
      'type': 'answer',
      'sdp': description.sdp,
      'target_id': target_id,
      'my_id':_id
    };
    _channel!.sink.add(jsonEncode(message));
    print("answer sent to signaling server");
  }

  void sendCandidateToSignalingServer(RTCIceCandidate candidate, String target_id) {
    var message = {
      'type': 'candidate',
      'candidate': {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      },
      'target_id': target_id
    };
    _channel!.sink.add(jsonEncode(message));
    print("Candidate sent to signaling server");
  }

  void disconnect() {
    _channel?.sink.close();
  }
}