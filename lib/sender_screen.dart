import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'signaling_client.dart';

class SenderScreen extends StatefulWidget {
  @override
  _SenderScreenState createState() => _SenderScreenState();
}

class _SenderScreenState extends State<SenderScreen> {
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  late RTCPeerConnection _peerConnection;
  SignalingClient? _signalingClient;
  List _candi = [];
  List pendingCandidates = [];

  void sendAllCandi(String target_id){
    for(RTCIceCandidate i in _candi)
      _signalingClient?.sendCandidateToSignalingServer(i, target_id);
  }

  @override
  void initState() {
    super.initState();
    initRenderer();
    _signalingClient = SignalingClient("ws://localhost:6789", sendAllCandi, _addCandi, _setSDP);
    _signalingClient?.connect();
    _setupConnection();
  }
  void _setSDP(sdp) async {
    RTCSessionDescription description = RTCSessionDescription(sdp, 'answer');
    await _peerConnection.setRemoteDescription(description);
    processPendingCandidates();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _localStream?.dispose();
    _peerConnection.close();
    _signalingClient?.disconnect();
    super.dispose();
  }

  Future<void> initRenderer() async {
    await _localRenderer.initialize();
  }

  Future<void> _setupConnection() async {
    _localStream = await _getUserMedia();
    _localRenderer.srcObject = _localStream;

    _peerConnection = await _createPeerConnection();

    _peerConnection.addStream(_localStream!);

    _peerConnection.onIceConnectionState = (RTCIceConnectionState state) {
      print("S) ICE Connection State Changed: $state");
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected) {
        print("S) ICE Connection is successfully established.");

      }
    };

    _createOffer();
  }

  void _addCandi(candidate) {
    pendingCandidates.add(candidate);
  }

  Future<MediaStream> _getUserMedia() async {
    final constraints = {
      'audio': true,
      'video': {
        'facingMode': 'user',
      },
    };
    return await navigator.mediaDevices.getUserMedia(constraints);
  }

  Future<RTCPeerConnection> _createPeerConnection() async {
    final Map<String, dynamic> configuration = {
      'iceServers': [
        {'url': 'stun:stun.l.google.com:19302'},
      ]
    };
    final Map<String, dynamic> offerSdpConstraints = {
      'mandatory': {
        'OfferToReceiveAudio': false,
        'OfferToReceiveVideo': false,
      },
      'optional': [],
    };

    RTCPeerConnection _peerConnection = await createPeerConnection(configuration, offerSdpConstraints);
    _peerConnection.onIceCandidate = (candidate) {
      _candi.add(candidate);
    };
    return _peerConnection;
  }

  void _createOffer() async {
    RTCSessionDescription description = await _peerConnection.createOffer({'offerToReceiveVideo': 0, 'offerToReceiveAudio': 0});
    await _peerConnection.setLocalDescription(description);

    // Send the offer to the remote peer through the signaling server
    _sendOfferToSignalingServer(description);
  }

  void _sendOfferToSignalingServer(RTCSessionDescription description) {
    _signalingClient?.sendOfferToSignalingServer(description);
    //print('Send offer to signaling server: ${description.sdp}');
  }

  void processPendingCandidates() async {
    for (RTCIceCandidate candidate in pendingCandidates) {
      await _peerConnection.addCandidate(candidate);
    }
    pendingCandidates.clear(); // 처리 후 목록 비우기
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sender Stream'),
      ),
      body: RTCVideoView(_localRenderer),
      floatingActionButton: FloatingActionButton(
        onPressed: _createOffer,
        child: Icon(Icons.videocam),
      ),
    );
  }
}
