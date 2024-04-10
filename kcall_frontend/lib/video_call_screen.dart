// video_call_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'webrtc_helper.dart';

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({super.key});

  @override
  VideoCallScreenState createState() => VideoCallScreenState();
}

class VideoCallScreenState extends State<VideoCallScreen> {
  late WebRTCHelper webRTCHelper;
  String callStatus = '';

  @override
  void initState() {
    super.initState();
    webRTCHelper = WebRTCHelper(
      updateCallState: (message) {
        setState(() {
          callStatus = message;
        });
      },
    );
    webRTCHelper.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("K Call"),
        ),
        body: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                Expanded(
                  child: RTCVideoView(webRTCHelper.localRenderer),
                ),
                Expanded(
                  child: RTCVideoView(webRTCHelper.remoteRenderer),
                ),
              ],
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  if (callStatus.isEmpty ||
                      callStatus == "Call ended" ||
                      callStatus == "Call rejected")
                    ElevatedButton(
                      onPressed: () => webRTCHelper.call(),
                      child: const Text('Appeler'),
                    ),
                  if (callStatus == "Incoming call...")
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () => webRTCHelper.acceptCall(),
                          child: const Text('Accepter'),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: () => webRTCHelper.rejectCall(),
                          child: const Text('Refuser'),
                        ),
                      ],
                    ),
                  if (callStatus == "Call Active" ||
                      callStatus == "Call Accepted")
                    ElevatedButton(
                      onPressed: () => webRTCHelper.endCall(),
                      child: const Text('Raccrocher'),
                    ),
                ],
              ),
            ),
          ],
        ));
  }

  @override
  void dispose() {
    webRTCHelper.dispose();
    super.dispose();
  }
}
