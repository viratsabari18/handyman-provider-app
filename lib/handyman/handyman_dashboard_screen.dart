import 'dart:ui';

import 'package:carousel_slider/carousel_slider.dart' as carousel;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:handyman_provider_flutter/Models_new/handyman_carousel.dart';
import 'package:handyman_provider_flutter/components/my_provider_widget.dart';
import 'package:handyman_provider_flutter/fragments/booking_fragment.dart';
import 'package:handyman_provider_flutter/fragments/notification_fragment.dart';
import 'package:handyman_provider_flutter/handyman/screen/fragments/handyman_fragment.dart';
import 'package:handyman_provider_flutter/handyman/screen/fragments/handyman_profile_fragment.dart';
import 'package:handyman_provider_flutter/main.dart';

import 'package:handyman_provider_flutter/networks/rest_apis.dart';
import 'package:handyman_provider_flutter/screens/chat/user_chat_list_screen.dart';
import 'package:handyman_provider_flutter/utils/colors.dart';
import 'package:handyman_provider_flutter/utils/common.dart';
import 'package:handyman_provider_flutter/utils/configs.dart';
import 'package:handyman_provider_flutter/utils/constant.dart';
import 'package:handyman_provider_flutter/utils/extensions/string_extension.dart';
import 'package:handyman_provider_flutter/utils/images.dart';
import 'package:nb_utils/nb_utils.dart';

import '../booking_filter/booking_filter_screen.dart';
import '../components/image_border_component.dart';
import '../utils/app_configuration.dart';

class HandymanDashboardScreen extends StatefulWidget {
  final int? index;

  const HandymanDashboardScreen({super.key, this.index});

  @override
  State<HandymanDashboardScreen> createState() =>
      _HandymanDashboardScreenState();
}

class _HandymanDashboardScreenState
    extends State<HandymanDashboardScreen> {
  int currentIndex = 0;
  int currentCarouselIndex = 0;

  List<String> carouselImages = [];

  late List<Widget> fragmentList;

  bool get isCurrentFragmentIsBooking =>
      fragmentList[currentIndex].runtimeType ==
      BookingFragment().runtimeType;

  @override
  void initState() {
    super.initState();

    currentIndex = widget.index ?? 0;

    fragmentList = [
      HandymanHomeFragment(),
      BookingFragment(),
      if (appConfigurationStore.isEnableChat) ChatListScreen(),
      HandymanProfileFragment(),
    ];

    init();
  }

  Future<void> getCarouselData() async {
    try {
      CarouselResponse res = await getCarouselImages();

      if (res.status) {
        carouselImages = res.carouselImages;
        setState(() {});
      }
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> init() async {
    setStatusBarColor(
      Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    );

    await getCarouselData();

    afterBuildCreated(() async {
      if (getIntAsync(THEME_MODE_INDEX) == THEME_MODE_SYSTEM) {
        appStore.setDarkMode(
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark,
        );
      }

      PlatformDispatcher.instance.onPlatformBrightnessChanged = () {
        if (getIntAsync(THEME_MODE_INDEX) == THEME_MODE_SYSTEM) {
          appStore.setDarkMode(
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark,
          );
        }
      };
    });

    LiveStream().on(LIVESTREAM_CHANGE_HANDYMAN_TAB, (data) {
      currentIndex = (data as Map)["index"];

      setState(() {});

      100.milliseconds.delay.then((value) {
        if (data.containsKey('booking_type')) {
          LiveStream().emit(
            LIVESTREAM_UPDATE_BOOKING_STATUS_WISE,
            data['booking_type'],
          );
        } else if (currentIndex == 1) {
          LiveStream().emit(
            LIVESTREAM_UPDATE_BOOKING_STATUS_WISE,
            '',
          );
        }
      });
    });

    await 3.seconds.delay;

    if (getBoolAsync(FORCE_UPDATE_PROVIDER_APP)) {
      showForceUpdateDialog(context);
    }
  }

  @override
  void dispose() {
    LiveStream().dispose(LIVESTREAM_CHANGE_HANDYMAN_TAB);
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    bool isHomeTab = currentIndex == 0;

    return DoublePressBackWidget(
      message: languages.lblCloseAppMsg,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Column(
          children: [
            if (isHomeTab)
              Stack(
                children: [
                  /// IMAGE SLIDER
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(35),
                      bottomRight: Radius.circular(35),
                    ),
                    child: SizedBox(
                      height: 300,
                      width: context.width(),
                      child: carousel.CarouselSlider(
                        options: carousel.CarouselOptions(
                          height: 300,
                          viewportFraction: 1,
                          autoPlay: true,
                          enlargeCenterPage: false,
                          autoPlayInterval:
                              const Duration(seconds: 4),
                          onPageChanged: (index, reason) {
                            setState(() {
                              currentCarouselIndex = index;
                            });
                          },
                        ),
                        items: carouselImages.isNotEmpty
                            ? carouselImages.map((imageUrl) {
                                return Image.network(
                                  imageUrl,
                                  width: context.width(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) {
                                    return Container(
                                      color: Colors.grey.shade300,
                                      child: const Center(
                                        child: Icon(
                                          Icons.image_not_supported,
                                          size: 40,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }).toList()
                            : [
                                Container(
                                  color: Colors.grey.shade300,
                                  child: const Center(
                                    child:
                                        CircularProgressIndicator(),
                                  ),
                                ),
                              ],
                      ),
                    ),
                  ),

                  /// DARK OVERLAY
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(35),
                          bottomRight: Radius.circular(35),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.2),
                            Colors.black.withOpacity(0.55),
                          ],
                        ),
                      ),
                    ),
                  ),

                  /// TOP CONTENT
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "${languages.lblHello}, ${appStore.userFullName}",
                              style: boldTextStyle(
                                size: 22,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          /// INFO BUTTON
                          IconButton(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                shape: RoundedRectangleBorder(
                                  borderRadius: radius(),
                                ),
                                clipBehavior:
                                    Clip.antiAliasWithSaveLayer,
                                builder: (_) {
                                  return MyProviderWidget();
                                },
                              );
                            },
                            icon: ic_info.iconImage(
                              color: Colors.white,
                            ),
                          ),

                          10.width,

                          /// NOTIFICATION
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              IconButton(
                                onPressed: () {
                                  NotificationFragment()
                                      .launch(context);
                                },
                                icon:
                                    ic_notification.iconImage(
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),

                              Positioned(
                                top: -2,
                                right: -2,
                                child: Observer(
                                  builder: (_) {
                                    if (appStore
                                            .notificationCount >
                                        0) {
                                      return Container(
                                        padding:
                                            const EdgeInsets.all(
                                                5),
                                        decoration:
                                            boxDecorationDefault(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          appStore
                                              .notificationCount
                                              .toString(),
                                          style:
                                              primaryTextStyle(
                                            size: 10,
                                            color: Colors.white,
                                          ),
                                        ),
                                      );
                                    }

                                    return const SizedBox();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  /// DOT INDICATORS
                  if (carouselImages.isNotEmpty)
                    Positioned(
                      bottom: 18,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children:
                            carouselImages.asMap().entries.map(
                          (entry) {
                            return AnimatedContainer(
                              duration: const Duration(
                                  milliseconds: 300),
                              width:
                                  currentCarouselIndex ==
                                          entry.key
                                      ? 20
                                      : 8,
                              height: 8,
                              margin:
                                  const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(20),
                                color:
                                    currentCarouselIndex ==
                                            entry.key
                                        ? Colors.white
                                        : Colors.white54,
                              ),
                            );
                          },
                        ).toList(),
                      ),
                    ),
                ],
              )

            /// OTHER PAGE HEADER
            else
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          [
                            languages.lblBooking,
                            if (appConfigurationStore
                                .isEnableChat)
                              languages.lblChat,
                            languages.lblProfile,
                          ][currentIndex - 1],
                          style: boldTextStyle(size: 22),
                        ),
                      ),

                      if (isCurrentFragmentIsBooking)
                        IconButton(
                          onPressed: () async {
                            BookingFilterScreen()
                                .launch(context)
                                .then((value) {
                              if (value != null) {
                                LiveStream().emit(
                                  LIVESTREAM_UPDATE_BOOKINGS,
                                );
                              }
                            });
                          },
                          icon: ic_filter.iconImage(
                            size: 22,
                            color: context.iconColor,
                          ),
                        ),

                      IconButton(
                        onPressed: () {
                          NotificationFragment()
                              .launch(context);
                        },
                        icon: ic_notification.iconImage(
                          size: 22,
                          color: context.iconColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            Expanded(
              child: fragmentList[currentIndex],
            ),
          ],
        ),

        /// BOTTOM NAVIGATION
        bottomNavigationBar: Blur(
          blur: 30,
          borderRadius: radius(0),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor:
                  context.cardColor.withOpacity(0.95),
              indicatorColor:
                  context.primaryColor.withOpacity(0.12),
              labelTextStyle:
                  WidgetStateProperty.all(
                primaryTextStyle(size: 12),
              ),
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.transparent,
            ),
            child: NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: (index) {
                currentIndex = index;
                setState(() {});
              },
              destinations: [
                NavigationDestination(
                  icon: ic_home.iconImage(
                    color: appTextSecondaryColor,
                  ),
                  selectedIcon:
                      ic_fill_home.iconImage(
                    color: context.primaryColor,
                  ),
                  label: languages.home,
                ),

                NavigationDestination(
                  icon: total_booking.iconImage(
                    color: appTextSecondaryColor,
                  ),
                  selectedIcon:
                      fill_ticket.iconImage(
                    color: context.primaryColor,
                  ),
                  label: languages.lblBooking,
                ),

                if (appConfigurationStore.isEnableChat)
                  NavigationDestination(
                    icon: Image.asset(
                      chat,
                      height: 20,
                      width: 20,
                      color: appTextSecondaryColor,
                    ),
                    selectedIcon: Image.asset(
                      ic_fill_textMsg,
                      height: 26,
                      width: 26,
                    ),
                    label: languages.lblChat,
                  ),

                Observer(
                  builder: (_) {
                    return NavigationDestination(
                      icon:
                          (appStore.isLoggedIn &&
                                  appStore
                                      .userProfileImage
                                      .isNotEmpty)
                              ? IgnorePointer(
                                  ignoring: true,
                                  child: ImageBorder(
                                    src:
                                        appStore.userProfileImage,
                                    height: 26,
                                  ),
                                )
                              : profile.iconImage(
                                  color:
                                      appTextSecondaryColor,
                                ),
                      selectedIcon:
                          (appStore.isLoggedIn &&
                                  appStore
                                      .userProfileImage
                                      .isNotEmpty)
                              ? IgnorePointer(
                                  ignoring: true,
                                  child: ImageBorder(
                                    src:
                                        appStore.userProfileImage,
                                    height: 26,
                                  ),
                                )
                              : ic_fill_profile.iconImage(
                                  color:
                                      context.primaryColor,
                                ),
                      label: languages.lblProfile,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}