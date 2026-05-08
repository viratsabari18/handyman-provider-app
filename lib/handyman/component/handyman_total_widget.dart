import 'package:flutter/material.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:nb_utils/nb_utils.dart';

class HandymanTotalWidget extends StatelessWidget {
  final String title;
  final String total;
  final String icon;
  final Color? color;

  const HandymanTotalWidget({
    super.key,
    required this.title,
    required this.total,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ Same dynamic colors as your first widget
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color bgColor = color ?? (isDark ? Colors.black : Colors.white);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      width: context.width() / 2 - 24,

      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),

        // ✅ SAME shadow logic
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.white.withAlpha(150)
                : Colors.black.withAlpha(100),
            offset: const Offset(0, 6),
            blurRadius: 10,
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              /// TOTAL TEXT
              SizedBox(
                width: context.width() / 2 - 94,
                child: Marquee(
                  child: Text(
                    total.validate(),
                    style: boldTextStyle(
                      color: Colors.black,
                      size: 16,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),

              /// ICON
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.black : Colors.white, // ✅ SAME
                ),
                child: Image.asset(
                  icon,
                  width: 18,
                  height: 18,
                  color: isDark ? Colors.white : Colors.black, // ✅ SAME
                ),
              ),
            ],
          ),

          8.height,

          /// TITLE
          Marquee(
            child: Text(
              title.validate(),
              style: secondaryTextStyle(
                size: 14,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}