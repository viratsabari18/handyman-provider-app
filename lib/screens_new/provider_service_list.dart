import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:handyman_provider_flutter/Models_new/providers_services.dart';
import 'package:handyman_provider_flutter/components/app_widgets.dart';
import 'package:handyman_provider_flutter/components/back_widget.dart';
import 'package:handyman_provider_flutter/components/cached_image_widget.dart';
import 'package:handyman_provider_flutter/components/disabled_rating_bar_widget.dart';
import 'package:handyman_provider_flutter/components/price_widget.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/service_model.dart';
import 'package:handyman_provider_flutter/networks/rest_apis.dart';
import 'package:handyman_provider_flutter/provider/services/add_services.dart';
import 'package:handyman_provider_flutter/provider/services/service_detail_screen.dart';
import 'package:handyman_provider_flutter/provider/services/shimmer/service_list_shimmer.dart';
import 'package:handyman_provider_flutter/utils/colors.dart';
import 'package:handyman_provider_flutter/utils/extensions/color_extension.dart';
import 'package:handyman_provider_flutter/utils/extensions/string_extension.dart';
import 'package:handyman_provider_flutter/utils/images.dart';
import 'package:handyman_provider_flutter/utils/model_keys.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../components/empty_error_state_widget.dart';
import '../../utils/configs.dart';
import '../../utils/constant.dart';

class ProviderServiceList extends StatefulWidget {
  const ProviderServiceList({super.key});

  @override
  State<ProviderServiceList> createState() => _ProviderServiceListState();
}

class _ProviderServiceListState extends State<ProviderServiceList> {
  TextEditingController searchController = TextEditingController();

  List<ProviderServiceData> services = [];
  Future<List<ProviderServiceData>>? future;

  int page = 1;
  bool changeListType = false;
  bool isLastPage = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    getServiceListAPI();
  }

  void getServiceListAPI() {
    future = getProviderServiceList(
      page,
      search: searchController.text,
      perPage: 10,
      providerId: appStore.userId,
      services: services,
      lastPageCallback: (b) {
        isLastPage = b;
      },
    );
  }

  void setPageToOne() {
    page = 1;
    appStore.setLoading(true);
    getServiceListAPI();
    setState(() {});
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: appBarWidget(
        languages.lblAllService,
        elevation: 0,
        systemUiOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.light,
        ),
        color: !isDark ? Colors.white : Colors.black,
        textColor: isDark ? Colors.white : Colors.black,
        backWidget: BackWidget(color: Colors.black,),
        textSize: APP_BAR_TEXT_SIZE,
        actions: [
          IconButton(
            onPressed: () {
              changeListType = !changeListType;
              setState(() {});
            },
            icon: Image.asset(changeListType ? list : grid,
                height: 20, width: 20,color: Colors.black,),
          ),
        ],
      ),
      body: Stack(
        children: [
          SnapHelperWidget<List<ProviderServiceData>>(
            future: future,
            errorBuilder: (error) {
              return NoDataWidget(
                title: error,
                imageWidget: const ErrorStateWidget(),
                retryText: 'Reload',
                onRetry: () => setPageToOne(),
              );
            },
            loadingWidget: ServiceListShimmer(
              width:
                  changeListType ? context.width() : context.width() * 0.5 - 24,
            ),
            onSuccess: (list) {
              if (list.isEmpty) {
                return NoDataWidget(
                  title: languages.noDataFound,
                  imageWidget: const EmptyStateWidget(),
                );
              }
              return AnimatedScrollView(
                listAnimationType: ListAnimationType.FadeIn,
                fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                physics: const AlwaysScrollableScrollPhysics(),
                onSwipeRefresh: () async {
                  page = 1;
                  getServiceListAPI();
                  setState(() {});
                  return await 2.seconds.delay;
                },
                onNextPage: () {
                  if (!isLastPage) {
                    page++;
                    appStore.setLoading(true);
                    getServiceListAPI();
                    setState(() {});
                  }
                },
                children: [
                  if (services.isNotEmpty)
                    Container(
                      alignment: Alignment.topLeft,
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, top: 4, bottom: 24),
                      child: AnimatedWrap(
                        spacing: 16.0,
                        runSpacing: 16.0,
                        scaleConfiguration: ScaleConfiguration(
                            duration: 400.milliseconds, delay: 50.milliseconds),
                        listAnimationType: ListAnimationType.FadeIn,
                        fadeInConfiguration:
                            FadeInConfiguration(duration: 2.seconds),
                        alignment: WrapAlignment.start,
                        itemCount: services.length,
                        itemBuilder: (context, index) {
                          return ProviderServiceComponent(
                            data: services[index],
                            width: changeListType
                                ? context.width()
                                : context.width() * 0.5 - 24,
                            changeList: changeListType,
                            onCallBack: () {
                              page = 1;
                              appStore.setLoading(true);
                              getServiceListAPI();
                              setState(() {});
                            },
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
          Observer(
              builder: (context) => LoaderWidget().visible(appStore.isLoading)),
        ],
      ),
    );
  }
}

// Service Component Widget
class ProviderServiceComponent extends StatelessWidget {
  final ProviderServiceData data;
  final double width;
  final bool changeList;
  final VoidCallback? onCallBack;

  const ProviderServiceComponent({
    super.key,
    required this.data,
    required this.width,
    required this.changeList,
    this.onCallBack,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: 400.milliseconds,
      decoration: boxDecorationWithRoundedCorners(
        borderRadius: radius(),
        backgroundColor: appStore.isDarkMode ? cardDarkColor : cardColor,
      ),
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 205,
            width: context.width(),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CachedImageWidget(
                  url: data.attchmentsArray != null &&
                          data.attchmentsArray!.isNotEmpty
                      ? data.attchmentsArray!.first.url.validate()
                      : "",
                  fit: BoxFit.cover,
                  height: 180,
                  width: context.width(),
                ).cornerRadiusWithClipRRectOnly(
                    topRight: defaultRadius.toInt(),
                    topLeft: defaultRadius.toInt()),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 2, vertical: 2),
                        constraints:
                            BoxConstraints(maxWidth: context.width() * 0.3),
                        decoration: boxDecorationWithShadow(
                          backgroundColor:
                              context.cardColor.withValues(alpha: 0.9),
                          borderRadius: radius(24),
                        ),
                        child: Marquee(
                          directionMarguee: DirectionMarguee.oneDirection,
                          child: Text(
                            (data.subcategoryName.validate().isNotEmpty
                                    ? data.subcategoryName.validate()
                                    : data.categoryName.validate())
                                .toUpperCase(),
                            style: boldTextStyle(
                                color:
                                    appStore.isDarkMode ? white : primaryColor,
                                size: 12),
                          ).paddingSymmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                      if (data.serviceRequestStatus != null &&
                          data.serviceRequestStatus !=
                              ServiceRequestKey.approve)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 2, vertical: 2),
                          constraints:
                              BoxConstraints(maxWidth: context.width() * 0.3),
                          decoration: boxDecorationDefault(
                            color: data.serviceRequestStatus
                                .validate()
                                .getServiceApprovalStatusColor,
                            borderRadius: radius(24),
                          ),
                          child: Marquee(
                            directionMarguee: DirectionMarguee.oneDirection,
                            child: Text(
                              data.serviceRequestStatus
                                  .validate()
                                  .toServiceApprovalStatus,
                              style: boldTextStyle(color: white, size: 12),
                            ).paddingSymmetric(horizontal: 8, vertical: 4),
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: boxDecorationWithShadow(
                      backgroundColor: primaryColor,
                      borderRadius: radius(24),
                      border: Border.all(color: context.cardColor, width: 2),
                    ),
                    child: PriceWidget(
                      price: data.price.validate(),
                      isHourlyService:
                          data.type.validate() == SERVICE_TYPE_HOURLY,
                      color: Colors.white,
                      hourlyTextColor: Colors.white,
                      size: 14,
                      isFreeService: data.price == 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              8.height,
              Marquee(
                directionMarguee: DirectionMarguee.oneDirection,
                child: Text(data.name.validate(), style: boldTextStyle())
                    .paddingSymmetric(horizontal: 16),
              ),
              8.height,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  data.description.validate(),
                  style: secondaryTextStyle(size: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              16.height,
            ],
          ),
        ],
      ),
    );
  }
}

// API Helper Function
Future<List<ProviderServiceData>> getProviderServiceList(
  int page, {
  String search = '',
  int perPage = 10,
  int? providerId,
  required List<ProviderServiceData> services,
  required Function(bool) lastPageCallback,
}) async {
  final response = await getProviderServices();
  final newServices = response.data ?? [];

  List<ProviderServiceData> filteredServices = newServices;
  if (search.isNotEmpty) {
    filteredServices = newServices.where((service) {
      return service.name?.toLowerCase().contains(search.toLowerCase()) ??
          false;
    }).toList();
  }

  if (page == 1) {
    services.clear();
    services.addAll(filteredServices);
  } else {
    services.addAll(filteredServices);
  }

  final pagination = response.pagination;
  if (pagination != null) {
    lastPageCallback(pagination.currentPage == pagination.totalPages);
  } else {
    lastPageCallback(filteredServices.length < perPage);
  }

  return services;
}
