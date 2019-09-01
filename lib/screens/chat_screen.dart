import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = Firestore.instance;
FirebaseUser loggedInUser;

class ChatScreen extends StatefulWidget {
  //static constant so we don't have to create a new object of this class to access it
  static const String id = 'chat_screen';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

//create final properties for our Cloud Firestore and FirebaseAuth classes
//we set these properties to the static instance variables in the respective classes
//create a property of type FirebaseUser to store the logged in user details
//create a String property that will store the message text
class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  String messageText;

  @override
  void initState() {
    super.initState();

    getCurrentUser();
  }

  //this method calls the currentUser method of the _auth class to get the current user
  //this all happens asynchronously
  //if the returned user data is not null, set the loggedInUser property to what is returned
  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser();

      if (user != null) {
        loggedInUser = user;
      }
    } catch (e) {
      print(e);
    }
  }

  //now for our stream
  //this is essentially listening for changes in our Cloudstore database
  //we loop through our messages collection(table) to extract each document(id)
  //we then loop through each document to get the message data out
  //the message data will contain our sender and text fields
//  void messagesStream() async {
//    await for (var snapshot in _firestore.collection('messages').snapshots()) {
//      for (var message in snapshot.documents) {
//        print(message.data);
//      }
//    }
//  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              //Implement logout functionality
              _auth.signOut();
              Navigator.pop(context);
//              messagesStream();
            },
          ),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      //clear the text field when the user taps on the send button
                      messageTextController.clear();
                      //we use the collection method of the _firestore instance to add messages to our database
                      _firestore.collection('messages').add({
                        'text': messageText,
                        'sender': loggedInUser.email,
                      });
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//we have refactored our MessageStream
//we are using a StreamBuilder which allows us to build widgets from our stream
//we know the stream is going to contain QuerySnapshot objects
//we set the stream property of the StreamBuilder to our actual stream
//we set the builder property to an anonymous function that takes 2 inputs, the current build context and an object of the AsyncSnapshot class (snapshot)
//the object of the AsyncSnapshot class contains our QuerySnapshot from Firestore so we can dig into it to get our data
//we check if the snapshot has no data, if not, we display a progress indicator until it does have data
class MessageStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('messages').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
            ),
          );
        }

        //snapshot contains all of the data in our Firestore
        //data contains each document in our Firestore
        //documents represents each document in our Firestore
        //each document contains a text and sender record
        final messages = snapshot.data.documents.reversed;

        //initialise an empty list of our custom MessageBubble widgets
        List<MessageBubble> messageBubbles = [];

        //loop through every "document" and assign the text and sender records to final variables
        for (var message in messages) {
          final messageText = message.data['text'];
          final messageSender = message.data['sender'];

          //check if the current user of the message is the logged in user
          final currentUser = loggedInUser.email;

          //create an object of our MessageBubble widget and set the text and sender properties
          final messageBubble = MessageBubble(
            text: messageText,
            sender: messageSender,
            isMe: currentUser == messageSender,
          );

          //add the new object of our MessageBubble object to our messageBubbles list
          messageBubbles.add(messageBubble);
        }

        //return an Expanded widget with a ListView widget as its child
        //the ListView's children property is set to our messageBubbles list
        //we use an Expanded widget so the ListView will only consume as much space as it is allowed to
        return Expanded(
          child: ListView(
            reverse: true,
            children: messageBubbles,
          ),
        );
      },
    );
  }
}

//our custom MessageBubble widget
//constructor sets text and sender properties when new object of this class is created
class MessageBubble extends StatelessWidget {
  MessageBubble({this.text, this.sender, this.isMe});

  final String text;
  final String sender;
  final bool isMe;

  //styling of message bubbles
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            sender,
            style: TextStyle(
              fontSize: 12.0,
              color: Colors.black54,
            ),
          ),
          Material(
            borderRadius:
                isMe ? kPersonalBubbleRadius : kNonPersonalBubbleRadius,
            elevation: 5.0,
            color: isMe ? Colors.lightBlueAccent : Colors.lightGreen,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
