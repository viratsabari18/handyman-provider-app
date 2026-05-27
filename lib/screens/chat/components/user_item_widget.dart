import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:handyman_provider_flutter/components/cached_image_widget.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/screens/chat/components/last_messege_chat.dart';
import 'package:handyman_provider_flutter/screens/chat/user_chat_screen.dart';
import 'package:handyman_provider_flutter/utils/configs.dart';
import 'package:nb_utils/nb_utils.dart';

class UserItemWidget extends StatefulWidget {
  final Map<String, dynamic> chatData;
  const UserItemWidget({Key? key, required this.chatData}) : super(key: key);

  @override
  State<UserItemWidget> createState() => _UserItemWidgetState();
}

class _UserItemWidgetState extends State<UserItemWidget> {
  @override
  Widget build(BuildContext context) {
    final String roomId = widget.chatData['chatRoomId'] ?? '';
    final String bookingId = widget.chatData['bookingId']?.toString() ?? '';
    final String targetUid = widget.chatData['targetUid'] ?? '';
final bool isProviderOrHandyman =
    appStore.userType == 'provider' ||
    appStore.userType == 'handyman';

final String name = isProviderOrHandyman
    ? (widget.chatData['name'] ?? 'Customer')
    : (widget.chatData['providerName'] ??
        widget.chatData['name'] ??
        'Professional');
final String image = isProviderOrHandyman
    ? (widget.chatData['image'] ?? '')
    : (widget.chatData['providerImage'] ??
        widget.chatData['image'] ??
        '');

    return InkWell(
      onTap: () {
        UserChatScreen(
          bookingId: bookingId,
          myChatId: getStringAsync('my_chat_id'),
          targetChatId: targetUid,
          receiverName: name,
          receiverImage: image,
          receiverPhone: '',
          isHandymanChat: targetUid.startsWith('handyman_'),
        ).launch(
          context,
          pageRouteAnimation: PageRouteAnimation.Fade,
          duration: 300.milliseconds,
        );
      },
      child: Container(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            if (image.isEmpty)
              Container(
                height: 40,
                width: 40,
                padding: EdgeInsets.all(10),
                color: context.primaryColor.withValues(alpha: 0.2),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'C',
                  style: boldTextStyle(color: context.primaryColor),
                ).center().fit(),
              ).cornerRadiusWithClipRRect(50)
            else
              CachedImageWidget(
                url: image,
                height: 40,
                circle: true,
                fit: BoxFit.cover,
              ),
            16.width,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: boldTextStyle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ).expand(),
                    // FIX: Unread badge now updates automatically via stream
                    StreamBuilder<int>(
                      stream: chatServices.getUnReadCount(
                        roomId: roomId,
                        myChatId: getStringAsync('my_chat_id'),
                      ),
                      builder: (context, snap) {
                        if (snap.hasData && snap.data != 0) {
                          return Container(
                            height: 18,
                            width: 18,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: primaryColor,
                            ),
                            child: Text(
                              snap.data.validate().toString(),
                              style: secondaryTextStyle(color: white),
                              textAlign: TextAlign.center,
                            ).center(),
                          );
                        }
                        return Offstage();
                      },
                    ),
                  ],
                ),
                4.height,
                // FIX: Last message is now a live stream from the chat document
                StreamBuilder<DocumentSnapshot>(
                  stream: chatServices.getLastMessageStream(roomId: roomId),
                  builder: (context, snapshot) {
                    String lastMsg = '';
                    if (snapshot.hasData && snapshot.data!.exists) {
                      lastMsg = snapshot.data!.get('lastMessage') ?? '';
                    }
                    return Text(
                      lastMsg,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: secondaryTextStyle(size: 14),
                    );
                  },
                ),
                4.height,
              ],
            ).expand(),
          ],
        ),
      ),
    );
  }
}