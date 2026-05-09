import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/booking_detail_response.dart';
import 'package:handyman_provider_flutter/models/booking_list_response.dart';
import 'package:handyman_provider_flutter/models/revenue_chart_data.dart';
import 'package:nb_utils/nb_utils.dart';

import '../utils/constant.dart';

class HandymanDashBoardResponse {
  Commission? commission;
  List<RatingData>? handymanReviews;
  bool? status;

  num? todayBooking;
  num? totalBooking;
  num? totalRevenue;
  num? todayCashAmount;
  num? totalCashInHand;
  num? notificationUnreadCount;
  num? remainingPayout;

  List<BookingData>? upcomingBookings;

  int? isHandymanAvailable;
  int? completedBooking;
  int? isEmailVerified;

  HandymanDashBoardResponse({
    this.isEmailVerified,
    this.commission,
    this.handymanReviews,
    this.status,
    this.totalCashInHand,
    this.todayBooking,
    this.totalBooking,
    this.totalRevenue,
    this.upcomingBookings,
    this.todayCashAmount,
    this.isHandymanAvailable,
    this.completedBooking,
    this.notificationUnreadCount,
    this.remainingPayout,
  });

  HandymanDashBoardResponse.fromJson(Map<String, dynamic> json) {
    /// Commission
    commission = json['commission'] != null
        ? Commission.fromJson(json['commission'])
        : null;

    /// Reviews
    handymanReviews = json['handyman_reviews'] != null
        ? (json['handyman_reviews'] as List)
            .map((i) => RatingData.fromJson(i))
            .toList()
        : null;

    /// Basic
    status = json['status'];

    /// Safe numeric parsing
    todayBooking =
        num.tryParse(json['today_booking']?.toString() ?? '0');

    todayCashAmount =
        num.tryParse(json['today_cash']?.toString() ?? '0');

    totalCashInHand =
        num.tryParse(json['total_cash_in_hand']?.toString() ?? '0');

    totalBooking =
        num.tryParse(json['total_booking']?.toString() ?? '0');

    totalRevenue =
        num.tryParse(json['total_revenue']?.toString() ?? '0');

    notificationUnreadCount =
        num.tryParse(
          json['notification_unread_count']?.toString() ?? '0',
        );

    remainingPayout =
        num.tryParse(
          json['remaining_payout']?.toString() ?? '0',
        );

    /// Upcoming bookings
    upcomingBookings = json['upcomming_booking'] != null
        ? (json['upcomming_booking'] as List)
            .map((i) => BookingData.fromJson(i))
            .toList()
        : null;

    /// Integer parsing
    isHandymanAvailable = int.tryParse(
      json['isHandymanAvailable']?.toString() ?? '0',
    );

    completedBooking = int.tryParse(
      json['completed_booking']?.toString() ?? '0',
    );

    isEmailVerified = int.tryParse(
      json['is_email_verified']?.toString() ?? '0',
    );

    /// Revenue chart safe handling
    chartData = [];

    if (json['monthly_revenue'] != null &&
        json['monthly_revenue']['revenueData'] != null) {
      Iterable it = json['monthly_revenue']['revenueData'];

it.forEachIndexed((element, index) {
  if ((element as Map).containsKey('${index + 1}')) {
    chartData.add(
      RevenueChartData(
        month: months[index],
        revenue: double.tryParse(
              element[(index + 1).toString()]
                  .toString(),
            ) ??
            0.0,
      ),
    );
  } else {
    chartData.add(
      RevenueChartData(
        month: months[index],
        revenue: 0.0,
      ),
    );
  }
});
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    data['status'] = status;

    data['is_email_verified'] = isEmailVerified;

    data['today_booking'] = todayBooking;

    data['total_booking'] = totalBooking;

    data['completed_booking'] = completedBooking;

    data['today_cash'] = todayCashAmount;

    data['total_cash_in_hand'] = totalCashInHand;

    data['notification_unread_count'] =
        notificationUnreadCount;

    data['remaining_payout'] = remainingPayout;

    data['isHandymanAvailable'] =
        isHandymanAvailable;

    if (upcomingBookings != null) {
      data['upcomming_booking'] =
          upcomingBookings!
              .map((v) => v.toJson())
              .toList();
    }

    if (commission != null) {
      data['commission'] = commission!.toJson();
    }

    if (handymanReviews != null) {
      data['handyman_reviews'] =
          handymanReviews!
              .map((v) => v.toJson())
              .toList();
    }

    return data;
  }
}

class Commission {
  num? commission;

  String? createdAt;
  String? deletedAt;
  String? name;
  String? type;
  String? updatedAt;

  int? id;
  int? status;

  Commission({
    this.commission,
    this.createdAt,
    this.deletedAt,
    this.id,
    this.name,
    this.status,
    this.type,
    this.updatedAt,
  });

  factory Commission.fromJson(
    Map<String, dynamic> json,
  ) {
    return Commission(
      commission: num.tryParse(
        json['commission']?.toString() ?? '0',
      ),

      createdAt: json['created_at']?.toString(),

      deletedAt: json['deleted_at']?.toString(),

      id: int.tryParse(
        json['id']?.toString() ?? '0',
      ),

      name: json['name']?.toString(),

      status: int.tryParse(
        json['status']?.toString() ?? '0',
      ),

      type: json['type']?.toString(),

      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    data['commission'] = commission;
    data['created_at'] = createdAt;
    data['deleted_at'] = deletedAt;
    data['id'] = id;
    data['name'] = name;
    data['status'] = status;
    data['type'] = type;
    data['updated_at'] = updatedAt;

    return data;
  }
}