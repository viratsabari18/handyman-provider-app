import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:handyman_provider_flutter/auth/sign_in_screen.dart';
import 'package:handyman_provider_flutter/handyman/handyman_dashboard_screen.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/provider/provider_dashboard_screen.dart';
import 'package:handyman_provider_flutter/screens/maintenance_mode_screen.dart';
import 'package:handyman_provider_flutter/utils/common.dart';
import 'package:handyman_provider_flutter/utils/configs.dart';
import 'package:handyman_provider_flutter/utils/images.dart';
import 'package:nb_utils/nb_utils.dart';

import '../components/app_widgets.dart';
import '../networks/rest_apis.dart';
import '../utils/constant.dart';

class SplashScreen extends StatefulWidget {
  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  bool appNotSynced = false;

  @override
  void initState() {
    super.initState();

    afterBuildCreated(() {
      setStatusBarColor(
        Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness:
            appStore.isDarkMode ? Brightness.light : Brightness.dark,
      );

      init();
    });
  }

  Future<void> init() async {
    await setValue(LAST_APP_CONFIGURATION_SYNCED_TIME, 0);

    bool configSuccess = false;

    try {
      await getAppConfigurations();

      configSuccess = true;

      await setValue(
        IS_APP_CONFIGURATION_SYNCED_AT_LEAST_ONCE,
        true,
      );
    } catch (e) {
      log("Config API failed: $e");

      if (!await isNetworkAvailable()) {
        toast(errorInternetNotAvailable);
      }

      if (!getBoolAsync(
          IS_APP_CONFIGURATION_SYNCED_AT_LEAST_ONCE)) {
        await setValue(
          IS_APP_CONFIGURATION_SYNCED_AT_LEAST_ONCE,
          true,
        );
      }
    }

    appStore.setLoading(false);

    proceedToNext();
  }

  Future<void> proceedToNext() async {
    appStore.setLanguage(
      getStringAsync(
        SELECTED_LANGUAGE_CODE,
        defaultValue: DEFAULT_LANGUAGE,
      ),
      context: context,
    );

    /// ================= THEME FIX =================

    int themeModeIndex = getIntAsync(
      THEME_MODE_INDEX,
      defaultValue: THEME_MODE_LIGHT,
    );

    print("=========== THEME MODE ===========");
    print(themeModeIndex);

    /// Force Light/Dark properly
    if (themeModeIndex == THEME_MODE_DARK) {
      appStore.setDarkMode(true);

      defaultToastBackgroundColor = Colors.white;
      defaultToastTextColor = Colors.black;
    } else {
      appStore.setDarkMode(false);

      defaultToastBackgroundColor = Colors.black;
      defaultToastTextColor = Colors.white;
    }

    print("=========== IS DARK MODE ===========");
    print(appStore.isDarkMode);

    /// =============================================

    if (appConfigurationStore.maintenanceModeStatus) {
      MaintenanceModeScreen().launch(
        context,
        pageRouteAnimation: PageRouteAnimation.Fade,
      );

      return;
    }

    if (!appConfigurationStore.isUserAuthorized &&
        appStore.isLoggedIn) {
      await clearPreferences();
    }

    if (!appStore.isLoggedIn) {
      SignInScreen().launch(
        context,
        isNewTask: true,
        pageRouteAnimation: PageRouteAnimation.Fade,
      );
    } else {
      await updateProfilePhoto();

      if (isUserTypeProvider) {
        setStatusBarColor(primaryColor);

        ProviderDashboardScreen(index: 0).launch(
          context,
          isNewTask: true,
          pageRouteAnimation: PageRouteAnimation.Fade,
        );
      } else if (isUserTypeHandyman) {
        setStatusBarColor(primaryColor);

        HandymanDashboardScreen(index: 0).launch(
          context,
          isNewTask: true,
          pageRouteAnimation: PageRouteAnimation.Fade,
        );
      } else {
        SignInScreen().launch(
          context,
          isNewTask: true,
        );
      }
    }
  }

  Future<void> updateProfilePhoto() async {
    try {
      var value = await getUserDetail(appStore.userId);

      await appStore.setUserProfile(
        value.data!.profileImage.validate(),
      );
    } catch (e) {
      log("Profile fetch failed: $e");
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            appStore.isDarkMode
                ? splash_background
                : splash_light_background,
            height: context.height(),
            width: context.width(),
            fit: BoxFit.cover,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                appLogo,
                height: 120,
                width: 120,
              ),

              32.height,

              Text(
                APP_NAME,
                style: boldTextStyle(
                  size: 26,
                  color: appStore.isDarkMode
                      ? Colors.white
                      : Colors.black,
                ),
              ),

              16.height,

              Observer(
                builder: (_) {
                  return appStore.isLoading
                      ? LoaderWidget().center()
                      : SizedBox();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}