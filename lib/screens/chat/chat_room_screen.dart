import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_pagination/firebase_pagination.dart';
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
  final String bookingId;
  final String myChatId;
  final String targetChatId;
  final String receiverName;
  final String receiverImage;
  final String receiverPhone;
  final bool isHandymanChat;
  final bool isChattingAllow;

  const ChatRoomScreen({
    Key? key,
    required this.bookingId,
    required this.myChatId,
    required this.targetChatId,
    required this.receiverName,
    required this.receiverImage,
    required this.receiverPhone,
    required this.isHandymanChat,
    this.isChattingAllow = false,
  }) : super(key: key);

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocus = FocusNode();

  late Stream<QuerySnapshot> _messagesStream;
  StreamSubscription<QuerySnapshot>? _messagesSubscription;

  bool _isSending = false;


  String get _chatRoomId => 'booking_${widget.bookingId}_${widget.targetChatId}';

  @override
  void initState() {
    super.initState();
    init();

_messageFocus.addListener(() {
  if (_messageFocus.hasFocus) {
    _scrollToBottom();
  }
});
  }

  void init() async {
    WidgetsBinding.instance.addObserver(this);

    log("========== CHAT ROOM OPEN ==========");
    log("BOOKING ID => ${widget.bookingId}");
    log("MY CHAT ID => ${widget.myChatId}");
    log("TARGET CHAT ID => ${widget.targetChatId}");
    log("IS HANDYMAN CHAT => ${widget.isHandymanChat}");
    log("ROOM ID => $_chatRoomId");
    log("====================================");

    await _markMessagesAsRead();
    _listenForNewMessages();
  }

  Future<void> _markMessagesAsRead() async {
    try {
      await chatServices.markMessagesAsRead(
        roomId: _chatRoomId,
        myChatId: widget.myChatId,
      );
    } catch (e) {
      log("Error marking messages as read: $e");
    }
  }

  void _listenForNewMessages() {
    _messagesStream = chatServices.chatMessagesWithPagination(roomId: _chatRoomId).snapshots();
    _messagesSubscription = _messagesStream.listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          if (data['receiverId'] == widget.myChatId && data['isRead'] == false) {
            _markMessagesAsRead();
          }
          // Scroll to bottom on new message
          _scrollToBottom();
          break;
        }
      }
    });
  }

  Widget _buildChatFieldWidget() {
    return Container(
 padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
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
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: appStore.isDarkMode ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocus,
                style: primaryTextStyle(),
                minLines: 1,
                maxLines: 5,
                cursorColor: appStore.isDarkMode ? Colors.white : Colors.black,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.send,
                onSubmitted: (s) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Type message...',
                  hintStyle: secondaryTextStyle(),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          8.width,
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor,
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () => _sendMessage(),
              padding: EdgeInsets.all(10),
              constraints: BoxConstraints(),
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

    // Block phone numbers
    final cleanedText = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanedText.length >= 10) {
      toast('Phone numbers are not allowed');
      return;
    }

    // Block email addresses
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (emailRegex.hasMatch(text)) {
      toast('Email sharing is not allowed');
      return;
    }

    // Block social media mentions
    const socialWords = [
      'instagram', 'insta', 'facebook', 'telegram', 'whatsapp',
      'snapchat', 'twitter', 'gmail', 'youtube', 'linkedin'
    ];
    final lowerText = text.toLowerCase();
    if (socialWords.any((word) => lowerText.contains(word))) {
      toast('Sharing social media is not allowed');
      return;
    }

    // Block inappropriate words
    const blockedWords = [
      'sex', 'nude', 'naked', 'porn', 'xxx', 'boobs', 'breast', 'adult',
      'fuck', 'bitch', 'motherfucker', 'asshole', 'dick', 'pussy', 'bastard', 'shit', 'fucker'
    ];
    if (blockedWords.any((word) => lowerText.contains(word))) {
      toast('Inappropriate message blocked');
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      appStore.setLoading(true);

      final Map<String, dynamic> data = {
        'senderId': widget.myChatId,
        'receiverId': widget.targetChatId,
        'message': text,
        'text': text,
        'bookingId': widget.bookingId,
        'participants': [widget.myChatId, widget.targetChatId],
        'chatType': widget.isHandymanChat ? 'handyman' : 'provider',
        'providerName': widget.receiverName,
        'providerImage': widget.receiverImage,
        'attachmentfiles': [],
      };

      await chatServices.addMessage(roomId: _chatRoomId, data: data);
      _messageController.clear();

    } catch (e) {
      log("Send message error: $e");
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
          0, // Because reverse is true, 0 is the bottom
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

  Future<void> _clearAllMessages() async {
    try {
      await chatServices.clearAllMessages(roomId: _chatRoomId);
      toast(languages.chatCleared);
    } catch (e) {
      toast(e.toString());
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top:false,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        
        appBar: AppBar(
          backgroundColor: Colors.transparent, // Make app bar transparent
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarBrightness: Brightness.dark,
            statusBarIconBrightness: Brightness.light,
          ),
          leading: IconButton(
            padding: EdgeInsets.symmetric(horizontal: 8),
            onPressed: () => finish(context),
            icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          title: Row(
            children: [
              CachedImageWidget(
                url: widget.receiverImage,
                height: 36,
                circle: true,
                fit: BoxFit.cover,
              ),
              12.width,
              Expanded(
                child: Text(
                  widget.receiverName,
                  style: boldTextStyle(color: white, size: APP_BAR_TEXT_SIZE),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
                      await _clearAllMessages();
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
        body: GestureDetector(
          onTap: () {
            // Dismiss keyboard when tapping outside
            _messageFocus.unfocus();
          },
          child: Column(
            children: [
              // Add a spacer to account for transparent app bar
              SizedBox(height: kToolbarHeight + MediaQuery.of(context).padding.top),
              // Chat messages - Expanded to take available space
              Expanded(
                child: Container(
                  child: FirestorePagination(
                    reverse: true,
                    isLive: true,
                    padding: EdgeInsets.only(
                      left: 8, 
                      top: 8, 
                      right: 8, 
                      bottom: 8,
                    ),
                    physics: const BouncingScrollPhysics(),
                    query: chatServices.chatMessagesWithPagination(roomId: _chatRoomId),
                    initialLoader: LoaderWidget(),
                    limit: PER_PAGE_CHAT_LIST_COUNT,
                    onEmpty: NoDataWidget(
                      title: languages.noConversation,
                      imageWidget: const EmptyStateWidget(),
                    ),
                    shrinkWrap: true,
                    viewType: ViewType.list,
                    controller: _scrollController,
                    itemBuilder: (context, snap, index) {
                      final rawData = snap[index].data() as Map<String, dynamic>;
                      ChatMessageModel data = ChatMessageModel.fromJson(rawData);
                      data.message = rawData['message'] ?? rawData['text'] ?? '';
                      data.isMe = data.senderId == widget.myChatId;
                      data.chatDocumentReference = snap[index].reference;
                      return ChatItemWidget(chatItemData: data);
                    },
                  ),
                ),
              ),
              // Chat input field - Only show if chatting is allowed
              if (!widget.isChattingAllow)
                _buildChatFieldWidget(),
            ],
          ),
        ),
      ),
    );
  }
}