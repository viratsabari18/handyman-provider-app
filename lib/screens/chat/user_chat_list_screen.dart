import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_pagination/firebase_pagination.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:handyman_provider_flutter/components/app_widgets.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/user_data.dart';
import 'package:handyman_provider_flutter/screens/chat/components/user_item_widget.dart';
import 'package:handyman_provider_flutter/utils/constant.dart';
import 'package:nb_utils/nb_utils.dart';

import 'package:handyman_provider_flutter/models/chat_model.dart';
import '../../auth/sign_in_screen.dart';
import '../../components/base_scaffold_widget.dart';
import '../../components/empty_error_state_widget.dart';

class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    if (appStore.isLoggedIn && (FirebaseAuth.instance.currentUser == null || appStore.uid.isEmpty)) {
      authService.verifyFirebaseUser().then((value) {
        setState(() {});
      }).catchError((e) {
        log(e.toString());
      });
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  bool get isUserTypeHandyman => appStore.userType == USER_TYPE_HANDYMAN;

  bool get isUserTypeProvider => appStore.userType == USER_TYPE_PROVIDER;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Observer(builder: (context) {
        bool isLoggedIn = FirebaseAuth.instance.currentUser != null && appStore.uid.isNotEmpty;

        if (appStore.isLoggedIn && !isLoggedIn) {
          return LoaderWidget().center();
        }

        if (!isLoggedIn) {
          return NoDataWidget(
            title: languages.youAreNotConnectedWithChatServer,
            subTitle: languages.tapBelowButtonToConnectWithOurChatServer,
            onRetry: () async {
              if (!appStore.isLoggedIn) {
                SignInScreen().launch(context);
              } else {
                appStore.setLoading(true);
                await authService.verifyFirebaseUser().then((value) {
                  setState(() {});
                }).catchError((e) {
                  toast(e.toString());
                });
                appStore.setLoading(false);
              }
            },
            retryText: languages.connect,
            imageWidget: EmptyStateWidget(),
          ).paddingSymmetric(horizontal: 16);
        } else {
          return FirestorePagination(
            // Query using numeric provider ID ("162") — this is what Zeerah user app stores in participants.
            query: chatServices.fetchChatListQuery(userId: appStore.userId.toString()),
            physics: AlwaysScrollableScrollPhysics(),
            isLive: true,
            shrinkWrap: true,
            itemBuilder: (context, snap, index) {
              Map<String, dynamic> rawData = snap[index].data() as Map<String, dynamic>;
              ChatModel chat = ChatModel.fromJson(rawData);

              String customerUid = '';
              if (chat.participants != null && chat.participants!.isNotEmpty) {
                // Exclude both the provider's numeric ID and Firebase UID to get the customer's ID.
                customerUid = chat.participants!.firstWhere(
                  (element) => element != appStore.userId.toString() && element != appStore.uid,
                  orElse: () => chat.participants!.first,
                );
              }

              return UserItemWidget(userUid: customerUid, bookingId: chat.bookingId);
            },
            initialLoader: LoaderWidget(),
            padding: EdgeInsets.only(left: 0, top: 8, right: 0, bottom: 0),
            limit: PER_PAGE_CHAT_LIST_COUNT,
            separatorBuilder: (_, i) =>
                Divider(height: 0, indent: 82, color: context.dividerColor),
            viewType: ViewType.list,
            onEmpty: NoDataWidget(
              title: languages.noConversation,
              subTitle: languages.noConversationSubTitle,
              imageWidget: EmptyStateWidget(),
            ).paddingSymmetric(horizontal: 16),
          );
        }
      }),
    );
  }
}
