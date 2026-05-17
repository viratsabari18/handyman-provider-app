import 'package:flutter/material.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/booking_list_response.dart';
import 'package:nb_utils/nb_utils.dart';
import 'dart:async';

import '../../components/booking_item_component.dart';
import '../../components/view_all_label_component.dart';
import '../../utils/constant.dart';

class UpcomingBookingComponent extends StatefulWidget {
  final List<BookingData> bookingData;

  const UpcomingBookingComponent({required this.bookingData});

  @override
  State<UpcomingBookingComponent> createState() => _UpcomingBookingComponentState();
}

class _UpcomingBookingComponentState extends State<UpcomingBookingComponent> {
  String displayedText = "";
  String fullText = "";
  Timer? _timer;
  int currentIndex = 0;
  bool isDeleting = false;

  @override
  void initState() {
    super.initState();
    // Initialize the fullText with localized string
    fullText = languages.waitingForWork;
    startTypingEffectLoop();
  }

  void startTypingEffectLoop() {
    _timer = Timer.periodic(Duration(milliseconds: 150), (timer) {
      setState(() {
        if (!isDeleting) {
          // Typing forward
          if (currentIndex < fullText.length) {
            displayedText += fullText[currentIndex];
            currentIndex++;
          } else {
            // Wait for 1 second before starting to delete
            Future.delayed(Duration(seconds: 1), () {
              if (mounted) {
                setState(() {
                  isDeleting = true;
                });
              }
            });
          }
        } else {
          // Deleting backward
          if (displayedText.isNotEmpty) {
            displayedText = displayedText.substring(0, displayedText.length - 1);
            currentIndex--;
          } else {
            // Reset and start over
            isDeleting = false;
            currentIndex = 0;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bookingData.isEmpty) {
      // Check if the current user is Handyman
      if (appStore.userType==USER_TYPE_HANDYMAN) {
        // Show empty state UI for Handyman
        return Container(
          height: MediaQuery.of(context).size.height * 0.28,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title Text
              Text(
                languages.noWorkAssignedYet.toUpperCase(),
                style: boldTextStyle(
                  size: 18,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              8.height,
              
              // Description
              Text(
                languages.yourWorkWillBeVisibleHere,
                style: secondaryTextStyle(
                  size: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ).paddingSymmetric(horizontal: 40),
              
              24.height,
              
              // Button with fixed size
              SizedBox(
                width: 220,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // Optional: Add refresh functionality
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFDB0008),
                    foregroundColor: Colors.white,
                    shadowColor: Color(0xFFDB0008).withOpacity(0.3),
                    elevation: 5,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        displayedText,
                        style: boldTextStyle(
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      if (displayedText.isNotEmpty && displayedText.length < fullText.length)
                        Container(
                          width: 2,
                          height: 20,
                          color: Colors.white,
                          margin: EdgeInsets.only(left: 4),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        // For Provider, return Offstage when empty
        return Offstage();
      }
    }

    // When bookings are not empty, show the booking list
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        8.height,
        ViewAllLabel(
          label: languages.upcomingBookings,
          list: widget.bookingData,
          onTap: () {
            LiveStream().emit(LIVESTREAM_PROVIDER_ALL_BOOKING, 1);
            LiveStream().emit(LIVESTREAM_CHANGE_HANDYMAN_TAB, {"index": 1});
          },
        ),
        8.height,
        AnimatedListView(
          itemCount: widget.bookingData.length,
          shrinkWrap: true,
          listAnimationType: ListAnimationType.FadeIn,
          fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
          itemBuilder: (_, i) => BookingItemComponent(bookingData: widget.bookingData[i], showDescription: false),
        ),
      ],
    ).paddingSymmetric(horizontal: 16);
  }
}