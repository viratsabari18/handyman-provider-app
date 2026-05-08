import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_pagination/firebase_pagination.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:handyman_provider_flutter/components/app_widgets.dart';
import 'package:handyman_provider_flutter/components/empty_error_state_widget.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/chat_message_model.dart';
import 'package:handyman_provider_flutter/models/user_data.dart';
import 'package:handyman_provider_flutter/networks/firebase_services/notification_service.dart';
import 'package:handyman_provider_flutter/screens/chat/components/chat_item_widget.dart';
import 'package:handyman_provider_flutter/utils/common.dart';
import 'package:handyman_provider_flutter/utils/configs.dart';
import 'package:handyman_provider_flutter/utils/constant.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../components/cached_image_widget.dart';
import '../../networks/firebase_services/chat_messages_service.dart';
import '../../utils/getImage.dart';
import 'package:handyman_provider_flutter/networks/rest_apis.dart';
import 'components/send_file_screen.dart';

class UserChatScreen extends StatefulWidget {
  final UserData receiverUser;
  final bool isChattingAllow;
  final String? bookingId;

  UserChatScreen({required this.receiverUser, this.isChattingAllow = false, this.bookingId});

  @override
  _UserChatScreenState createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> with WidgetsBindingObserver {
  TextEditingController messageCont = TextEditingController();

  FocusNode messageFocus = FocusNode();

  UserData senderUser = UserData();

  StreamSubscription? _streamSubscription;

  int isReceiverOnline = 0;

  bool get isReceiverUserOnline => isReceiverOnline == 1;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    log("UserChatScreen init started. BookingId: ${widget.bookingId}");
    WidgetsBinding.instance.addObserver(this);

    if (widget.receiverUser.uid.validate().isEmpty) {
      log("Receiver UID is empty, fetching by email: ${widget.receiverUser.email}");
      await userService.getUser(email: widget.receiverUser.email.validate()).then((value) {
        widget.receiverUser.uid = value.uid;
        log("Fetched Receiver UID: ${widget.receiverUser.uid}");
      }).catchError((e) {
        log("Error fetching receiver UID: ${e.toString()}");
      });
    }

    log("Fetching sender user info for: ${appStore.userEmail}");
    senderUser = await userService.getUser(email: appStore.userEmail.validate());
    log("Sender user info fetched.");

    setState(() {});

    log("Setting unread status to true.");
    await chatServices.setUnReadStatusToTrue(senderId: appStore.uid.validate(), receiverId: widget.receiverUser.uid.validate(), bookingId: widget.bookingId).then((value) {
      log("Unread status set to true.");
    }).catchError((e) {
      log("Error setting unread status: ${e.toString()}");
      toast(e.toString());
    });

    log("receiver ID ${widget.receiverUser.uid}");

    // Fetch details from API if Firestore data is incomplete
    if (widget.bookingId.validate().isNotEmpty && (widget.receiverUser.firstName.validate().isEmpty || widget.receiverUser.lastName.validate().isEmpty)) {
      int bId = widget.bookingId.validate().split('_').last.toInt();
      try {
        var res = await bookingDetail({'booking_id': bId});
        if (res.customer != null) {
          widget.receiverUser.firstName = res.customer!.firstName;
          widget.receiverUser.lastName = res.customer!.lastName;
          widget.receiverUser.profileImage = res.customer!.profileImage;
          widget.receiverUser.displayName = res.customer!.displayName;
          setState(() {});
        }
      } catch (e) {
        log("Error fetching booking details for customer info: $e");
      }
    }

    chatServices.setOnlineCount(senderId: widget.receiverUser.uid.validate(), receiverId: appStore.uid.validate(), status: 1);
    //
    _streamSubscription = chatServices.isReceiverOnline(senderId: appStore.uid.validate(), receiverUserId: widget.receiverUser.uid.validate()).listen((event) {
      isReceiverOnline = event.isOnline.validate();
      log("=======*=======*=======*=======*=======* Provider $isReceiverOnline =======*=======*=======*=======*=======");
    });
    log("UserChatScreen init completed.");
  }

  //region Widget
  Widget _buildChatFieldWidget() {
    return Row(
      children: [
        AppTextField(
          textFieldType: TextFieldType.OTHER,
          controller: messageCont,
          textStyle: primaryTextStyle(),
          minLines: 1,
          onFieldSubmitted: (s) {
            sendMessages();
          },
          focus: messageFocus,
          cursorHeight: 20,
          maxLines: 5,
          cursorColor: appStore.isDarkMode ? Colors.white : Colors.black,
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.multiline,
          suffix: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Transform.rotate(angle: -0.75, child: Icon(Icons.attach_file_outlined)),
                onPressed: () {
                  if (!appStore.isLoading) {
                    _handleDocumentClick();
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.camera_alt_outlined),
                onPressed: () {
                  if (!appStore.isLoading) {
                    _handleCameraClick();
                  }
                },
              ),
            ],
          ),
          decoration: inputDecoration(context).copyWith(hintText: languages.lblMessage, hintStyle: secondaryTextStyle()),
        ).expand(),
        8.width,
        Container(
          decoration: boxDecorationDefault(borderRadius: radius(80), color: primaryColor),
          child: IconButton(
            icon: Icon(Icons.send, color: Colors.white),
            onPressed: () {
              sendMessages();
            },
          ),
        )
      ],
    );
  }

  //endregion

  //region Methods
  Future<void> sendMessages({
    bool isFile = false,
    List<String> attachmentfiles = const [],
  }) async {
    if (appStore.isLoading) return;

    // If Message TextField is Empty.
    if (messageCont.text.trim().isEmpty && !isFile) {
      messageFocus.requestFocus();
      return;
    } else if (isFile && attachmentfiles.isEmpty) {
      return;
    }

    // Making Request for sending data to firebase
    ChatMessageModel data = ChatMessageModel();

    data.receiverId = widget.receiverUser.id.validate() != 0 ? widget.receiverUser.id.toString() : widget.receiverUser.uid.validate();
    data.senderId = appStore.userId.toString();            // provider's numeric ID ("162")
    data.senderUid = appStore.uid;                        // provider's Firebase UID (for isMe fallback)
    data.receiverUid = widget.receiverUser.uid.validate(); // user's Firebase UID
    data.senderName = appStore.userFullName;
    data.message = messageCont.text;
    data.text = messageCont.text;
    data.isMessageRead = isReceiverOnline == 1;
    data.createdAt = DateTime.now().millisecondsSinceEpoch;
    data.createdAtTime = Timestamp.now();
    data.updatedAtTime = Timestamp.now();
    data.messageType = isFile ? MessageType.Files.name : MessageType.TEXT.name;
    data.attachmentfiles = attachmentfiles;
    // log('ChatMessageModel Data : ${data.toJson()}');

    messageCont.clear();

    await chatServices.addMessage(data, bookingId: widget.bookingId).then((value) async {
      log("--Message Successfully Added--");

      if (isReceiverOnline != 1) {
        /// Send Notification
        NotificationService().sendPushNotifications(
          appStore.userFullName,
          data.message.validate(),
          image: data.attachmentfiles == null || data.attachmentfiles!.isEmpty ? null : data.attachmentfiles!.first,
          receiverUser: widget.receiverUser,
          senderUserData: senderUser,
        ).catchError((e) {
          log("Notification Error ${e.toString()}");
        });
      }

      /// ENd
    }).catchError((e) {
      log(e.toString());
    });
  }

  //endregion

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.detached) {
      chatServices.setOnlineCount(senderId: widget.receiverUser.uid.validate(), receiverId: appStore.uid.validate(), status: 0);
    }

    if (state == AppLifecycleState.paused) {
      chatServices.setOnlineCount(senderId: widget.receiverUser.uid.validate(), receiverId: appStore.uid.validate(), status: 0);
    }
    if (state == AppLifecycleState.resumed) {
      chatServices.setOnlineCount(senderId: widget.receiverUser.uid.validate(), receiverId: appStore.uid.validate(), status: 1);
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    chatServices.setOnlineCount(senderId: widget.receiverUser.uid.validate(), receiverId: appStore.uid.validate(), status: 0);

    _streamSubscription?.cancel();

    setStatusBarColor(transparentColor, statusBarBrightness: Brightness.dark, statusBarIconBrightness: Brightness.dark);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.primaryColor,
        leadingWidth: context.width(),
        systemOverlayStyle: SystemUiOverlayStyle(statusBarColor: context.primaryColor, statusBarBrightness: Brightness.dark, statusBarIconBrightness: Brightness.light),
        leading: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              padding: EdgeInsets.symmetric(horizontal: 8),
              onPressed: () {
                finish(context);
              },
              icon: Icon(Icons.arrow_back_ios, color: Colors.white),
            ),
            CachedImageWidget(url: widget.receiverUser.profileImage.validate(), height: 36, circle: true, fit: BoxFit.cover),
            12.width,
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (widget.receiverUser.firstName.validate().isNotEmpty || widget.receiverUser.lastName.validate().isNotEmpty)
                      ? '${widget.receiverUser.firstName.validate()} ${widget.receiverUser.lastName.validate()}'.trim()
                      : 'Customer',
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
                    await chatServices.clearAllMessages(receiverId: widget.receiverUser.uid.validate(), bookingId: widget.bookingId).then((value) {
                      toast(languages.chatCleared);
                      hideKeyboard(context);
                    }).catchError((e) {
                      toast(e);
                    });
                    appStore.setLoading(false);
                  },
                );
              }
            },
            icon: Icon(Icons.more_vert_sharp, color: Colors.white),
            color: context.cardColor,
            itemBuilder: (context) {
              List<PopupMenuItem> list = [];
              list.add(
                PopupMenuItem(
                  value: 0,
                  child: Text(languages.clearChat, style: primaryTextStyle()),
                ),
              );
              return list;
            },
          )
        ],
      ),
      body: SizedBox(
        height: context.height(),
        width: context.width(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              margin: EdgeInsets.only(bottom: widget.isChattingAllow ? 0 : 80),
              child: FirestorePagination(
                reverse: true,
                isLive: true,
                padding: EdgeInsets.only(left: 8, top: 8, right: 8, bottom: 0),
                physics: BouncingScrollPhysics(),
                query: chatServices.chatMessagesWithPagination(bookingId: widget.bookingId),
                initialLoader: LoaderWidget(),
                limit: PER_PAGE_CHAT_LIST_COUNT,
                onEmpty: NoDataWidget(
                  title: languages.noConversation,
                  imageWidget: EmptyStateWidget(),
                ),
                shrinkWrap: true,
                viewType: ViewType.list,
                itemBuilder: (context, snap, index) {
                  ChatMessageModel data = ChatMessageModel.fromJson(snap[index].data() as Map<String, dynamic>);
                  // isMe: provider's messages have senderId = appStore.userId (numeric "162")
                  //        or senderUid = appStore.uid (Firebase UID).
                  // Zeerah user messages have senderId = user's Firebase UID.
                  data.isMe = data.senderId == appStore.userId.toString() ||
                               data.senderUid == appStore.uid;
                  data.chatDocumentReference = snap[index].reference;

                  return ChatItemWidget(chatItemData: data, bookingId: widget.bookingId);
                },
              ),
            ),
            if (!widget.isChattingAllow)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: _buildChatFieldWidget(),
              ),
            Observer(builder: (context) => LoaderWidget().visible(appStore.isLoading)),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDocumentClick() async {
    appStore.setLoading(true);
    await pickFiles(
      allowedExtensions: chatFilesAllowedExtensions,
      maxFileSizeMB: max_acceptable_file_size,
      type: FileType.custom,
    ).then((pickedfiles) async {
      await handleUploadAndSendFiles(pickedfiles);
    }).catchError((e) {
      toast(e);
      log('ChatServices().uploadFiles Err: ${e}');
      return;
    }).whenComplete(() => appStore.setLoading(false));
  }

  Future<void> _handleCameraClick() async {
    GetImage(ImageSource.camera, path: (path, name, xFile) async {
      log('Path camera : ${path.toString()} name $name');
      await handleUploadAndSendFiles([File(xFile.path)]);
      setState(() {});
    });
  }

  Future<void> handleUploadAndSendFiles(List<File> pickedfiles) async {
    if (pickedfiles.isEmpty) return;
    await SendFilePreviewScreen(pickedfiles: pickedfiles).launch(context).then((value) async {
      if (value[MessageType.Files.name] is List<File>) {
        pickedfiles = value[MessageType.Files.name];
      }

      if (value[MessageType.TEXT.name] is String) {
        messageCont.text = value[MessageType.TEXT.name];
      }

      if (messageCont.text.trim().isNotEmpty || pickedfiles.isNotEmpty) {
        appStore.setLoading(true);
        await ChatServices().uploadFiles(pickedfiles).then((attachedfiles) async {
          if (attachedfiles.isEmpty) return;
          log('ATTACHEDFILES: ${attachedfiles}');
          await sendMessages(isFile: true, attachmentfiles: attachedfiles).whenComplete(() => appStore.setLoading(false));
        }).catchError((e) {
          toast(e);
          log('ChatServices().uploadFiles Err: ${e}');
          return;
        }).whenComplete(() => appStore.setLoading(false));
      }
    });
  }
}
