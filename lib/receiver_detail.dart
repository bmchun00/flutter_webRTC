import 'package:client/signaling_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class ReceiverDetail extends StatefulWidget {
  late String sender_id;
  late String sender_sdp;

  ReceiverDetail(this.sender_id,this.sender_sdp);

  @override
  _ReceiverDetailState createState() => _ReceiverDetailState(sender_id,sender_sdp);
}

class _ReceiverDetailState extends State<ReceiverDetail> {
  late RTCPeerConnection _peerConnection;
  late String _sender_id;
  late String _sender_sdp;
  SignalingClient? _signalingClient;

  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  _ReceiverDetailState(this._sender_id,this._sender_sdp);


  @override
  void initState() {
    super.initState();
    initRenderers();
    _signalingClient = SignalingClient("ws://localhost:6789", null, _addCandi, null);
    _signalingClient?.connect();
    _createPeerConnection();
  }

  Future<void> initOffer() async {
    await _peerConnection.setRemoteDescription(RTCSessionDescription(_sender_sdp, 'offer'));
  }

  Future<void> sendAnswer() async{
    RTCSessionDescription answer = await _peerConnection.createAnswer();
    await _peerConnection.setLocalDescription(answer);

    _signalingClient?.sendAnswerToSignalingServer(answer, _sender_id);
  }

  Future<void> initRenderers() async {
    await _remoteRenderer.initialize();
  }

  Future<void> _addCandi(candidate) async{
    await _peerConnection.addCandidate(candidate);
  }

  Future<void> _createPeerConnection() async {
    Map<String, dynamic> configuration = {
      'iceServers': [
        {'url': 'stun:stun.l.google.com:19302'}
      ]
    };

    _peerConnection = await createPeerConnection(configuration);


    _peerConnection.onAddStream = (stream) {
      _remoteRenderer.srcObject = stream;
    };

    _peerConnection.onIceCandidate = (candidate) {
      _signalingClient?.sendCandidateToSignalingServer(candidate, _sender_id);
      // Receive and add candidate
    };
    await initOffer();
    // Answer 생성 및 시그널링 서버로 전송 로직 추가 필요
    await sendAnswer();

    _peerConnection.onIceConnectionState = (RTCIceConnectionState state) {
      print("R) ICE Connection State Changed: $state");
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected) {
        print("R) ICE Connection is successfully established.");

      }
    };

    _peerConnection.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty && event.track.kind == 'video') {
        // 이벤트에서 미디어 스트림을 받고, 해당 스트림을 재생할 수 있습니다.
        print("Received media stream");
        setState(() {
          _remoteRenderer.srcObject = event.streams.first;
        });
      }
    };

  }

  @override
  void dispose() {
    _remoteRenderer.dispose();
    _peerConnection.close();
    _signalingClient?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Receiver Stream'),
      ),
      body: RTCVideoView(_remoteRenderer),
    );
  }
}