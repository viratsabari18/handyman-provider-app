import 'package:flutter/material.dart';
import 'package:handyman_provider_flutter/Models_new/about_us_model.dart';
import 'package:handyman_provider_flutter/components/html_widget.dart';

import 'package:handyman_provider_flutter/main.dart';

import 'package:handyman_provider_flutter/networks/rest_apis.dart';
import 'package:nb_utils/nb_utils.dart';

class AboutUsScreen extends StatefulWidget {
  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen> {
  Future<AboutUsModel>? future;

  @override
  void initState() {
    super.initState();
    future = getAboutUs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: appBarWidget(languages.lblAbout),

      // COMMENTED OLD UI
      // body: AnimatedWrap(
      //   spacing: 16,
      //   runSpacing: 16,
      //   itemCount: aboutList.length,
      //   listAnimationType: ListAnimationType.FadeIn,
      //   fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
      //   scaleConfiguration: ScaleConfiguration(duration: 400.milliseconds, delay: 50.milliseconds),
      //   itemBuilder: (context, index) {
      //     return Container();
      //   },
      // ).paddingAll(16),

      body: FutureBuilder<AboutUsModel>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                style: boldTextStyle(),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                'No Data Found',
                style: boldTextStyle(),
              ),
            );
          }

        return HtmlWidget(
  postContent: snapshot.data?.data ?? '',
  title: languages.lblAbout,
);
        },
      ),
    );
  }
}