import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:handyman_provider_flutter/components/app_widgets.dart';
import 'package:handyman_provider_flutter/components/back_widget.dart';
import 'package:handyman_provider_flutter/components/cached_image_widget.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/selectZoneModel.dart';
import 'package:handyman_provider_flutter/models/user_data.dart';
import 'package:handyman_provider_flutter/networks/rest_apis.dart';
import 'package:handyman_provider_flutter/screens%20new/handyman_upload_screen.dart';
import 'package:handyman_provider_flutter/utils/common.dart';
import 'package:handyman_provider_flutter/utils/configs.dart';
import 'package:handyman_provider_flutter/utils/constant.dart';
import 'package:handyman_provider_flutter/utils/extensions/num_extenstions.dart';
import 'package:handyman_provider_flutter/utils/extensions/string_extension.dart';
import 'package:handyman_provider_flutter/utils/images.dart';
import 'package:handyman_provider_flutter/utils/model_keys.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:handyman_provider_flutter/Models new/registration_data.dart';
import 'package:handyman_provider_flutter/controllers/registration_data_controller.dart';

import '../provider/earning/handyman_payout_list_screen.dart';

class HandymanAddUpdateScreen extends StatefulWidget {
  final String? userType;
  final UserData? data;
  final Function? onUpdate;

  HandymanAddUpdateScreen({this.userType, this.data, this.onUpdate});

  @override
  HandymanAddUpdateScreenState createState() => HandymanAddUpdateScreenState();
}

class HandymanAddUpdateScreenState extends State<HandymanAddUpdateScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController fNameCont = TextEditingController();
  TextEditingController lNameCont = TextEditingController();
  TextEditingController emailCont = TextEditingController();
  TextEditingController userNameCont = TextEditingController();
  TextEditingController mobileCont = TextEditingController();
  TextEditingController passwordCont = TextEditingController();
  TextEditingController cPasswordCont = TextEditingController();
  TextEditingController designationCont = TextEditingController();

  FocusNode fNameFocus = FocusNode();
  FocusNode lNameFocus = FocusNode();
  FocusNode emailFocus = FocusNode();
  FocusNode userNameFocus = FocusNode();
  FocusNode mobileFocus = FocusNode();
  FocusNode passwordFocus = FocusNode();
  FocusNode cPasswordFocus = FocusNode();
  FocusNode designationFocus = FocusNode();

  ValueNotifier _valueNotifier = ValueNotifier(true);

  Country selectedCountry = defaultCountry();

  List<ZoneResponse> providerZoneList = [];
  ZoneResponse? selectedServiceZone;

  // New commission variables
  RegistrationData? registrationData;
  List<HandymanType> uniqueHandymanCommissions = [];
  HandymanType? selectedHandymanCommission;

  int? serviceZoneId;

  bool isUpdate = false;
  
  // Add this variable to track if form has been attempted
  bool _formAttempted = false;

  @override
  void initState() {
    super.initState();

    if (widget.data != null) {
      isUpdate = true;
      fNameCont.text = widget.data!.firstName.validate();
      lNameCont.text = widget.data!.lastName.validate();
      emailCont.text = widget.data!.email.validate();
      userNameCont.text = widget.data!.username.validate();
      mobileCont.text = widget.data!.contactNumber?.split("-").last.validate() ?? "";
      serviceZoneId = widget.data!.handymanZoneID.validate();
      designationCont.text = widget.data!.designation.validate();
      selectedCountry = Country(
        phoneCode: widget.data!.contactNumber?.split("-").first.validate() ?? "",
        countryCode: "",
        e164Sc: 0,
        geographic: true,
        level: 0,
        name: "",
        example: "",
        displayName: "",
        displayNameNoCountryCode: "",
        e164Key: "",
      );
    }

    init();
    afterBuildCreated(() {
      appStore.setLoading(true);
    });
  }

  Future<void> init() async {
    await Future.wait([
      getAddressList(),
      fetchRegistrationData(),
    ]);
  }

  Future<void> fetchRegistrationData() async {
    appStore.setLoading(true);
    try {
      final data = await RegistrationDataController.getRegistrationFields();
      setState(() {
        registrationData = data;
        uniqueHandymanCommissions = _getUniqueHandymanCommissions(data.handymanTypes ?? []);
        
        // Set selected commission if this is an update
        if (widget.data != null && widget.data!.handymanCommissionId != null) {
          selectedHandymanCommission = uniqueHandymanCommissions.firstWhere(
            (commission) => commission.id == widget.data!.handymanCommissionId,
          );
        }
      });
    } catch (e) {
      toast('Failed to load commission data: $e');
      log(e.toString());
    } finally {
      appStore.setLoading(false);
    }
  }

  // Method to remove duplicate handyman commissions based on commission percentage
  List<HandymanType> _getUniqueHandymanCommissions(List<HandymanType> commissions) {
    final seenCommissions = <int>{};
    return commissions.where((commission) {
      if (commission.commission == null) return false;
      if (seenCommissions.contains(commission.commission)) {
        return false;
      } else {
        seenCommissions.add(commission.commission!);
        return true;
      }
    }).toList();
  }

  Future<void> getAddressList() async {
    appStore.setLoading(true);
    await getZoneWithPagination(providerId: appStore.userId, zoneList: providerZoneList, isRequiredAllZones: true).then((value) {
      appStore.setLoading(false);

      providerZoneList.forEach((e) {
        if (e.id == serviceZoneId) {
          selectedServiceZone = e;
        }
      });
      setState(() {});
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    });
  }

  // Build mobile number with phone code and number
  String buildMobileNumber() {
    return '${selectedCountry.phoneCode}-${mobileCont.text.trim()}';
  }

  /// Validate and proceed to document upload
  void proceedToDocumentUpload() {
    // Mark that user attempted to submit
    setState(() {
      _formAttempted = true;
    });
    
    if (formKey.currentState!.validate()) {
      if (selectedHandymanCommission == null) {
        toast(languages.pleaseSelectCommission);
        return;
      }
      
      if (selectedServiceZone == null && providerZoneList.isNotEmpty) {
        toast(languages.selectServiceZone);
        return;
      }
      
      formKey.currentState!.save();
      hideKeyboard(context);
      
      // Prepare request data for the upload screen
      Map<String, dynamic> request = {
        'first_name': fNameCont.text,
        'last_name': lNameCont.text,
        'username': userNameCont.text,
        'email': emailCont.text,
        'mobile': buildMobileNumber(),
        'user_type': widget.userType ?? USER_TYPE_HANDYMAN,
        'designation': designationCont.text.validate(),
        'handyman_zone_id': serviceZoneId.validate(),
        'handyman_type_id': selectedHandymanCommission?.id,
        'commission': selectedHandymanCommission?.commission,
        'commission_type': selectedHandymanCommission?.type,
        'provider_id': appStore.userId, // Current provider's ID
      };
      
      // Add password for new handyman
      if (!isUpdate) {
        request['password'] = passwordCont.text;
      }
      
      // If updating, add the handyman ID
      if (isUpdate) {
        request['id'] = widget.data!.id;
        request['is_update'] = true;
      }
      
      // Navigate to upload documents screen
      HandymanUploadDocumentsScreen(
        formRequest: request,
        isUpdate: isUpdate,
        handymanData: widget.data,
        onUpdate: widget.onUpdate,
      ).launch(context, pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
    }
  }

  /// Direct save for update (without documents)
  Future<void> directUpdate() async {
    // Mark that user attempted to submit
    setState(() {
      _formAttempted = true;
    });
    
    if (formKey.currentState!.validate()) {
      if (selectedHandymanCommission == null) {
        toast(languages.pleaseSelectCommission);
        return;
      }
      
      formKey.currentState!.save();
      hideKeyboard(context);
      
      var request = {
        CommonKeys.id: widget.data!.id,
        UserKeys.firstName: fNameCont.text,
        UserKeys.lastName: lNameCont.text,
        UserKeys.userName: userNameCont.text,
        UserKeys.userType: widget.userType,
        UserKeys.providerId: appStore.userId,
        UserKeys.status: USER_STATUS_CODE,
        UserKeys.contactNumber: buildMobileNumber(),
        UserKeys.designation: designationCont.text.validate(),
        if (serviceZoneId != null && serviceZoneId != -1) UserKeys.handyman_zone_id: serviceZoneId.validate(),
        UserKeys.email: emailCont.text,
        UserKeys.handymanTypeId: selectedHandymanCommission?.id,
      };
      
      appStore.setLoading(true);
      await updateProfile(request).then((res) async {
        toast("Handyman updated successfully");
        finish(context, widget.onUpdate!.call());
      }).catchError((e) {
        toast(e.toString());
      });
      appStore.setLoading(false);
    }
  }

  /// Remove the Handyman
  Future<void> removeHandyman(int? id) async {
    appStore.setLoading(true);
    await deleteHandyman(id.validate()).then((value) {
      appStore.setLoading(false);
      finish(context, widget.onUpdate!.call());
      toast(languages.lblTrashHandyman, print: true);
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    });
  }

  /// Restore the Handyman
  Future<void> restoreHandymanData() async {
    appStore.setLoading(true);
    var req = {
      CommonKeys.id: widget.data!.id,
      'type': RESTORE,
    };

    await restoreHandyman(req).then((value) {
      appStore.setLoading(false);
      toast(value.message);
      finish(context, widget.onUpdate!.call());
      setState(() {});
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    });
  }

  /// ForceFully Delete the Handyman
  Future<void> forceDeleteHandymanData() async {
    appStore.setLoading(true);
    var req = {
      CommonKeys.id: widget.data!.id,
      'type': FORCE_DELETE,
    };

    await restoreHandyman(req).then((value) {
      appStore.setLoading(false);
      toast(value.message);
      finish(context, widget.onUpdate!.call());
      setState(() {});
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Scaffold(
        backgroundColor: context.cardColor,
        appBar: appBarWidget(
          isUpdate ? languages.lblUpdate : languages.lblAddHandyman,
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
                if (widget.data != null) {
                  HandymanPayoutListScreen(user: widget.data!).launch(context);
                }
              },
              icon: Icon(Icons.payments_outlined, size: 24, color: white),
              tooltip: languages.handymanPayoutList,
            ).visible(isUpdate),
            if (isUpdate && rolesAndPermissionStore.handymanDelete)
              PopupMenuButton(
                icon: Icon(Icons.more_vert, size: 24, color: white),
                onSelected: (selection) async {
                  if (selection == 1) {
                    showConfirmDialogCustom(
                      context,
                      dialogType: DialogType.DELETE,
                      title: languages.lblDoYouWantToDelete,
                      positiveText: languages.lblDelete,
                      negativeText: languages.lblCancel,
                      onAccept: (_) {
                        ifNotTester(context, () {
                          removeHandyman(widget.data!.id.validate());
                        });
                      },
                    );
                  } else if (selection == 2) {
                    showConfirmDialogCustom(
                      context,
                      dialogType: DialogType.DELETE,
                      title: languages.lblDoYouWantToRestore,
                      positiveText: languages.lblRestore,
                      negativeText: languages.lblCancel,
                      onAccept: (_) {
                        ifNotTester(context, () {
                          restoreHandymanData();
                        });
                      },
                    );
                  } else if (selection == 3) {
                    showConfirmDialogCustom(
                      context,
                      dialogType: DialogType.DELETE,
                      title: languages.lblDoYouWantToDeleteForcefully,
                      positiveText: languages.lblDelete,
                      negativeText: languages.lblCancel,
                      onAccept: (_) {
                        ifNotTester(context, () {
                          forceDeleteHandymanData();
                        });
                      },
                    );
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Text(languages.lblDelete),
                    value: 1,
                    enabled: widget.data!.deletedAt == null,
                    textStyle: boldTextStyle(color: widget.data!.deletedAt == null ? textPrimaryColorGlobal : null),
                  ),
                  PopupMenuItem(
                    child: Text(languages.lblRestore),
                    value: 2,
                    textStyle: boldTextStyle(color: widget.data!.deletedAt != null ? textPrimaryColorGlobal : null),
                    enabled: widget.data!.deletedAt != null,
                  ),
                  PopupMenuItem(
                    child: Text(languages.lblForceDelete),
                    textStyle: boldTextStyle(),
                    value: 3,
                    enabled: widget.data!.deletedAt != null,
                  ),
                ],
              ),
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: formKey,
                // Update this line to only validate after form has been attempted
                autovalidateMode: _formAttempted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isUpdate)
                      CachedImageWidget(
                        url: widget.data!.profileImage.validate(value: profile),
                        height: 100,
                        circle: true,
                        fit: BoxFit.cover,
                      ).center(),
                    30.height,
                    AppTextField(
                      textFieldType: TextFieldType.NAME,
                      controller: fNameCont,
                      focus: fNameFocus,
                      enabled: isUpdate ? rolesAndPermissionStore.handymanEdit : true,
                      nextFocus: lNameFocus,
                      decoration: inputDecoration(
                        context,
                        hint: languages.hintFirstNameTxt,
                        fillColor: context.scaffoldBackgroundColor,
                      ),
                      suffix: profile.iconImage(size: 10).paddingAll(14),
                    ),
                    16.height,
                    AppTextField(
                      textFieldType: TextFieldType.NAME,
                      controller: lNameCont,
                      focus: lNameFocus,
                      enabled: isUpdate ? rolesAndPermissionStore.handymanEdit : true,
                      nextFocus: userNameFocus,
                      decoration: inputDecoration(
                        context,
                        hint: languages.hintLastNameTxt,
                        fillColor: context.scaffoldBackgroundColor,
                      ),
                      suffix: profile.iconImage(size: 10).paddingAll(14),
                    ),
                    16.height,
                    AppTextField(
                      textFieldType: TextFieldType.USERNAME,
                      controller: userNameCont,
                      focus: userNameFocus,
                      nextFocus: emailFocus,
                      enabled: isUpdate ? rolesAndPermissionStore.handymanEdit : true,
                      decoration: inputDecoration(
                        context,
                        hint: languages.hintUserNameTxt,
                        fillColor: context.scaffoldBackgroundColor,
                      ),
                      suffix: profile.iconImage(size: 10).paddingAll(14),
                    ),
                    16.height,
                    AppTextField(
                      textFieldType: TextFieldType.EMAIL_ENHANCED,
                      controller: emailCont,
                      focus: emailFocus,
                      nextFocus: mobileFocus,
                      enabled: isUpdate ? rolesAndPermissionStore.handymanEdit : true,
                      decoration: inputDecoration(
                        context,
                        hint: languages.hintEmailAddressTxt,
                        fillColor: context.scaffoldBackgroundColor,
                      ),
                      suffix: ic_message.iconImage(size: 10).paddingAll(14),
                    ),
                    16.height,
                    IgnorePointer(
                      ignoring: isUpdate ? !rolesAndPermissionStore.handymanEdit : false,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            height: 48.0,
                            decoration: BoxDecoration(
                              color: context.scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Center(
                              child: ValueListenableBuilder(
                                valueListenable: _valueNotifier,
                                builder: (context, value, child) => Row(
                                  children: [
                                    Text(
                                      "+${selectedCountry.phoneCode}",
                                      style: primaryTextStyle(size: 12),
                                    ).paddingOnly(left: 8),
                                    Icon(Icons.arrow_drop_down)
                                  ],
                                ),
                              ),
                            ),
                          ).onTap(
                            () => changeCountry(),
                          ).paddingOnly(right: 10.0),
                          Expanded(
                            child: AppTextField(
                              textFieldType: TextFieldType.PHONE,
                              controller: mobileCont,
                              focus: mobileFocus,
                              nextFocus: designationFocus,
                              decoration: inputDecoration(
                                context,
                                hint: languages.hintContactNumberTxt,
                                fillColor: context.scaffoldBackgroundColor,
                              ),
                              suffix: calling.iconImage(size: 10).paddingAll(14),
                              validator: (mobileCont) {
                                if (mobileCont!.isEmpty) return languages.lblPleaseEnterMobileNumber;
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    16.height,
                    AppTextField(
                      textFieldType: TextFieldType.NAME,
                      controller: designationCont,
                      isValidationRequired: false,
                      enabled: isUpdate ? rolesAndPermissionStore.handymanEdit : true,
                      focus: designationFocus,
                      nextFocus: passwordFocus,
                      decoration: inputDecoration(
                        context,
                        hint: languages.lblDesignation,
                        fillColor: context.scaffoldBackgroundColor,
                      ),
                    ),
                    16.height,
                    // Commission Dropdown
                    IgnorePointer(
                      ignoring: isUpdate ? !rolesAndPermissionStore.handymanEdit : false,
                      child: DropdownButtonFormField<HandymanType>(
                        decoration: inputDecoration(
                          context,
                          hint: languages.lblSelectCommission,
                          fillColor: context.scaffoldBackgroundColor,
                        ),
                        isExpanded: true,
                        dropdownColor: context.cardColor,
                        value: selectedHandymanCommission,
                        items: uniqueHandymanCommissions.map((handymanType) {
                          return DropdownMenuItem<HandymanType>(
                            value: handymanType,
                            child: Row(
                              children: [
                                Text(
                                  '${handymanType.commission}% ${handymanType.type}',
                                  style: primaryTextStyle(),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (HandymanType? value) async {
                          selectedHandymanCommission = value;
                          setState(() {});
                        },
                      ),
                    ).visible(uniqueHandymanCommissions.isNotEmpty),
                    16.height,
                    IgnorePointer(
                      ignoring: isUpdate ? !rolesAndPermissionStore.handymanEdit : false,
                      child: DropdownButtonFormField<ZoneResponse>(
                        decoration: inputDecoration(
                          context,
                          hint: languages.selectServiceZone,
                          fillColor: context.scaffoldBackgroundColor,
                        ),
                        isExpanded: true,
                        dropdownColor: context.cardColor,
                        value: selectedServiceZone != null ? selectedServiceZone : null,
                        items: providerZoneList.map((data) {
                          return DropdownMenuItem<ZoneResponse>(
                            value: data,
                            child: Text(
                              data.name.validate(),
                              style: primaryTextStyle(),
                            ),
                          );
                        }).toList(),
                        onChanged: (ZoneResponse? value) async {
                          selectedServiceZone = value;
                          serviceZoneId = selectedServiceZone!.id.validate();
                          setState(() {});
                        },
                      ),
                    ).visible(providerZoneList.isNotEmpty),
                    16.height.visible(!isUpdate),
                    // Password field for new handyman
                    if (!isUpdate)
                      AppTextField(
                        textFieldType: TextFieldType.PASSWORD,
                        controller: passwordCont,
                        focus: passwordFocus,
                        enabled: rolesAndPermissionStore.handymanEdit,
                        obscureText: true,
                        decoration: inputDecoration(
                          context,
                          hint: languages.hintPassword,
                          fillColor: context.scaffoldBackgroundColor,
                        ),
                        isValidationRequired: true,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return languages.hintRequired;
                          } else if (val.length < 8 || val.length > 12) {
                            return languages.passwordLengthShouldBe;
                          }
                          return null;
                        },
                      ),
                    16.height,
                    if (isUpdate)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${widget.data!.displayName} ${languages.lblRegistered} ${DateTime.parse(widget.data!.createdAt!).timeAgo}\n${formatBookingDate(widget.data!.createdAt!)}',
                              style: secondaryTextStyle()),
                          if (widget.data!.emailVerifiedAt.validate().isNotEmpty)
                            TextIcon(
                              text: '${languages.lblEmailIsVerified}',
                              textStyle: primaryTextStyle(color: Colors.green),
                              prefix: Container(
                                child: Icon(Icons.check, color: Colors.white, size: 14),
                                padding: EdgeInsets.all(2),
                                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.green),
                              ),
                            ).paddingTop(8),
                        ],
                      ),
                    24.height,
                    Observer(
                      builder: (context) => AppButton(
                        text: isUpdate ? languages.btnSave : languages.lblNext,
                        height: 40,
                        color: primaryColor,
                        textColor: white,
                        width: context.width() - context.navigationBarHeight,
                        onTap: appStore.isLoading
                            ? null
                            : () {
                                if (isUpdate) {
                                  // For update, directly save
                                  directUpdate();
                                } else {
                                  // For new handyman, go to document upload
                                  proceedToDocumentUpload();
                                }
                              },
                      ),
                    )
                  ],
                ),
              ),
            ),
            Observer(builder: (_) => LoaderWidget().center().visible(appStore.isLoading)),
          ],
        ),
      ),
    );
  }

  // Change country code function...
  Future<void> changeCountry() async {
    showCountryPicker(
      context: context,
      countryListTheme: CountryListThemeData(
        textStyle: secondaryTextStyle(color: textSecondaryColorGlobal),
        searchTextStyle: primaryTextStyle(),
        inputDecoration: InputDecoration(
          labelText: languages.search,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: const Color(0xFF8C98A8).withValues(alpha: 0.2),
            ),
          ),
        ),
      ),
      showPhoneCode: true,
      onSelect: (Country country) {
        selectedCountry = country;
        _valueNotifier.notifyListeners();
      },
    );
  }
}