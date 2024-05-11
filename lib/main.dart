import 'package:flutter/material.dart';
import 'sender_screen.dart';
import 'receiver_screen.dart';

void main() {
  runApp(MaterialApp(
    home: HomeScreen(),
  ));
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('WebRTC Demo')),
        body: Center(
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
        ElevatedButton(
        onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SenderScreen()),
      );
    },
    child: Text('Go to Sender'),
        ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ReceiverScreen()),
              );
            },
            child: Text('Go to Receiver'),
          ),
        ],
        ),
        ),
    );
  }
}
