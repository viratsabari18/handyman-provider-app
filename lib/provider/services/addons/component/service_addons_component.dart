import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../components/cached_image_widget.dart';
import '../../../../components/price_widget.dart';
import '../../../../components/view_all_label_component.dart';
import '../../../../main.dart';
import '../../../../models/booking_detail_response.dart';

class AddonComponent extends StatefulWidget {
  final List<ServiceAddon> serviceAddon;

  AddonComponent({
    required this.serviceAddon,
  });

  @override
  _AddonComponentState createState() => _AddonComponentState();
}

class _AddonComponentState extends State<AddonComponent> {
  double imageHeight = 60;

  @override
  void initState() {
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.serviceAddon.isEmpty) return Offstage();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ViewAllLabel(
          label: languages.addOns,
          list: [],
          onTap: () {},
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: widget.serviceAddon.length,
          separatorBuilder: (context, index) => Divider(
            height: 0,
            thickness: 1,
            color: Colors.grey.withOpacity(0.3),
          ),
          itemBuilder: (context, index) {
            ServiceAddon data = widget.serviceAddon[index];
            
            return Container(
              width: context.width(),
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.only(bottom: 16),
              decoration: boxDecorationWithRoundedCorners(
                borderRadius: radius(),
                backgroundColor: context.cardColor,
                border: appStore.isDarkMode 
                    ? Border.all(color: context.dividerColor) 
                    : null,
              ),
              child: Row(
                children: [
                  CachedImageWidget(
                    url: data.serviceAddonImage,
                    height: imageHeight,
                    fit: BoxFit.cover,
                    radius: defaultRadius,
                  ),
                  16.width,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Marquee(
                          directionMarguee: DirectionMarguee.oneDirection,
                          child: Text(data.name.validate(), style: boldTextStyle()),
                        ),
                        2.height,
                        PriceWidget(
                          price: data.price.validate(),
                          hourlyTextColor: Colors.white,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                  if (data.status.getBoolInt())
                    Icon(
                      Icons.check_circle_outline_outlined,
                      size: 24,
                      color: Colors.green,
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}