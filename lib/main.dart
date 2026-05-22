import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:handyman_provider_flutter/networks/rest_apis.dart';

import 'package:nb_utils/nb_utils.dart';

import 'package:handyman_provider_flutter/app_theme.dart';

import 'package:handyman_provider_flutter/auth/sign_in_screen.dart';

import 'package:handyman_provider_flutter/handyman/handyman_dashboard_screen.dart';

import 'package:handyman_provider_flutter/helpDesk/model/help_desk_response.dart';

import 'package:handyman_provider_flutter/locale/applocalizations.dart';
import 'package:handyman_provider_flutter/locale/base_language.dart';
import 'package:handyman_provider_flutter/locale/language_en.dart';

import 'package:handyman_provider_flutter/models/bank_list_response.dart';
import 'package:handyman_provider_flutter/models/booking_detail_response.dart';
import 'package:handyman_provider_flutter/models/booking_list_response.dart';
import 'package:handyman_provider_flutter/models/booking_status_response.dart';
import 'package:handyman_provider_flutter/models/dashboard_response.dart';
import 'package:handyman_provider_flutter/models/document_list_response.dart';
import 'package:handyman_provider_flutter/models/extra_charges_model.dart';
import 'package:handyman_provider_flutter/models/handyman_dashboard_response.dart';
import 'package:handyman_provider_flutter/models/notification_list_response.dart';
import 'package:handyman_provider_flutter/models/payment_list_reasponse.dart';
import 'package:handyman_provider_flutter/models/revenue_chart_data.dart';
import 'package:handyman_provider_flutter/models/service_detail_response.dart';
import 'package:handyman_provider_flutter/models/service_model.dart';
import 'package:handyman_provider_flutter/models/total_earning_response.dart';
import 'package:handyman_provider_flutter/models/user_data.dart';
import 'package:handyman_provider_flutter/models/wallet_history_list_response.dart';

import 'package:handyman_provider_flutter/networks/firebase_services/auth_services.dart';
import 'package:handyman_provider_flutter/networks/firebase_services/chat_messages_service.dart';
import 'package:handyman_provider_flutter/networks/firebase_services/notification_service.dart';
import 'package:handyman_provider_flutter/networks/firebase_services/user_services.dart';

import 'package:handyman_provider_flutter/provider/jobRequest/models/post_job_detail_response.dart';

import 'package:handyman_provider_flutter/provider/promotional_banner/model/promotional_banner_response.dart';

import 'package:handyman_provider_flutter/provider/provider_dashboard_screen.dart';

import 'package:handyman_provider_flutter/provider/timeSlots/timeSlotStore/time_slot_store.dart';

import 'package:handyman_provider_flutter/services/in_app_purchase.dart';

import 'package:handyman_provider_flutter/store/AppStore.dart';
import 'package:handyman_provider_flutter/store/app_configuration_store.dart';
import 'package:handyman_provider_flutter/store/filter_store.dart';
import 'package:handyman_provider_flutter/store/roles_and_permission_store.dart';

import 'package:handyman_provider_flutter/utils/common.dart';
import 'package:handyman_provider_flutter/utils/configs.dart';
import 'package:handyman_provider_flutter/utils/constant.dart';
import 'package:handyman_provider_flutter/utils/firebase_messaging_utils.dart';

/// ================= BACKGROUND FIREBASE =================

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp();

  log('Background Message : ${message.data}');
}

/// =======================================================

/// ======================= STORES ========================

AppStore appStore = AppStore();

TimeSlotStore timeSlotStore = TimeSlotStore();

AppConfigurationStore appConfigurationStore =
    AppConfigurationStore();

FilterStore filterStore = FilterStore();

RolesAndPermissionStore rolesAndPermissionStore =
    RolesAndPermissionStore();

/// =======================================================

/// ================= FIREBASE SERVICES ===================

UserService userService = UserService();

AuthService authService = AuthService();

ChatServices chatServices = ChatServices();

NotificationService notificationService =
    NotificationService();

/// =======================================================

/// ================== IN APP PURCHASE ====================

InAppPurchaseService inAppPurchaseService =
    InAppPurchaseService();

/// =======================================================

/// ================= GLOBAL VARIABLES ====================

Languages languages = LanguageEn();

List<RevenueChartData> chartData = [];

List<ExtraChargesModel> chargesList = [];

/// =======================================================

/// ================= CACHE VARIABLES =====================

DashboardResponse? cachedProviderDashboardResponse;

HandymanDashBoardResponse?
    cachedHandymanDashboardResponse;

List<BookingData>? cachedBookingList;

List<PaymentData>? cachedPaymentList;

List<NotificationData>? cachedNotifications;

List<BookingStatusResponse>?
    cachedBookingStatusDropdown;

List<(int serviceId, ServiceDetailResponse)?>
    listOfCachedData = [];

List<BookingDetailResponse>
    cachedBookingDetailList = [];

List<(int postJobId, PostJobDetailResponse)?>
    cachedPostJobList = [];

List<UserData>? cachedHandymanList;

List<TotalData>? cachedTotalDataList;

List<WalletHistory>? cachedWalletList;

List<BankHistory>? cachedBankList;

List<HelpDeskListData>? cachedHelpDeskListData;

List<PromotionalBannerListData>?
    cachedPromotionalBannerListData;

List<ServiceData>? cachedServiceData;

List<UserData>? cachedUserData;

DocumentListResponse? cachedDocumentListResponse;

/// =======================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// ================= INITIALIZE =================

  await initialize();

  /// =================================================

  /// ================= FIREBASE INIT =================

  if (!isDesktop) {
    try {
      await Firebase.initializeApp();

      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      );

      if (kReleaseMode) {
        FlutterError.onError =
            FirebaseCrashlytics.instance
                .recordFlutterFatalError;
      }

      subscribeToFirebaseTopic();

      log("Firebase Initialized");
    } catch (e) {
      log("Firebase Init Error : $e");
    }
  }

  /// =================================================

  HttpOverrides.global = MyHttpOverrides();

  defaultSettings();

  localeLanguageList = languageList();

  /// ================= LANGUAGE =================

  appStore.setLanguage(
    getStringAsync(
      SELECTED_LANGUAGE_CODE,
      defaultValue: DEFAULT_LANGUAGE,
    ),
  );

  /// =================================================

  /// ================= THEME =================

  int themeModeIndex = getIntAsync(
    THEME_MODE_INDEX,
    defaultValue: THEME_MODE_LIGHT,
  );

  if (themeModeIndex == THEME_MODE_DARK) {
    appStore.setDarkMode(true);

    defaultToastBackgroundColor = Colors.white;

    defaultToastTextColor = Colors.black;
  } else {
    appStore.setDarkMode(false);

    defaultToastBackgroundColor = Colors.black;

    defaultToastTextColor = Colors.white;
  }

  /// =================================================

  /// ================= APP CONFIG =================

  try {
    await getAppConfigurations();

    if (!appConfigurationStore.isUserAuthorized &&
        appStore.isLoggedIn) {
      await clearPreferences();
    }

    if (appStore.isLoggedIn) {
      try {
        await authService.verifyFirebaseUser();

        log("Firebase User Verified");
      } catch (e) {
        log("Firebase Verify Error : $e");
      }
    }
  } catch (e) {
    log("Startup Config Error : $e");
  }

  /// =================================================

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RestartAppWidget(
      child: Observer(
        builder: (_) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,

            navigatorKey: navigatorKey,

            home: AppStartupScreen(),

            theme: AppTheme.lightTheme,

            darkTheme: AppTheme.darkTheme,

            themeMode: appStore.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,

            supportedLocales:
                LanguageDataModel.languageLocales(),

            localizationsDelegates: [
              AppLocalizations(),

              GlobalMaterialLocalizations.delegate,

              GlobalWidgetsLocalizations.delegate,

              GlobalCupertinoLocalizations.delegate,
            ],

            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler:
                      TextScaler.linear(1.0),
                ),
                child: child!,
              );
            },

            localeResolutionCallback:
                (locale, supportedLocales) =>
                    locale,

            locale: Locale(
              appStore.selectedLanguageCode,
            ),
          );
        },
      ),
    );
  }
}

/// ================= STARTUP SCREEN =================

class AppStartupScreen extends StatefulWidget {
  @override
  State<AppStartupScreen> createState() =>
      _AppStartupScreenState();
}

class _AppStartupScreenState
    extends State<AppStartupScreen> {

  @override
  void initState() {
    super.initState();

    init();
  }

  Future<void> init() async {

    /// wait for shared prefs restore
    await Future.delayed(
      Duration(milliseconds: 500),
    );

    if (!mounted) return;

    if (appStore.isLoggedIn) {

      String token =
          getStringAsync(TOKEN);

      log("RESTORED TOKEN = $token");

      /// token missing
      if (token.isEmpty) {

        await clearPreferences();

        if (!mounted) return;

        SignInScreen().launch(
          context,
          isNewTask: true,
        );

        return;
      }

      /// provider
      if (isUserTypeProvider) {

        ProviderDashboardScreen(
          index: 0,
        ).launch(
          context,
          isNewTask: true,
        );

      }

      /// handyman
      else if (isUserTypeHandyman) {

        HandymanDashboardScreen(
          index: 0,
        ).launch(
          context,
          isNewTask: true,
        );

      }

      /// invalid user
      else {

        await clearPreferences();

        if (!mounted) return;

        SignInScreen().launch(
          context,
          isNewTask: true,
        );
      }

    } else {

      SignInScreen().launch(
        context,
        isNewTask: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,

      body: Center(
        child: CircularProgressIndicator(color:Colors.red),
      ),
    );
  }
}

/// =======================================================

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(
    SecurityContext? context,
  ) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (
            X509Certificate cert,
            String host,
            int port,
          ) {
            return true;
          };
  }
}