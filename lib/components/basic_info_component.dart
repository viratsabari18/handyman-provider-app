import 'package:flutter/material.dart';
import 'package:handyman_provider_flutter/components/handyman_name_widget.dart';
import 'package:handyman_provider_flutter/components/image_border_component.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/booking_list_response.dart';
import 'package:handyman_provider_flutter/models/service_model.dart';
import 'package:handyman_provider_flutter/models/user_data.dart';
import 'package:handyman_provider_flutter/screens/chat/chat_room_screen.dart';
import 'package:handyman_provider_flutter/utils/colors.dart';
import 'package:handyman_provider_flutter/utils/common.dart';
import 'package:handyman_provider_flutter/utils/configs.dart';
import 'package:handyman_provider_flutter/utils/constant.dart';
import 'package:handyman_provider_flutter/utils/images.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/booking_detail_response.dart';
import '../utils/model_keys.dart';

class BasicInfoComponent extends StatefulWidget {
  final UserData? handymanData;
  final UserData? customerData;
  final UserData? providerData;
  final ServiceData? service;
  final BookingDetailResponse? bookingInfo;
  final bool isshow;

  /// flag == 0 = customer
  /// flag == 1 = handyman
  /// else provider
  final int flag;

  final BookingData? bookingDetail;

  BasicInfoComponent(
    this.flag, {
    this.customerData,
    this.handymanData,
    this.providerData,
    this.service,
    this.bookingDetail,
    this.bookingInfo,
    this.isshow = true,
  });

  @override
  BasicInfoComponentState createState() => BasicInfoComponentState();
}

class BasicInfoComponentState extends State<BasicInfoComponent> {
  UserData customer = UserData();
  UserData provider = UserData();
  UserData userData = UserData();
  ServiceData service = ServiceData();

  String? googleUrl;
  String? address;
  String? name;
  String? contactNumber;
  String? profileUrl;
  int? profileId;
  int? handymanRating;
  int? flag;
  bool isChattingAllow = false;
  bool showVerifiedBadge = false;
  bool showContactWidgets = false;
  bool showChat = false;

  @override
  void initState() {
    super.initState();
    init();

    log("=========== CHAT OPEN DEBUG ===========");
    log("BOOKING ID => ${widget.bookingDetail?.id}");
    log("CUSTOMER ID => ${widget.bookingDetail?.customerId}");
    log("PROVIDER ID => ${widget.bookingDetail?.providerId}");
    log("HANDYMAN DATA => ${widget.handymanData?.id}");
    log("APP USER ID => ${appStore.userId}");
    log("APP USER TYPE => ${appStore.userType}");
    log("MY CHAT ID => ${getStringAsync('my_chat_id')}");
    log("=======================================");
  }

  Future<void> init() async {
    if (widget.flag == 0) {
      profileId = widget.customerData!.id.validate();
      name = widget.customerData!.displayName.validate();
      profileUrl = widget.customerData!.profileImage.validate();
      contactNumber = widget.customerData!.contactNumber.validate();
      address = widget.customerData!.address.validate();
      userData = widget.customerData!;
      showContactWidgets = widget.bookingDetail!.status != BookingStatusKeys.complete &&
          widget.bookingDetail!.status != BookingStatusKeys.cancelled;
      showChat = true;
      showVerifiedBadge = widget.customerData!.isVerifiedAccount.validate().getBoolInt();
    } else if (widget.flag == 1) {
      profileId = widget.handymanData!.id.validate();
      name = widget.handymanData!.displayName.validate();
      profileUrl = widget.handymanData!.profileImage.validate();
      contactNumber = widget.handymanData!.contactNumber.validate();
      address = widget.handymanData!.address.validate();
      userData = widget.handymanData!;
      showContactWidgets = widget.bookingInfo != null &&
          widget.bookingInfo!.providerData!.id.validate() != widget.handymanData!.id.validate();
      showVerifiedBadge = widget.handymanData!.isVerifiedAccount.validate().getBoolInt();
      showChat = widget.bookingDetail!.status != BookingStatusKeys.complete &&
          widget.bookingDetail!.status != BookingStatusKeys.cancelled;
    } else {
      final bool hasAssignedHandyman = widget.handymanData != null && widget.handymanData!.id != null;

      log("PROVIDER HAS ASSIGNED HANDYMAN => $hasAssignedHandyman");

      profileId = widget.providerData!.id.validate();
      name = widget.providerData!.displayName.validate();
      profileUrl = widget.providerData!.profileImage.validate();
      contactNumber = widget.providerData!.contactNumber.validate();
      address = widget.providerData!.address.validate();
      provider = widget.providerData!;
      showVerifiedBadge = widget.providerData!.isVerifiedAccount.validate().getBoolInt();
      showChat = !hasAssignedHandyman &&
          widget.bookingDetail!.status != BookingStatusKeys.complete &&
          widget.bookingDetail!.status != BookingStatusKeys.cancelled;

      log("PROVIDER SHOW CHAT => $showChat");
    }

    setState(() {});
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  // Helper function to check if booking status is pending or accepted
  // Returns true if status is pending or accepted (buttons should be HIDDEN)
  bool shouldHideCallAndChatButtons() {
    final status = widget.bookingDetail?.status;
    // Hide buttons for pending and accepted statuses
    return status == BookingStatusKeys.pending || status == BookingStatusKeys.accept;
  }

  @override
  Widget build(BuildContext context) {
    final handymanList = widget.bookingDetail?.handyman ?? [];

    log("HANDYMAN LIST => $handymanList");
    log("HANDYMAN COUNT => ${handymanList.length}");

    final bool isHandymanLogin = appStore.userType == 'handyman';

    final String targetChatId = isHandymanLogin
        ? 'handyman_${appStore.userId}'
        : 'provider_${widget.bookingDetail?.providerId}';

    log("IS HANDYMAN LOGIN => $isHandymanLogin");
    log("TARGET CHAT ID => $targetChatId");

    // Check if buttons should be hidden (hidden for pending and accepted statuses)
    final bool hideButtons = shouldHideCallAndChatButtons();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (profileUrl.validate().isNotEmpty)
              ImageBorder(
                src: profileUrl.validate(),
                height: 45,
              ),
            16.width,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    HandymanNameWidget(
                      name: name.validate(),
                      size: 14,
                      showVerifiedBadge: showVerifiedBadge,
                    ).flexible(),
                  ],
                ),
                if (widget.flag == 1 && userData.handymanRating.validate().toDouble() > 0)
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: rattingColor,
                        size: 16,
                      ),
                      2.width,
                      Text(
                        '${userData.handymanRating.validate().toDouble()}',
                        style: secondaryTextStyle(
                          weight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ).expand(),
          ],
        ),
        if (widget.bookingDetail!.canCustomerContact && widget.flag == 0)
          Column(
            children: [
              16.height,
              if (userData.email.validate().isNotEmpty)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languages.email,
                      style: boldTextStyle(
                        size: 12,
                        color: appStore.isDarkMode ? textSecondaryColor : textPrimaryColor,
                      ),
                    ).expand(),
                    8.width,
                    Text(
                      userData.email.validate(),
                      style: boldTextStyle(
                        size: 12,
                        color: appStore.isDarkMode ? white : textSecondaryColor,
                        weight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.left,
                    ).expand(flex: 4),
                  ],
                ).onTap(() {
                  launchMail(userData.email.validate());
                }),
              if (widget.bookingDetail != null) ...[
                8.height,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${languages.lblAddress}:',
                      style: boldTextStyle(
                        size: 12,
                        color: appStore.isDarkMode ? textSecondaryColor : textPrimaryColor,
                      ),
                    ).expand(),
                    8.width,
                    Text(
                      widget.bookingDetail!.address.validate(),
                      style: boldTextStyle(
                        size: 12,
                        color: appStore.isDarkMode ? white : textSecondaryColor,
                        weight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.left,
                    ).expand(flex: 4),
                  ],
                )
                    .visible(widget.bookingDetail!.address.validate().isNotEmpty)
                    .onTap(() {
                  commonLaunchUrl(
                    '$GOOGLE_MAP_PREFIX${Uri.encodeFull(widget.bookingDetail!.address.validate())}',
                    launchMode: LaunchMode.externalApplication,
                  );
                }),
                8.height,
              ],
            ],
          ).paddingSymmetric(horizontal: 4),

        // Only show Call and Chat buttons if hideButtons is false (status is NOT pending or accepted)
        if (contactNumber.validate().isNotEmpty && !hideButtons) ...[
          16.height,
          Row(
            children: [
              if (showContactWidgets) ...[
                AppButton(
                  shapeBorder: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey, width: 1.2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        calling,
                        height: 18,
                        width: 18,
                      ),
                      16.width,
                      Text(
                        languages.lblCall,
                        style: boldTextStyle(),
                      ),
                    ],
                  ),
                  width: context.width(),
                  color: context.scaffoldBackgroundColor,
                  elevation: 0,
                  onTap: () {
                    launchCall(contactNumber.validate());
                  },
                ).expand(),
                24.width,
              ],
              if (showChat && widget.isshow && !hideButtons)
                AppButton(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        chat,
                        color: Colors.white,
                        height: 18,
                        width: 18,
                      ),
                      16.width,
                      Text(
                        languages.lblChat,
                        style: boldTextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  width: showContactWidgets ? context.width() : context.width() / 2,
                  elevation: 0,
                  color: primaryColor,
                  onTap: () async {
                    log("=========== CHAT OPEN DEBUG ===========");
                    log("BOOKING ID => ${widget.bookingDetail?.id}");
                    log("CUSTOMER ID => ${widget.bookingDetail?.customerId}");
                    log("PROVIDER ID => ${widget.bookingDetail?.providerId}");
                    log("HANDYMAN DATA => ${widget.handymanData?.id}");
                    log("APP USER ID => ${appStore.userId}");
                    log("APP USER TYPE => ${appStore.userType}");
                    log("MY CHAT ID => ${getStringAsync('my_chat_id')}");
                    log("IS HANDYMAN BOOKING => $isHandymanLogin");
                    log("TARGET CHAT ID => $targetChatId");
                    log("=======================================");

                    // Determine if chatting is allowed based on booking status
                    bool isChattingAllow = false;
                    if (widget.bookingDetail != null) {
                      isChattingAllow = widget.bookingDetail!.status == BookingStatusKeys.complete ||
                          widget.bookingDetail!.status == BookingStatusKeys.cancelled;
                    }

                    // Get the receiver name and image
                    String receiverName = "";
                    String receiverImage = "";
                    String receiverPhone = "";
                    
                    if (widget.flag == 0) {
                      // Customer chat
                      receiverName = widget.customerData?.displayName ?? "Customer";
                      receiverImage = widget.customerData?.profileImage ?? "";
                      receiverPhone = widget.customerData?.contactNumber ?? "";
                    } else if (widget.flag == 1) {
                      // Handyman chat
                      receiverName = widget.handymanData?.displayName ?? "Handyman";
                      receiverImage = widget.handymanData?.profileImage ?? "";
                      receiverPhone = widget.handymanData?.contactNumber ?? "";
                    } else {
                      // Provider chat
                      receiverName = widget.providerData?.displayName ?? "Provider";
                      receiverImage = widget.providerData?.profileImage ?? "";
                      receiverPhone = widget.providerData?.contactNumber ?? "";
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatRoomScreen(
                          bookingId: widget.bookingDetail?.id?.toString() ?? '',
                          myChatId: getStringAsync('my_chat_id'),
                          targetChatId: targetChatId,
                          receiverName: receiverName,
                          receiverImage: receiverImage,
                          receiverPhone: receiverPhone,
                          isHandymanChat: isHandymanLogin,
                          isChattingAllow: isChattingAllow,
                        ),
                      ),
                    );
                  },
                ).expand(),
            ],
          ),
        ],
      ],
    );
  }
}