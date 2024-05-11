import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class SignalingClient {
  WebSocketChannel? _channel;
  String _url;

  SignalingClient(this._url);

  void connect() {
    _channel = WebSocketChannel.connect(Uri.parse(_url));
    _channel!.stream.listen(_onMessageReceived);
  }

  void _onMessageReceived(dynamic message) { //세션 키와 answer, ICE를 받을 수 있음
    print("Message received from signaling server: $message");

  }

  void sendOfferToSignalingServer(RTCSessionDescription description) {
    var message = {
      'type': 'offer',
      'sdp': description.sdp
    };
    print(message);
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

  void disconnect() {
    _channel?.sink.close();
  }
}