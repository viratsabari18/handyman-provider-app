import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({Key? key}) : super(key: key);

  @override
  State<ChatRoomScreen> createState() =>
      _ChatRoomScreenState();
}

class _ChatRoomScreenState
    extends State<ChatRoomScreen> {

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final TextEditingController
      _messageController =
      TextEditingController();

  final ScrollController
      _scrollController =
      ScrollController();

  String _bookingId = '';

  String _providerName = '';

  String _providerImage = '';

  String _providerPhone = '';

  String _targetChatId = '';

  String _myUid = '';

  bool _isHandymanChat = false;

  bool _initialized = false;

  @override
  void didChangeDependencies() {

    super.didChangeDependencies();

    if (_initialized) return;

    final args =
        ModalRoute.of(context)
                ?.settings
                .arguments
            as Map<String, dynamic>?;

    if (args != null) {

      _bookingId =
          args['booking_id']
                  ?.toString() ??
              '';

      _providerName =
          args['name']
                  ?.toString() ??
              'User';

      _providerImage =
          args['image']
                  ?.toString() ??
              '';

      _providerPhone =
          args['phone']
                  ?.toString() ??
              '';

      _targetChatId =
          args['target_chat_id']
                  ?.toString() ??
              '';

      _myUid =
          args['my_chat_id']
                  ?.toString() ??
              '';

      _isHandymanChat =
          args['is_handyman_chat'] ==
              true;
    }

    _initialized = true;

    log(
      "=========== CHAT ROOM OPEN ===========",
    );

    log(
      "BOOKING ID => $_bookingId",
    );

    log(
      "MY CHAT ID => $_myUid",
    );

    log(
      "TARGET CHAT ID => $_targetChatId",
    );

    log(
      "IS HANDYMAN CHAT => $_isHandymanChat",
    );

    log(
      "ROOM ID => $_chatRoomId",
    );

    log(
      "======================================",
    );
  }

  String get _chatRoomId {

    return
        'booking_${_bookingId}_$_targetChatId';
  }

  CollectionReference get _messagesRef =>

      _firestore
          .collection('chats')
          .doc(_chatRoomId)
          .collection('messages');

  // =====================================================
  // SEND MESSAGE
  // =====================================================

  Future<void> _sendMessage() async {

    final text =
        _messageController.text.trim();

    if (text.isEmpty) return;

    // =====================================================
    // BLOCK PHONE NUMBERS
    // =====================================================

    final cleanedText =
        text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (cleanedText.length >= 10) {

      toast(
        'Phone numbers are not allowed',
      );

      return;
    }

    // =====================================================
    // BLOCK EMAILS
    // =====================================================

    final emailRegex = RegExp(
      r'^[^@]+@[^@]+\.[^@]+',
    );

    if (emailRegex.hasMatch(text)) {

      toast(
        'Email sharing is not allowed',
      );

      return;
    }

    // =====================================================
    // BLOCK SOCIAL MEDIA
    // =====================================================

    final socialWords = [

      'instagram',
      'insta',
      'facebook',
      'telegram',
      'whatsapp',
      'snapchat',
      'twitter',
      'gmail',
      'youtube',
      'linkedin',
    ];

    final lowerText =
        text.toLowerCase();

    bool hasSocialWord =
        socialWords.any(
      (word) =>
          lowerText.contains(word),
    );

    if (hasSocialWord) {

      toast(
        'Sharing social media is not allowed',
      );

      return;
    }

    // =====================================================
    // BLOCK BAD WORDS
    // =====================================================

    List<String> blockedWords = [

      // nudity
      'sex',
      'nude',
      'naked',
      'porn',
      'xxx',
      'boobs',
      'breast',
      'adult',

      // abuse
      'fuck',
      'bitch',
      'motherfucker',
      'asshole',
      'dick',
      'pussy',
      'bastard',
      'shit',
      'fucker',
    ];

    bool hasBadWord =
        blockedWords.any(
      (word) =>
          lowerText.contains(word),
    );

    if (hasBadWord) {

      toast(
        'Inappropriate message blocked',
      );

      return;
    }

    log(
      "=========== SEND MESSAGE ===========",
    );

    log(
      "ROOM ID => $_chatRoomId",
    );

    log(
      "SENDER ID => $_myUid",
    );

    log(
      "TARGET CHAT ID => $_targetChatId",
    );

    log(
      "BOOKING ID => $_bookingId",
    );

    log(
      "IS HANDYMAN CHAT => $_isHandymanChat",
    );

    log(
      "MESSAGE => $text",
    );

    log(
      "====================================",
    );

    try {

      await _messagesRef.add({

        'senderId': _myUid,

        'receiverId': _targetChatId,

        'message': text,

        'bookingId': _bookingId,

        'participants': [

          _myUid,

          _targetChatId,
        ],

        'timestamp': Timestamp.now(),
      });

      await _firestore
          .collection('chats')
          .doc(_chatRoomId)
          .set({

        'bookingId': _bookingId,

        'chatRoomId': _chatRoomId,

        'chatType':
            _isHandymanChat
                ? 'handyman'
                : 'provider',

        'participants': [

          _myUid,

          _targetChatId,
        ],

        'lastMessage': text,

        'lastTimestamp':
            Timestamp.now(),

        'targetUid':
            _targetChatId,

        'name':
            _providerName,

        'image':
            _providerImage,

      }, SetOptions(merge: true));

      log(
        "✅ Message sent successfully",
      );

      log(
        "✅ Chat room updated: $_chatRoomId",
      );

      _messageController.clear();

      Future.delayed(

        const Duration(
            milliseconds: 300),

        () {

          if (_scrollController
              .hasClients) {

            _scrollController.animateTo(

              _scrollController
                  .position
                  .maxScrollExtent,

              duration:
                  const Duration(
                      milliseconds: 300),

              curve: Curves.easeOut,
            );
          }
        },
      );

    } catch (e) {

      log(
        "❌ SEND MESSAGE ERROR",
      );

      log(e.toString());
    }
  }

  // =====================================================
  // MESSAGE ITEM
  // =====================================================

  Widget _buildMessageItem(
      Map<String, dynamic> data) {

    final isMe =
        data['senderId'] == _myUid;

    return Align(

      alignment:

          isMe
              ? Alignment.centerRight
              : Alignment.centerLeft,

      child: Container(

        margin:
            const EdgeInsets.symmetric(
          vertical: 4,
          horizontal: 8,
        ),

        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),

        decoration: BoxDecoration(

          color:

              isMe
                  ? Colors.blue
                  : Colors.grey.shade300,

          borderRadius:
              BorderRadius.circular(12),
        ),

        child: Text(

          data['message'] ??
              data['text'] ??
              data['msg'] ??
              '',

          style: TextStyle(

            color:

                isMe
                    ? Colors.white
                    : Colors.black,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title:
            Text(_providerName),
      ),

      body: Column(

        children: [

          Expanded(

            child:
                StreamBuilder<QuerySnapshot>(

              stream: _messagesRef

                  .orderBy(
                    'timestamp',
                    descending: false,
                  )

                  .snapshots(
                    includeMetadataChanges:
                        true,
                  ),

              builder:
                  (context, snapshot) {

                log(
                  "=========== CHAT STREAM ===========",
                );

                log(
                  "HAS DATA => ${snapshot.hasData}",
                );

                log(
                  "DOC COUNT => ${snapshot.data?.docs.length}",
                );

                log(
                  "ERROR => ${snapshot.error}",
                );

                log(
                  "===================================",
                );

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {

                  return const Center(

                    child:
                        CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {

                  return Center(

                    child: Text(
                      snapshot.error.toString(),
                    ),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot
                        .data!.docs.isEmpty) {

                  return const Center(

                    child:
                        Text('No messages'),
                  );
                }

                final docs =
                    snapshot.data!.docs;

                WidgetsBinding.instance
                    .addPostFrameCallback((_) {

                  if (_scrollController
                      .hasClients) {

                    _scrollController.jumpTo(

                      _scrollController
                          .position
                          .maxScrollExtent,
                    );
                  }
                });

                return ListView.builder(

                  controller:
                      _scrollController,

                  itemCount:
                      docs.length,

                  itemBuilder:
                      (context, index) {

                    final data =

                        docs[index].data()
                            as Map<String,
                                dynamic>;

                    log(
                      "FULL MESSAGE DATA => $data",
                    );

                    log(
                      "MESSAGE => ${data['message'] ?? data['text'] ?? data['msg']}",
                    );

                    return _buildMessageItem(
                        data);
                  },
                );
              },
            ),
          ),

          Container(

            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),

            child: Row(

              children: [

                Expanded(

                  child: TextField(

                    controller:
                        _messageController,

                    maxLines: 5,

                    minLines: 1,

                    decoration:
                        InputDecoration(

                      hintText:
                          'Type message...',

                      border:
                          OutlineInputBorder(

                        borderRadius:
                            BorderRadius.circular(
                                30),
                      ),
                    ),
                  ),
                ),

                8.width,

                CircleAvatar(

                  child: IconButton(

                    icon: const Icon(

                      Icons.send,

                      color: Colors.white,
                    ),

                    onPressed:
                        _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}