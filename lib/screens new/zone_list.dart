import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:handyman_provider_flutter/Models%20new/add_provider_zones_requst_and_response.dart';
import 'package:handyman_provider_flutter/Models%20new/delete_provider_zones_request_and_responses.dart';
import 'package:handyman_provider_flutter/Models%20new/registration_data.dart';
import 'package:handyman_provider_flutter/components/app_widgets.dart';
import 'package:handyman_provider_flutter/components/back_widget.dart';
import 'package:handyman_provider_flutter/components/empty_error_state_widget.dart';
import 'package:handyman_provider_flutter/controllers/registration_data_controller.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/utils/constant.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../networks/rest_apis.dart';
import '../../utils/colors.dart';
import '../../utils/configs.dart';
import '../../utils/extensions/string_extension.dart';

class ZoneList extends StatefulWidget {
  const ZoneList({super.key});

  @override
  State<ZoneList> createState() => _ZoneListState();
}

class _ZoneListState extends State<ZoneList> {
  List<Zone> zones = [];

  bool isError = false;
  String errorMessage = '';

  bool showZoneDropdown = false;
  List<Zone> availableZones = [];
  List<int> selectedZoneIds = [];
  String? dropdownError;

  @override
  void initState() {
    super.initState();
    fetchZones();
  }

  Future<void> fetchZones() async {
    setState(() {
      isError = false;
      errorMessage = '';
    });
    appStore.setLoading(true);

    try {
      final response = await getProviderZoneList();

      if (response != null && response.data != null) {
        setState(() {
          zones = response.data!;
        });
      } else {
        setState(() {
          isError = true;
          errorMessage = languages.noZonesFound;
        });
      }
    } catch (e) {
      setState(() {
        isError = true;
        errorMessage = e.toString();
      });
      toast(errorMessage, print: true);
    } finally {
      appStore.setLoading(false);
    }
  }

  Future<void> fetchAvailableZones() async {
    setState(() {
      dropdownError = null;
    });
    appStore.setLoading(true);

    try {
      final response = await RegistrationDataController.getRegistrationFields();

      setState(() {
        if (response.zones != null && response.zones!.isNotEmpty) {
          final existingZoneIds = zones.map((z) => z.id).toSet();
          availableZones = response.zones!
              .where((zone) => !existingZoneIds.contains(zone.id))
              .toList();
        } else {
          availableZones = [];
          dropdownError = languages.noZonesAvailable;
        }
      });
    } catch (e) {
      setState(() {
        availableZones = [];
        dropdownError = '${languages.failedToLoadZones}: $e';
      });
      toast(dropdownError!);
    } finally {
      appStore.setLoading(false);
    }
  }

  Future<void> addProviderZones() async {
    if (selectedZoneIds.isEmpty) {
      toast(languages.pleaseSelectAtLeastOneZone);
      return;
    }

    appStore.setLoading(true);

    try {
      final request = AddProviderZoneRequest(zoneId: selectedZoneIds);

      await addProviderZoneList(request);

      toast(languages.zonesAddedSuccessfully);

      setState(() {
        showZoneDropdown = false;
        selectedZoneIds.clear();
      });

      await fetchZones();
    } catch (e) {
      toast('${languages.error}: ${e.toString()}');
    } finally {
      appStore.setLoading(false);
    }
  }

  Future<void> deleteZone(int id) async {
    appStore.setLoading(true);

    try {
      final req = deleteProviderZoneRequest(zoneId: id);
      await deleteProviderZoneList(req);

      setState(() {
        zones.removeWhere((zone) => zone.id == id);
      });

      toast(languages.zoneDeletedSuccessfully);
      await fetchZones();
    } catch (e) {
      toast('${languages.error}: ${e.toString()}');
    } finally {
      appStore.setLoading(false);
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: appBarWidget(
        languages.zoneListTitle,
        elevation: 0,
        systemUiOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: isDark ? Colors.black : Colors.white,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
        color: !isDark ? Colors.white : Colors.black,
        textColor: isDark ? Colors.white : Colors.black,
        backWidget: BackWidget(color: isDark ? Colors.white : Colors.black),
        textSize: APP_BAR_TEXT_SIZE,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                showZoneDropdown = !showZoneDropdown;
                if (showZoneDropdown) {
                  fetchAvailableZones();
                }
              });
            },
            icon: Icon(Icons.add,
                size: 28, color: isDark ? Colors.white : Colors.black),
            tooltip: languages.addZones,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (isError)
            NoDataWidget(
              title: errorMessage,
              imageWidget: const ErrorStateWidget(),
              retryText: languages.reload,
              onRetry: () {
                fetchZones();
              },
            )
          else if (zones.isEmpty && !appStore.isLoading)
            NoDataWidget(
              title: languages.noZonesFound,
              subTitle: languages.noZonesAvailableForProvider,
              imageWidget: const EmptyStateWidget(),
            )
          else
            Column(
              children: [
                if (showZoneDropdown) _buildAddZoneDropdown(),
                Expanded(
                  child: AnimatedScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    listAnimationType: ListAnimationType.FadeIn,
                    fadeInConfiguration:
                        FadeInConfiguration(duration: 2.seconds),
                    onSwipeRefresh: () async {
                      await fetchZones();
                      return await 2.seconds.delay;
                    },
                    children: [
                      if (zones.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildListView(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          Observer(
            builder: (context) => LoaderWidget().visible(appStore.isLoading),
          ),
        ],
      ),
    );
  }

  Widget _buildAddZoneDropdown() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: boxDecorationWithRoundedCorners(
        borderRadius: radius(12),
        backgroundColor: appStore.isDarkMode ? cardDarkColor : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  languages.addNewZones,
                  style: boldTextStyle(size: 16),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      showZoneDropdown = false;
                      selectedZoneIds.clear();
                      dropdownError = null;
                    });
                  },
                  icon: Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: languages.close,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          if (appStore.isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (dropdownError != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        dropdownError!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (availableZones.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  languages.noZonesAvailableToAdd,
                  style: secondaryTextStyle(size: 14),
                ),
              ),
            )
          else
            Container(
              constraints: BoxConstraints(
                maxHeight: context.height() * 0.5,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: availableZones.length,
                itemBuilder: (context, index) {
                  final zone = availableZones[index];
                  final isSelected = selectedZoneIds.contains(zone.id);

                  return CheckboxListTile(
                    checkboxShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    activeColor: context.primaryColor,
                    title: Text(
                      zone.name.validate(),
                      style: primaryTextStyle(size: 14),
                    ),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedZoneIds.add(zone.id!);
                        } else {
                          selectedZoneIds.remove(zone.id!);
                        }
                      });
                    },
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  );
                },
              ),
            ),

          if (!appStore.isLoading &&
              dropdownError == null &&
              availableZones.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: context.dividerColor),
                ),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                runSpacing: 8,
                children: [
                  Text(
                    '${languages.selected}: ${selectedZoneIds.length}',
                    style: secondaryTextStyle(size: 14),
                  ),
                  Wrap(
                    spacing: 12,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedZoneIds.clear();
                          });
                        },
                        child: Text(languages.clearAll),
                      ),
                      ElevatedButton(
                        onPressed:
                            selectedZoneIds.isEmpty ? null : addProviderZones,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(languages.addZones),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return AnimatedWrap(
      spacing: 16.0,
      runSpacing: 16.0,
      scaleConfiguration: ScaleConfiguration(
          duration: 400.milliseconds, delay: 50.milliseconds),
      listAnimationType: ListAnimationType.FadeIn,
      fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
      alignment: WrapAlignment.start,
      itemCount: zones.length,
      itemBuilder: (context, index) {
        final zone = zones[index];
        return _buildZoneListItem(zone);
      },
    );
  }

  Widget _buildZoneListItem(Zone zone) {
    return AnimatedContainer(
      duration: 400.milliseconds,
      decoration: boxDecorationWithRoundedCorners(
        borderRadius: radius(),
        backgroundColor: appStore.isDarkMode ? cardDarkColor : cardColor,
      ),
      width: context.width(),
      child: Row(
        children: [
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.primaryColor,
                  context.primaryColor.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(defaultRadius),
                bottomLeft: Radius.circular(defaultRadius),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.location_on,
                size: 32,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    zone.name.validate(),
                    style: boldTextStyle(size: 15),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: () {
                showConfirmDialogCustom(
                  context,
                  dialogType: DialogType.DELETE,
                  title: languages.deleteZoneConfirmation,
                  positiveText: languages.delete,
                  negativeText: languages.cancel,
                  onAccept: (v) async {
                    await deleteZone(zone.id ?? 0);
                  },
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}