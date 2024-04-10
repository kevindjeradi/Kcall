// webrtc_helper.dart
import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/io.dart';

class WebRTCHelper {
  late RTCPeerConnection peerConnection;
  late RTCVideoRenderer localRenderer;
  late RTCVideoRenderer remoteRenderer;
  final _channel = IOWebSocketChannel.connect('ws://10.68.244.236:3000');
  Function(String message)? updateCallState;

  WebRTCHelper({this.updateCallState});

  MediaStream? localStream;

  Future<void> initialize() async {
    localRenderer = RTCVideoRenderer();
    remoteRenderer = RTCVideoRenderer();
    await localRenderer.initialize();
    await remoteRenderer.initialize();
    peerConnection = await _createPeerConnection();
    _channel.stream.listen(_handleSignaling);
  }

  Future<RTCPeerConnection> _createPeerConnection() async {
    final Map<String, dynamic> configuration = {
      "iceServers": [
        {"urls": "stun:stun.l.google.com:19302"},
      ]
    };

    RTCPeerConnection pc = await createPeerConnection(configuration);
    localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': true,
    });

    localRenderer.srcObject = localStream;
    localStream!.getTracks().forEach((track) {
      pc.addTrack(track, localStream!);
    });

    pc.onIceConnectionState = (RTCIceConnectionState state) {
      print(
          "------------------------------------------------------ICE connection state changed: $state");
    };

    pc.onConnectionState = (RTCPeerConnectionState state) {
      print(
          "------------------------------------------------------Peer connection state changed: $state");
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        print(
            "------------------------------------------------------Call is ongoing...");
      } else if (state ==
          RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        print(
            "------------------------------------------------------Call has been disconnected.");
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        print(
            "------------------------------------------------------Call failed.");
      }
    };

    pc.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        // Attach the first stream with video tracks to the remote renderer
        final stream = event.streams.first;
        if (stream.getVideoTracks().isNotEmpty) {
          print("Attaching remote stream");
          remoteRenderer.srcObject = stream;
        }
      }
    };

    pc.onIceCandidate = (candidate) {
      _channel.sink.add(jsonEncode({
        'type': 'candidate',
        'candidate': candidate.toMap(),
      }));
    };

    return pc;
  }

  void resetForNewCall() async {
    dispose(); // Clean up existing resources
    await initialize(); // Reinitialize everything for a new call
  }

  void call() async {
    updateCallState?.call("Ringing...");
    print('Creating offer and sending...');
    final offer = await peerConnection.createOffer();
    await peerConnection.setLocalDescription(offer);
    _channel.sink.add(jsonEncode({
      'type': 'offer',
      'offer': offer.toMap(),
    }));
    print('Offer sent: ${offer.toMap()}');
  }

  void _handleSignaling(dynamic message) {
    String messageString;

    // Check if the message is binary data or a String
    if (message is String) {
      messageString = message;
    } else if (message is List<int>) {
      // If it's binary data, you might need to decode it depending on your protocol
      // For demonstration, converting List<int> (binary data) to a String
      messageString = utf8.decode(message);
    } else {
      print("Unknown data type received through WebSocket");
      return;
    }

    final parsedMessage = jsonDecode(messageString);
    print('Received signaling message: $parsedMessage');
    switch (parsedMessage['type']) {
      case 'offer':
        updateCallState?.call("Incoming call...");
        peerConnection
            .setRemoteDescription(
          RTCSessionDescription(
              parsedMessage['offer']['sdp'], parsedMessage['offer']['type']),
        )
            .then((_) {
          _answerCall();
        });
        break;
      case 'answer':
        peerConnection.setRemoteDescription(
          RTCSessionDescription(
              parsedMessage['answer']['sdp'], parsedMessage['answer']['type']),
        );
        break;
      case 'candidate':
        peerConnection.addCandidate(
          RTCIceCandidate(
            parsedMessage['candidate']['candidate'],
            parsedMessage['candidate']['sdpMid'],
            parsedMessage['candidate']['sdpMLineIndex'],
          ),
        );
        break;
      case 'call-ended':
        updateCallState?.call("Call ended");
        resetForNewCall();
        break;

      default:
        print('Unknown signaling message type');
    }
  }

  void _answerCall() async {
    print('Creating answer...');
    final answer = await peerConnection.createAnswer();
    await peerConnection.setLocalDescription(answer);
    _channel.sink.add(jsonEncode({
      'type': 'answer',
      'answer': answer.toMap(),
    }));
    print('Answer sent: ${answer.toMap()}');
  }

  void acceptCall() async {
    print('Call accepted by user.');
    updateCallState?.call("Call Accepted");

    // Assume we have already received an offer at this point,
    // and the local description is set with the answer created in _answerCall().
    // Now, we need to notify the caller that the call has been accepted.
    // This is where you send a 'call-accepted' message back through your signaling channel.
    _channel.sink.add(jsonEncode({
      'type': 'call-accepted',
    }));
  }

  void rejectCall() {
    print('Call rejected by user.');
    updateCallState?.call("Call rejected");

    // Notify the caller that the call has been rejected.
    // This involves sending a 'call-rejected' message back through your signaling channel.
    _channel.sink.add(jsonEncode({
      'type': 'call-rejected',
    }));

    resetForNewCall();
  }

  void endCall() {
    print('Ending the call.');
    updateCallState?.call("Call ended");

    // Send a 'call-ended' message to inform the other participant
    _channel.sink.add(jsonEncode({
      'type': 'call-ended',
    }));

    resetForNewCall();
  }

  void dispose() {
    if (localRenderer.srcObject != null) {
      localRenderer.srcObject!.getTracks().forEach((track) {
        track.stop();
      });
      localRenderer.srcObject = null;
    }
    localRenderer.dispose();
    if (remoteRenderer.srcObject != null) {
      remoteRenderer.srcObject!.getTracks().forEach((track) {
        track.stop();
      });
      remoteRenderer.srcObject = null;
    }
    remoteRenderer.dispose();
    peerConnection.close();
    _channel.sink.close();
  }
}
