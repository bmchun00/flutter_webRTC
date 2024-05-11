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
  RTCPeerConnection? _peerConnection;
  SignalingClient? _signalingClient;

  @override
  void initState() {
    super.initState();
    initRenderer();
    _signalingClient = SignalingClient("ws://localhost:6789");
    _signalingClient?.connect();
    _setupConnection();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _localStream?.dispose();
    _peerConnection?.close();
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
    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    _createOffer();
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

    RTCPeerConnection pc = await createPeerConnection(configuration, offerSdpConstraints);
    pc.onIceCandidate = (candidate) {
      _sendCandidateToSignalingServer(candidate);
    };
    return pc;
  }

  void _createOffer() async {
    RTCSessionDescription description = await _peerConnection!.createOffer({'offerToReceiveVideo': 0, 'offerToReceiveAudio': 0});
    await _peerConnection!.setLocalDescription(description);

    // Send the offer to the remote peer through the signaling server
    _sendOfferToSignalingServer(description);
  }

  void _sendOfferToSignalingServer(RTCSessionDescription description) {
    _signalingClient?.sendOfferToSignalingServer(description);
    //print('Send offer to signaling server: ${description.sdp}');
  }

  void _sendCandidateToSignalingServer(RTCIceCandidate candidate) {
    // Implement your signaling client here.
    //print('Send candidate to signaling server: ${candidate.candidate}');
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
