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
  bool _isFrontCamera = false;
  MediaStreamTrack? videoTrack;
  MediaStreamTrack? audioTrack;

  void initVars(){
    _candi = [];
    pendingCandidates = [];
    _isFrontCamera = false;
    videoTrack = null;
    audioTrack = null;
  }


  void sendAllCandi(String target_id){
    for(RTCIceCandidate i in _candi)
      _signalingClient?.sendCandidateToSignalingServer(i, target_id);
  }

  @override
  void initState() {
    super.initState();
    initRenderer();
    _signalingClient = SignalingClient("ws://192.168.35.159:6789", sendAllCandi, _addCandi, _setSDP);
    _signalingClient?.connect();
    _setupConnection();
  }


  void _setSDP(sdp) async {
    RTCSessionDescription description = RTCSessionDescription(sdp, 'answer');
    await _peerConnection.setRemoteDescription(description);
    await processPendingCandidates();
  }

  void _showBlackScreen(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false, // 모달이 투명하게
        pageBuilder: (BuildContext context, _, __) {
          return Scaffold(
            backgroundColor: Colors.black.withOpacity(0.99), // 반투명 검은색 배경
            body: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.of(context).pop(); // 화면 탭 시 모달 닫기
              },
              child: Center(
                child: Text(
                  'Tap anywhere to return',
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
              ),
            ),
          );
        },
      ),
    );
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

  Future<void> _initStream() async {
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {
        'facingMode': _isFrontCamera ? 'user' : 'environment',
      },
    });
    _localRenderer.srcObject = _localStream;
    videoTrack = _localStream!.getVideoTracks().first;
    audioTrack = _localStream!.getAudioTracks().first;

    // Add each track to the peer connection
    if (videoTrack != null) {
      _peerConnection!.addTrack(videoTrack!, _localStream!);
    }
    if (audioTrack != null) {
      _peerConnection!.addTrack(audioTrack!, _localStream!);
    }

    setState(() {
      
    });
  }

  Future<void> _setupConnection() async {
    _peerConnection = await _createPeerConnection();
    await _initStream();

    _peerConnection.onIceConnectionState = (RTCIceConnectionState state) {
      print("S) ICE Connection State Changed: $state");
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected) {
        print("S) ICE Connection is successfully established.");
      }
      if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
        print("Connection is disconnected. Attempting to reconnect...");
        reconnectConnection();
      }
    };

    _createOffer();
  }

  Future<void> reconnectConnection() async {
    var route = MaterialPageRoute(builder: (context) => SenderScreen());
    Navigator.of(context).pop();
    Navigator.of(context).push(route);
  }


  void _addCandi(candidate) {
    pendingCandidates.add(candidate);
    print(pendingCandidates);
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

  Future<void> processPendingCandidates() async {

    print("S) cand add start");
    for (RTCIceCandidate candidate in pendingCandidates) {
      await _peerConnection.addCandidate(candidate);
    }

    print("S) cand add fin");
    pendingCandidates.clear(); // 처리 후 목록 비우기
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sender Stream'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              child: RTCVideoView(_localRenderer),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  heroTag: "btn1",
                  onPressed: (){
                    _isFrontCamera = !_isFrontCamera;
                    _initStream();
                  },
                  child: Icon(Icons.switch_camera),
                ),
                FloatingActionButton(
                  heroTag: "btn2",
                  onPressed: () => _showBlackScreen(context),
                  child: Icon(Icons.dark_mode_outlined),
                ),
                FloatingActionButton(
                  heroTag: "btn3",
                  onPressed: () => reconnectConnection(),
                  child: Icon(Icons.restart_alt),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
