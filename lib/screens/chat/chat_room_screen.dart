import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:handyman_provider_flutter/components/app_widgets.dart';
import 'package:handyman_provider_flutter/components/empty_error_state_widget.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/chat_message_model.dart';
import 'package:handyman_provider_flutter/screens/chat/components/chat_item_widget.dart';
import 'package:handyman_provider_flutter/utils/common.dart';
import 'package:handyman_provider_flutter/utils/configs.dart';
import 'package:handyman_provider_flutter/utils/constant.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../components/cached_image_widget.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({Key? key}) : super(key: key);

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> with WidgetsBindingObserver {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocus = FocusNode();

  late Stream<QuerySnapshot> _messagesStream;
  StreamSubscription<QuerySnapshot>? _messagesSubscription;

  String _bookingId = '';
  String _providerName = '';
  String _providerImage = '';
  String _providerPhone = '';
  String _targetChatId = '';
  String _myUid = '';
  bool _isHandymanChat = false;
  bool _initialized = false;
  bool _isSending = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _bookingId = args['booking_id']?.toString() ?? '';
      _providerName = args['name']?.toString() ?? 'User';
      _providerImage = args['image']?.toString() ?? '';
      _providerPhone = args['phone']?.toString() ?? '';
      _targetChatId = args['target_chat_id']?.toString() ?? '';
      _myUid = args['my_chat_id']?.toString() ?? '';
      _isHandymanChat = args['is_handyman_chat'] == true;
    }

    _initialized = true;

    log("========== CHAT ROOM OPEN ==========");
    log("BOOKING ID => $_bookingId");
    log("MY CHAT ID => $_myUid");
    log("TARGET CHAT ID => $_targetChatId");
    log("IS HANDYMAN CHAT => $_isHandymanChat");
    log("ROOM ID => $_chatRoomId");
    log("====================================");

    _markMessagesAsRead();
    _listenForNewMessages();
  }

  String get _chatRoomId => 'booking_${_bookingId}_$_targetChatId';

  CollectionReference<Map<String, dynamic>> get _messagesRef =>
      _firestore.collection('chats').doc(_chatRoomId).collection('messages');

  Future<void> _markMessagesAsRead() async {
    try {
      final unreadMessages = await _messagesRef
          .where('receiverId', isEqualTo: _myUid)
          .where('isRead', isEqualTo: false)
          .get();

      if (unreadMessages.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      log("✅ Marked ${unreadMessages.docs.length} messages as read");
    } catch (e) {
      log("❌ Error marking messages as read: $e");
    }
  }

  void _listenForNewMessages() {
    _messagesStream = _messagesRef
        .where('receiverId', isEqualTo: _myUid)
        .where('isRead', isEqualTo: false)
        .snapshots();

    _messagesSubscription = _messagesStream.listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        _markMessagesAsRead();
      }
    });
  }

  Widget _buildChatFieldWidget() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 8,
      ),
      decoration: BoxDecoration(
        color: context.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          AppTextField(
            textFieldType: TextFieldType.OTHER,
            controller: _messageController,
            textStyle: primaryTextStyle(),
            minLines: 1,
            focus: _messageFocus,
            cursorHeight: 20,
            maxLines: 5,
            cursorColor: appStore.isDarkMode ? Colors.white : Colors.black,
            textCapitalization: TextCapitalization.sentences,
            keyboardType: TextInputType.multiline,
            onFieldSubmitted: (s) => _sendMessage(),
            decoration: inputDecoration(context).copyWith(
              hintText: 'Type message...',
              hintStyle: secondaryTextStyle(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              filled: true,

              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ).expand(),
          8.width,
          Container(
            decoration: boxDecorationDefault(
              borderRadius: radius(80),
              color: primaryColor,
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: () => _sendMessage(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (appStore.isLoading || _isSending) return;
    
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      _messageFocus.requestFocus();
      return;
    }

    final cleanedText = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanedText.length >= 10) {
      toast('Phone numbers are not allowed');
      return;
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (emailRegex.hasMatch(text)) {
      toast('Email sharing is not allowed');
      return;
    }

    const socialWords = [
      'instagram', 'insta', 'facebook', 'telegram', 'whatsapp',
      'snapchat', 'twitter', 'gmail', 'youtube', 'linkedin'
    ];
    final lowerText = text.toLowerCase();
    if (socialWords.any((word) => lowerText.contains(word))) {
      toast('Sharing social media is not allowed');
      return;
    }

    const blockedWords = [
      'sex', 'nude', 'naked', 'porn', 'xxx', 'boobs', 'breast', 'adult',
      'fuck', 'bitch', 'motherfucker', 'asshole', 'dick', 'pussy', 'bastard', 'shit', 'fucker'
    ];
    if (blockedWords.any((word) => lowerText.contains(word))) {
      toast('Inappropriate message blocked');
      return;
    }

    log("========== SEND MESSAGE ==========");
    log("ROOM ID => $_chatRoomId");
    log("SENDER ID => $_myUid");
    log("TARGET CHAT ID => $_targetChatId");
    log("MESSAGE => $text");
    log("==================================");

    setState(() {
      _isSending = true;
    });

    try {
      appStore.setLoading(true);

      final messageRef = _messagesRef.doc();
      final messageId = messageRef.id;
      final timestamp = DateTime.now();

      await messageRef.set({
        'messageId': messageId,
        'senderId': _myUid,
        'receiverId': _targetChatId,
        'message': text,
        'text': text,
        'bookingId': _bookingId,
        'participants': [_myUid, _targetChatId],
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': timestamp.microsecondsSinceEpoch / 1000,
        'createdAtTime': Timestamp.fromDate(timestamp),
        'isRead': false,
        'isDelivered': false,
        'chatType': _isHandymanChat ? 'handyman' : 'provider',
        'providerName': _providerName ?? '',
        'providerImage': _providerImage ?? '',
        'messageType': 'TEXT',
        'attachmentfiles': [],
      });

      await _firestore.collection('chats').doc(_chatRoomId).set({
        'bookingId': _bookingId,
        'chatRoomId': _chatRoomId,
        'chatType': _isHandymanChat ? 'handyman' : 'provider',
        'participants': [_myUid, _targetChatId],
        'lastMessage': text,
        'lastTimestamp': FieldValue.serverTimestamp(),
        'targetUid': _targetChatId,
        'name': _providerName ?? '',
        'image': _providerImage ?? '',
      }, SetOptions(merge: true));

      _messageController.clear();
      _scrollToBottom();

      log("✅ Message sent and chat room updated");
    } catch (e) {
      log("❌ Send message error: $e");
      toast('Failed to send message');
    } finally {
      appStore.setLoading(false);
      setState(() {
        _isSending = false;
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _markMessagesAsRead();
    }
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocus.dispose();
    WidgetsBinding.instance.removeObserver(this);
    setStatusBarColor(
      transparentColor,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.primaryColor,
        leadingWidth: context.width(),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: context.primaryColor,
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
        leading: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              padding: EdgeInsets.symmetric(horizontal: 8),
              onPressed: () => finish(context),
              icon: Icon(Icons.arrow_back_ios, color: Colors.white),
            ),
            CachedImageWidget(
              url: _providerImage,
              height: 36,
              circle: true,
              fit: BoxFit.cover,
            ),
            12.width,
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _providerName,
                  style: boldTextStyle(color: white, size: APP_BAR_TEXT_SIZE),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ).expand(),
            40.width,
          ],
        ),
        actions: [
          PopupMenuButton(
            onSelected: (index) {
              if (index == 0) {
                showConfirmDialogCustom(
                  context,
                  positiveText: languages.lblYes,
                  negativeText: languages.lblNo,
                  primaryColor: context.primaryColor,
                  title: languages.clearChatMessage,
                  onAccept: (c) async {
                    appStore.setLoading(true);
                    await _clearAllMessages().then((value) {
                      toast(languages.chatCleared);
                      hideKeyboard(context);
                    }).catchError((e) => toast(e));
                    appStore.setLoading(false);
                  },
                );
              }
            },
            icon: Icon(Icons.more_vert_sharp, color: Colors.white),
            color: context.cardColor,
            itemBuilder: (context) {
              return [
                PopupMenuItem(value: 0, child: Text(languages.clearChat, style: primaryTextStyle())),
              ];
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _messagesRef.orderBy('timestamp', descending: false).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return LoaderWidget();
                    }
                    if (snapshot.hasError) {
                      return NoDataWidget(
                        title: snapshot.error.toString(),
                        imageWidget: ErrorStateWidget(),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return NoDataWidget(
                        title: languages.noConversation,
                        imageWidget: EmptyStateWidget(),
                      );
                    }

                    final docs = snapshot.data!.docs;
                    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: false,
                      padding: EdgeInsets.only(left: 8, top: 8, right: 8, bottom: 80),
                      physics: BouncingScrollPhysics(),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        try {
                          final data = docs[index].data() as Map<String, dynamic>;
                          
                          if (data == null) {
                            return SizedBox.shrink();
                          }
                          
                          final chatMessage = ChatMessageModel.fromJson({
                            ...data,
                            'messageId': docs[index].id,
                          });
                          
                          final senderId = data['senderId'] as String? ?? '';
                          chatMessage.isMe = senderId == _myUid;
                          chatMessage.chatDocumentReference = docs[index].reference;
                          
                     
                          return ChatItemWidget(
                            chatItemData: chatMessage,
                          );
                        } catch (e) {
                          log("Error building message: $e");
                          return SizedBox.shrink();
                        }
                      },
                    );
                  },
                ),
              ),
              _buildChatFieldWidget(),
            ],
          ),
          Observer(
            builder: (context) => Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: LoaderWidget().visible(appStore.isLoading),
                ),
              ),
            ).visible(appStore.isLoading),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllMessages() async {
    try {
      final messagesSnapshot = await _messagesRef.get();
      final batch = _firestore.batch();

      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      await _firestore.collection('chats').doc(_chatRoomId).set({
        'lastMessage': '',
        'lastTimestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      log("=========== CHAT CLEARED ===========");
      log("ROOM ID => $_chatRoomId");
      log("DELETED => ${messagesSnapshot.docs.length}");
      log("====================================");
    } catch (e) {
      log("=========== CLEAR CHAT ERROR ===========");
      log(e.toString());
      log("========================================");
      rethrow;
    }
  }
}