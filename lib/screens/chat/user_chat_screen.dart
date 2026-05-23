import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_pagination/firebase_pagination.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:handyman_provider_flutter/components/app_widgets.dart';
import 'package:handyman_provider_flutter/components/empty_error_state_widget.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/chat_message_model.dart';
import 'package:handyman_provider_flutter/networks/firebase_services/chat_messages_service.dart';
import 'package:handyman_provider_flutter/screens/chat/components/chat_item_widget.dart';
import 'package:handyman_provider_flutter/utils/common.dart';
import 'package:handyman_provider_flutter/utils/configs.dart';
import 'package:handyman_provider_flutter/utils/constant.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../components/cached_image_widget.dart';

class UserChatScreen extends StatefulWidget {

  final String bookingId;

  final String myChatId;

  final String targetChatId;

  final String receiverName;

  final String receiverImage;

  final String receiverPhone;

  final bool isHandymanChat;

  final bool isChattingAllow;

  UserChatScreen({

    required this.bookingId,

    required this.myChatId,

    required this.targetChatId,

    required this.receiverName,

    required this.receiverImage,

    required this.receiverPhone,

    required this.isHandymanChat,

    this.isChattingAllow = false,
  });

  @override
  _UserChatScreenState createState() =>
      _UserChatScreenState();
}

class _UserChatScreenState
    extends State<UserChatScreen>
    with WidgetsBindingObserver {

  TextEditingController messageCont =
      TextEditingController();

  FocusNode messageFocus =
      FocusNode();

  String get roomId {

    return
        'booking_${widget.bookingId}_${widget.targetChatId}';
  }

  @override
  void initState() {

    super.initState();

    init();
  }

  void init() async {

    WidgetsBinding.instance.addObserver(this);

    log("========== CHAT DEBUG ==========");

    log("Booking ID => ${widget.bookingId}");

    log("Target UID => ${widget.targetChatId}");

    log("My UID => ${widget.myChatId}");

    log(
      "Is Handyman Chat => ${widget.isHandymanChat}",
    );

    log(
      "Chat Room ID => $roomId",
    );

    log("================================");
  }

  // =========================================================
  // CHAT FIELD
  // =========================================================

  Widget _buildChatFieldWidget() {

    return Row(

      children: [

        AppTextField(

          textFieldType:
              TextFieldType.OTHER,

          controller:
              messageCont,

          textStyle:
              primaryTextStyle(),

          minLines: 1,

          focus:
              messageFocus,

          cursorHeight: 20,

          maxLines: 5,

          cursorColor:
              appStore.isDarkMode
                  ? Colors.white
                  : Colors.black,

          textCapitalization:
              TextCapitalization
                  .sentences,

          keyboardType:
              TextInputType.multiline,

          onFieldSubmitted: (s) {

            sendMessages();
          },

          decoration:
              inputDecoration(context)
                  .copyWith(

            hintText:
                'Type message...',

            hintStyle:
                secondaryTextStyle(),
          ),
        ).expand(),

        8.width,

        Container(

          decoration:
              boxDecorationDefault(

            borderRadius:
                radius(80),

            color:
                primaryColor,
          ),

          child: IconButton(

            icon: Icon(
              Icons.send,
              color: Colors.white,
            ),

            onPressed: () {

              sendMessages();
            },
          ),
        ),
      ],
    );
  }

  // =========================================================
  // SEND MESSAGE
  // =========================================================

  Future<void> sendMessages() async {

    if (appStore.isLoading) return;

    String text =
        messageCont.text.trim();

    if (text.isEmpty) {

      messageFocus.requestFocus();

      return;
    }

    // =====================================================
    // BLOCK PHONE NUMBERS
    // =====================================================

    final String cleanedText =
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
    // BLOCK BAD WORDS
    // =====================================================

    List<String> blockedWords = [

      // nudity
      'sex',
      'nude',
      'naked',
      'porn',
      'boobs',
      'breast',
      'xxx',
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
    ];

    String lowerText =
        text.toLowerCase();

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

    final Map<String, dynamic> data = {

      'senderId':
          widget.myChatId,

      'receiverId':
          widget.targetChatId,

      'message':
          text,

      'text':
          text,

      'bookingId':
          widget.bookingId,

      'participants': [

        widget.myChatId,

        widget.targetChatId,
      ],

      'chatType':

          widget.isHandymanChat

              ? 'handyman'

              : 'provider',

      'providerName':
          widget.receiverName,

      'providerImage':
          widget.receiverImage,

      // NO FILES
      'attachmentfiles': [],
    };

    log(
      "========== SEND MESSAGE ==========",
    );

    log(
      "Room ID => $roomId",
    );

    log(
      "Sender ID => ${widget.myChatId}",
    );

    log(
      "Target Chat ID => ${widget.targetChatId}",
    );

    log(
      "Booking ID => ${widget.bookingId}",
    );

    log(
      "Is Handyman Chat => ${widget.isHandymanChat}",
    );

    log(
      "Message => $text",
    );

    log(
      "==================================",
    );

    await chatServices.addMessage(

      roomId: roomId,

      data: data,
    );

    messageCont.clear();
  }

  // =========================================================
  // LIFECYCLE
  // =========================================================

  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state) {

    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {

    WidgetsBinding.instance
        .removeObserver(this);

    setStatusBarColor(

      transparentColor,

      statusBarBrightness:
          Brightness.dark,

      statusBarIconBrightness:
          Brightness.dark,
    );

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        backgroundColor:
            context.primaryColor,

        leadingWidth:
            context.width(),

        systemOverlayStyle:
            SystemUiOverlayStyle(

          statusBarColor:
              context.primaryColor,

          statusBarBrightness:
              Brightness.dark,

          statusBarIconBrightness:
              Brightness.light,
        ),

        leading: Row(

          mainAxisAlignment:
              MainAxisAlignment.start,

          children: [

            IconButton(

              padding:
                  EdgeInsets.symmetric(
                horizontal: 8,
              ),

              onPressed: () {

                finish(context);
              },

              icon: Icon(

                Icons.arrow_back_ios,

                color: Colors.white,
              ),
            ),

            CachedImageWidget(

              url:
                  widget.receiverImage,

              height: 36,

              circle: true,

              fit: BoxFit.cover,
            ),

            12.width,

            Column(

              mainAxisAlignment:
                  MainAxisAlignment.center,

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(

                  widget.receiverName,

                  style: boldTextStyle(

                    color: white,

                    size:
                        APP_BAR_TEXT_SIZE,
                  ),

                  maxLines: 1,

                  overflow:
                      TextOverflow
                          .ellipsis,
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

                  positiveText:
                      languages.lblYes,

                  negativeText:
                      languages.lblNo,

                  primaryColor:
                      context.primaryColor,

                  title:
                      languages.clearChatMessage,

                  onAccept: (c) async {

                    appStore.setLoading(true);

                    await chatServices
                        .clearAllMessages(

                      roomId: roomId,
                    )

                        .then((value) {

                      toast(
                        languages.chatCleared,
                      );

                      hideKeyboard(context);

                    }).catchError((e) {

                      toast(e);
                    });

                    appStore.setLoading(false);
                  },
                );
              }
            },

            icon: Icon(

              Icons.more_vert_sharp,

              color: Colors.white,
            ),

            color:
                context.cardColor,

            itemBuilder: (context) {

              List<PopupMenuItem>
                  list = [];

              list.add(

                PopupMenuItem(

                  value: 0,

                  child: Text(

                    languages.clearChat,

                    style:
                        primaryTextStyle(),
                  ),
                ),
              );

              return list;
            },
          ),
        ],
      ),

      body: SafeArea(
        child: SizedBox(

          height: context.height(),

          width: context.width(),

          child: Stack(

            fit: StackFit.expand,

            children: [

              Container(

                margin: EdgeInsets.only(

                  bottom:
                      widget.isChattingAllow
                          ? 0
                          : 80,
                ),

                child:
                    FirestorePagination(

                  reverse: true,

                  isLive: true,

                  padding:
                      EdgeInsets.only(

                    left: 8,

                    top: 8,

                    right: 8,

                    bottom: 0,
                  ),

                  physics:
                      BouncingScrollPhysics(),

                  query:
                      chatServices
                          .chatMessagesWithPagination(

                    roomId: roomId,
                  ),

                  initialLoader:
                      LoaderWidget(),

                  limit:
                      PER_PAGE_CHAT_LIST_COUNT,

                  onEmpty: NoDataWidget(

                    title:
                        languages.noConversation,

                    imageWidget:
                        EmptyStateWidget(),
                  ),

                  shrinkWrap: true,

                  viewType:
                      ViewType.list,

                  itemBuilder:
                      (context, snap, index) {

                    final rawData =

                        snap[index].data()
                            as Map<String,
                                dynamic>;

                    ChatMessageModel data =

                        ChatMessageModel
                            .fromJson(rawData);

                    data.message =

                        rawData['message'] ??

                        rawData['text'] ??

                        '';

                    data.isMe =

                        data.senderId ==
                            widget.myChatId;

                    data.chatDocumentReference =
                        snap[index].reference;

                    return ChatItemWidget(
                      chatItemData: data,
                    );
                  },
                ),
              ),

              if (!widget.isChattingAllow)

                Positioned(

                  bottom: 16,

                  left: 16,

                  right: 16,

                  child:
                      _buildChatFieldWidget(),
                ),

              Observer(

                builder: (context) {

                  return LoaderWidget()
                      .visible(
                    appStore.isLoading,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}