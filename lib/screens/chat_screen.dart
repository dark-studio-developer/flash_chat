import 'package:flash_chat/google_signIn_provider.dart';
import 'package:flash_chat/main.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:move_to_background/move_to_background.dart';

final _firestore = FirebaseFirestore.instance;
User loggedInUser;
String email;
String photoUrl;
bool isMessagePressed = false;
Color selectedMessageColor = Colors.amber[100];
MessageBubble messageSeleted;
String messageID;
bool iSNotificationsInitialized = false;
final _auth = FirebaseAuth.instance;

Color messageColor(bool isMe) {
  if (isMessagePressed) {
    return selectedMessageColor;
  } else
    return isMe ? Colors.lightBlueAccent : Colors.white;
}

class ChatScreen extends StatefulWidget {
  static const String id = 'chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();

  String messageText;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    getMessage();

    Future.delayed(const Duration(milliseconds: 3000), () {
      iSNotificationsInitialized = true;
    });
  }

  void getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
        email = user.email;
        photoUrl = user.photoURL;
      }
    } catch (e) {
      print(e);
    }
  }

  List<IconButton> showLongPressActions() {
    List<IconButton> iconButtonsList = [];

    iconButtonsList = [];

    IconButton copyButton = IconButton(
        icon: Icon(Icons.copy),
        onPressed: () {
          Clipboard.setData(ClipboardData(text: messageSeleted.text));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Copied'),
              duration: Duration(milliseconds: 500),
            ),
          );
        });

    IconButton deleteButton = IconButton(
        icon: Icon(Icons.delete),
        onPressed: () async {
          if (messageSeleted.isMe)
            deleteMessage(messageID);
          else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('You can not delete other\'s messages '),
                duration: Duration(milliseconds: 500),
              ),
            );
          }
        });

    iconButtonsList.add(copyButton);
    iconButtonsList.add(deleteButton);

    return iconButtonsList;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (isMessagePressed) {
          setState(() {
            isMessagePressed = false;
          });
        } else {
          MoveToBackground.moveTaskToBack();
          return false;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: null,
          actions: isMessagePressed
              ? showLongPressActions()
              : [
                  IconButton(
                      icon: Icon(Icons.logout),
                      onPressed: () {
                        final provider =
                            Provider.of<SignInProvider>(context, listen: false);
                        provider.logout();
                      }),
                ],
          title: Text('⚡️Chat'),
          backgroundColor: Colors.lightBlueAccent,
        ),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              MessagesStream(
                onLongPress: () {
                  setState(() {
                    isMessagePressed = true;
                    HapticFeedback.mediumImpact();
                  });
                },
              ),
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
                      onPressed: () async {
                        DateTime now = DateTime.now();

                        messageTextController.clear();
                        await _firestore.collection('messages').add({
                          'text': messageText,
                          'sender': loggedInUser.email,
                          'senderName': loggedInUser.displayName,
                          'createdAt': now,
                          'photoUrl': photoUrl,
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
      ),
    );
  }
}

class MessagesStream extends StatefulWidget {
  MessagesStream({this.onLongPress});

  final Function onLongPress;

  @override
  _MessagesStreamState createState() => _MessagesStreamState();
}

class _MessagesStreamState extends State<MessagesStream> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore.collection('messages').orderBy('createdAt').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
            ),
          );
        }
        final messages = snapshot.data.docs.reversed;

        List<MessageBubble> messageBubbles = [];
        for (var message in messages) {
          final messageText = message.get('text');
          final messageSender = message.get('sender');
          final currentUser = loggedInUser.email;
          final userName = message.get('senderName');
          final photo = message.get('photoUrl');
          final messageID = message.reference.id;

          final messageBubble = MessageBubble(
            documentID: messageID,
            sender: messageSender,
            text: messageText,
            isMe: currentUser == messageSender,
            senderName: userName,
            photoUrll: photo,
            onLongPress: widget.onLongPress,
            isSelected: false,
          );

          messageBubble.thisMessageBubble = messageBubble;
          messageBubbles.add(messageBubble);
        }

        return Expanded(
          child: ListView(
            reverse: true,
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
            children: messageBubbles,
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatefulWidget {
  MessageBubble({
    this.documentID,
    this.sender,
    this.text,
    this.isMe,
    this.senderName,
    this.photoUrll,
    this.onLongPress,
    this.isSelected,
    this.thisMessageBubble,
  });

  final documentID;
  final String sender;
  final String text;
  final bool isMe;
  final String senderName;
  final String photoUrll;
  final Function onLongPress;
  MessageBubble thisMessageBubble;

  bool isSelected;

  @override
  _MessageBubbleState createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  final String defaultImage = 'images/default_avatar_icon.png';
  Color textColor = Colors.orange;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: widget.onLongPress,
      onLongPressUp: () {
        setState(() {
          widget.isSelected = true;
          messageID = widget.documentID;

          messageSeleted = widget.thisMessageBubble;
        });
        print('message ' + widget.text);
      },
      child: Padding(
        padding: EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment:
              widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: <Widget>[
            widget.senderName == null
                ? Text(
                    widget.sender,
                    style: TextStyle(fontSize: 12.0, color: Colors.black54),
                  )
                : Text(
                    widget.senderName,
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Colors.black54,
                    ),
                  ),
            widget.isMe
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Message(
                          isMe: widget.isMe,
                          text: widget.text,
                          color: widget.isSelected
                              ? textColor
                              : Colors.lightBlueAccent),
                      SizedBox(
                        width: 5.0,
                      ),
                      CircleAvatar(
                        radius: 20.0,
                        backgroundImage: widget.photoUrll != null
                            ? NetworkImage(widget.photoUrll)
                            : AssetImage(defaultImage),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 20.0,
                        backgroundImage: widget.photoUrll != null
                            ? NetworkImage(widget.photoUrll)
                            : AssetImage(defaultImage),
                      ),
                      SizedBox(
                        width: 5.0,
                      ),
                      Message(
                        isMe: widget.isMe,
                        text: widget.text,
                        color: widget.isSelected ? textColor : Colors.white,
                      ),
                    ],
                  )
          ],
        ),
      ),
    );
  }
}

class Message extends StatelessWidget {
  const Message({
    @required this.isMe,
    @required this.text,
    this.isSelected,
    this.color,
  });

  final bool isMe;
  final String text;
  final bool isSelected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: isMe
          ? BorderRadius.only(
              topLeft: Radius.circular(30.0),
              bottomLeft: Radius.circular(30.0),
              bottomRight: Radius.circular(30.0))
          : BorderRadius.only(
              bottomLeft: Radius.circular(30.0),
              bottomRight: Radius.circular(30.0),
              topRight: Radius.circular(30.0),
            ),
      elevation: 5.0,
      color: color, //isMe ? Colors.lightBlueAccent : Colors.white,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
        child: Text(
          text,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black54,
            fontSize: 15.0,
          ),
        ),
      ),
    );
  }
}

Future<void> deleteMessage(var id) async {
  DocumentReference documentReference =
      FirebaseFirestore.instance.collection('messages').doc(id);
  await FirebaseFirestore.instance
      .runTransaction((Transaction myTransaction) async {
    myTransaction.delete(documentReference);
  });
}

showMessageNotification(var message) async {
  String sender;
  if (message.get('senderName') == null)
    sender = message.get('sender');
  else
    sender = message.get('senderName');

  String messageText = message.get('text');

  var android = AndroidNotificationDetails('id', 'channel ', 'description',
      priority: Priority.high, importance: Importance.max);
  var iOS = IOSNotificationDetails();
  var platform = new NotificationDetails(android: android, iOS: iOS);
  await flutterLocalNotificationsPlugin.show(0, sender, messageText, platform,
      payload: 'Welcome to the Local Notification demo');
}

bool isMe;
void getMessage() async {
  FirebaseFirestore.instance
      .collection('messages')
      .snapshots()
      .listen((result) {
    result.docChanges.forEach((message) {
      if (message.type == DocumentChangeType.added) {
        if (iSNotificationsInitialized) {
          if (message.doc.get('sender') == email)
            isMe = true;
          else
            isMe = false;
          if (!isMe) showMessageNotification(message.doc);
        }
      } else if (message.type == DocumentChangeType.modified) {
      } else if (message.type == DocumentChangeType.removed) {}
    });
  });
}
