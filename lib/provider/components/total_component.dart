import 'package:flutter/material.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/dashboard_response.dart';
import 'package:handyman_provider_flutter/provider/components/total_widget.dart';
import 'package:handyman_provider_flutter/provider/services/service_list_screen.dart';
import 'package:handyman_provider_flutter/screens%20new/category_list.dart';
import 'package:handyman_provider_flutter/screens/total_earning_screen.dart';
import 'package:handyman_provider_flutter/utils/constant.dart';
import 'package:handyman_provider_flutter/utils/extensions/num_extenstions.dart';
import 'package:handyman_provider_flutter/utils/images.dart';
import 'package:nb_utils/nb_utils.dart';

class TotalComponent extends StatelessWidget {
  final DashboardResponse snap;

  TotalComponent({required this.snap});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        TotalWidget(
          title: languages.lblTotalBooking,
          total: snap.totalBooking.toString(),
          icon: total_booking,
          color: Color(0xFFE5E9EB),
        ).onTap(
          () {
            LiveStream().emit(LIVESTREAM_PROVIDER_ALL_BOOKING, 1);
          },
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
        ),
        // TotalWidget(
        //   title: languages.lblTotalService,
        //   total: snap.totalService.validate().toString(),
        //   color: Color(0xFFF5F5CE),
        //   icon: total_services,
        // ).onTap(
        //   () {
        //     ServiceListScreen().launch(context);
        //   },
        //   highlightColor: Colors.transparent,
        //   splashColor: Colors.transparent,
        // ),
        TotalWidget(
          title: languages.remainingPayout,
          total: snap.remainingPayout.validate().toPriceFormat().toString(),
          icon: ic_remainng_payout_new,
          color: Color(0xFFF5EEF5),
        ),
        TotalWidget(
          title: languages.totalRevenue,
          total: snap.totalRevenue.validate().toPriceFormat(),
          icon: total_revenue_final,
          color: Color(0xFFEFF4F6),
        ).onTap(
          () {
            TotalEarningScreen().launch(context);
          },
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
        ),
        TotalWidget(
          title: languages.totalCategory,
          total: snap.totalCategory.toString(),
          icon: ic_filter,
          color: Color.fromARGB(255, 252, 232, 232),
        )
        .onTap(
          () {
            CategoryList().launch(context);
          },
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
        ),
        TotalWidget(
          title: languages.totalZone,
          total: snap.totalZone.toString(),
          icon: ic_location,
          color: Color.fromARGB(255, 206, 245, 209),
        )
        // .onTap(
        //   () {
        //     CategoryList().launch(context);
        //   },
        //   highlightColor: Colors.transparent,
        //   splashColor: Colors.transparent,
        // ),
      ],
    ).paddingAll(16);
  }
}
