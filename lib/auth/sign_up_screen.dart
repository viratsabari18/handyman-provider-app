import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:handyman_provider_flutter/Models%20new/registration_data.dart';
import 'package:handyman_provider_flutter/controllers/registration_controller.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/utils/common.dart';
import 'package:handyman_provider_flutter/utils/configs.dart';
import 'package:handyman_provider_flutter/utils/constant.dart';
import 'package:handyman_provider_flutter/utils/extensions/string_extension.dart';
import 'package:handyman_provider_flutter/utils/images.dart';
import 'package:nb_utils/nb_utils.dart';
import '../components/back_widget.dart';
import 'upload_documents_screen.dart';
import 'sign_in_screen.dart';



class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // TextEditing controllers
  TextEditingController fNameCont = TextEditingController();
  TextEditingController lNameCont = TextEditingController();
  TextEditingController emailCont = TextEditingController();
  TextEditingController userNameCont = TextEditingController();
  TextEditingController mobileCont = TextEditingController();
  TextEditingController passwordCont = TextEditingController();
  TextEditingController designationCont = TextEditingController();

  // FocusNodes
  FocusNode fNameFocus = FocusNode();
  FocusNode lNameFocus = FocusNode();
  FocusNode emailFocus = FocusNode();
  FocusNode userNameFocus = FocusNode();
  FocusNode mobileFocus = FocusNode();
  FocusNode userTypeFocus = FocusNode();
  FocusNode designationFocus = FocusNode();
  FocusNode passwordFocus = FocusNode();

  String? selectedUserTypeValue;
  
  // For Provider
  ProviderType? selectedProviderCommission;
  
  // For Handyman
  Provider? selectedProvider;
  HandymanType? selectedHandymanCommission;
  
  bool isLoading = false;

  // API Data
  RegistrationData? registrationData;
  
  // Unique lists for commissions
  List<ProviderType> uniqueProviderCommissions = [];
  List<HandymanType> uniqueHandymanCommissions = [];

  @override
  void initState() {
    super.initState();
    fetchRegistrationData();
  }

  Future<void> fetchRegistrationData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final data = await RegistrationController.getRegistrationFields();
      setState(() {
        registrationData = data;
        // Remove duplicates from provider commissions based on commission value
        uniqueProviderCommissions = _getUniqueProviderCommissions(data.providerTypes ?? []);
        // Remove duplicates from handyman commissions based on commission value
        uniqueHandymanCommissions = _getUniqueHandymanCommissions(data.handymanTypes ?? []);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      toast('Failed to load registration data: $e');
      print('Error fetching registration data: $e');
    }
  }

  // Method to remove duplicate provider commissions based on commission percentage
  List<ProviderType> _getUniqueProviderCommissions(List<ProviderType> commissions) {
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

  void _logUserEnteredValues() {
    print('================== USER REGISTRATION DETAILS ==================');
    print('First Name: ${fNameCont.text.trim()}');
    print('Last Name: ${lNameCont.text.trim()}');
    print('Username: ${userNameCont.text.trim()}');
    print('Email: ${emailCont.text.trim()}');
    print('Mobile: ${mobileCont.text.trim()}');
    print('Password: ${'*' * passwordCont.text.length}');
    print('User Type: ${selectedUserTypeValue == USER_TYPE_PROVIDER ? "Provider" : "Handyman"}');
    print('Designation: ${designationCont.text.trim()}');
    
    if (selectedUserTypeValue == USER_TYPE_PROVIDER && selectedProviderCommission != null) {
      print('Provider Commission: ${selectedProviderCommission!.commission}% (${selectedProviderCommission!.type})');
    } else if (selectedUserTypeValue == USER_TYPE_HANDYMAN) {
      print('Selected Provider: ${selectedProvider?.name}');
      if (selectedHandymanCommission != null) {
        print('Handyman Commission: ${selectedHandymanCommission!.commission}% (${selectedHandymanCommission!.type})');
      }
    }
    print('===============================================================');
  }

  @override
  void dispose() {
    fNameCont.dispose();
    lNameCont.dispose();
    emailCont.dispose();
    userNameCont.dispose();
    mobileCont.dispose();
    passwordCont.dispose();
    designationCont.dispose();
    fNameFocus.dispose();
    lNameFocus.dispose();
    emailFocus.dispose();
    userNameFocus.dispose();
    mobileFocus.dispose();
    userTypeFocus.dispose();
    designationFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: Container(
            margin: EdgeInsets.only(left: 6),
            padding: EdgeInsets.only(left: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: BackWidget(color: context.iconColor),
          ),
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarIconBrightness: appStore.isDarkMode ? Brightness.light : Brightness.dark,
            statusBarColor: context.scaffoldBackgroundColor,
          ),
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : Form(
                key: formKey,
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTopWidget(),
                      _buildFormWidget(),
                      _buildFooterWidget(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTopWidget() {
    return Column(
      children: [
        (context.height() * 0.08).toInt().height,
        Container(
          width: 85,
          height: 85,
          decoration: boxDecorationWithRoundedCorners(
              boxShape: BoxShape.circle, backgroundColor: primaryColor),
          child: Image.asset(profile, height: 45, width: 45, color: white),
        ),
        16.height,
        Text(languages.lblSignupTitle, style: boldTextStyle(size: 18)),
        16.height,
        Text(
          languages.lblSignupSubtitle,
          style: secondaryTextStyle(size: 14),
          textAlign: TextAlign.center,
        ).paddingSymmetric(horizontal: 32),
        24.height,
      ],
    );
  }

  Widget _buildFormWidget() {
    return Column(
      children: [
        // First name
        AppTextField(
          textFieldType: TextFieldType.NAME,
          controller: fNameCont,
          focus: fNameFocus,
          nextFocus: lNameFocus,
          errorThisFieldRequired: languages.hintRequired,
          decoration: inputDecoration(context, hint: languages.hintFirstNameTxt),
          suffix: profile.iconImage(size: 10).paddingAll(14),
        ),
        16.height,

        // Last name
        AppTextField(
          textFieldType: TextFieldType.NAME,
          controller: lNameCont,
          focus: lNameFocus,
          nextFocus: userNameFocus,
          errorThisFieldRequired: languages.hintRequired,
          decoration: inputDecoration(context, hint: languages.hintLastNameTxt),
          suffix: profile.iconImage(size: 10).paddingAll(14),
        ),
        16.height,

        // Username
        AppTextField(
          textFieldType: TextFieldType.USERNAME,
          controller: userNameCont,
          focus: userNameFocus,
          nextFocus: emailFocus,
          errorThisFieldRequired: languages.hintRequired,
          decoration: inputDecoration(context, hint: languages.hintUserNameTxt),
          suffix: profile.iconImage(size: 10).paddingAll(14),
        ),
        16.height,

        // Email
        AppTextField(
          textFieldType: TextFieldType.EMAIL_ENHANCED,
          controller: emailCont,
          focus: emailFocus,
          nextFocus: mobileFocus,
          errorThisFieldRequired: languages.hintRequired,
          decoration: inputDecoration(context, hint: languages.hintEmailAddressTxt),
          suffix: ic_message.iconImage(size: 10).paddingAll(14),
        ),
        16.height,

        // Mobile number
        AppTextField(
          textFieldType: isAndroid ? TextFieldType.PHONE : TextFieldType.NAME,
          controller: mobileCont,
          focus: mobileFocus,
          errorThisFieldRequired: languages.hintRequired,
          nextFocus: designationFocus,
          decoration: inputDecoration(context, hint: languages.hintContactNumberTxt),
          maxLength: 15,
          suffix: calling.iconImage(size: 10).paddingAll(14),
        ),
        16.height,

        // Designation
        AppTextField(
          textFieldType: TextFieldType.USERNAME,
          controller: designationCont,
          isValidationRequired: false,
          focus: designationFocus,
          nextFocus: userTypeFocus,
          decoration: inputDecoration(context, hint: languages.lblDesignation),
          suffix: profile.iconImage(size: 10).paddingAll(14),
        ),
        16.height,

        // User Role Dropdown
        DropdownButtonFormField<String>(
          items: [
            DropdownMenuItem(
              child: Text(languages.provider, style: primaryTextStyle()),
              value: USER_TYPE_PROVIDER,
            ),
            DropdownMenuItem(
              child: Text(languages.handyman, style: primaryTextStyle()),
              value: USER_TYPE_HANDYMAN,
            ),
          ],
          focusNode: userTypeFocus,
          dropdownColor: context.cardColor,
          decoration: inputDecoration(context, hint: languages.userRole),
          value: selectedUserTypeValue,
          validator: (value) {
            if (value == null) return languages.hintRequired;
            return null;
          },
          onChanged: (c) {
            hideKeyboard(context);
            setState(() {
              selectedUserTypeValue = c.validate();
              selectedProviderCommission = null;
              selectedProvider = null;
              selectedHandymanCommission = null;
            });
          },
        ),

        // For Provider: Single Commission Dropdown (with duplicates removed)
        if (selectedUserTypeValue == USER_TYPE_PROVIDER && registrationData != null)
          Column(
            children: [
              16.height,
              DropdownButtonFormField<ProviderType>(
                items: uniqueProviderCommissions.map((providerType) {
                  return DropdownMenuItem<ProviderType>(
                    child: Text(
                      '${providerType.commission}% ${providerType.type}',
                      style: primaryTextStyle(),
                    ),
                    value: providerType,
                  );
                }).toList(),
                dropdownColor: context.cardColor,
                decoration: inputDecoration(context, hint: 'Select Commission'),
                value: selectedProviderCommission,
                validator: (value) {
                  if (value == null) return 'Please select commission';
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    selectedProviderCommission = value;
                  });
                },
              ),
            ],
          ),

        // For Handyman: Two Dropdowns (Provider Name + Handyman Commission with duplicates removed)
        if (selectedUserTypeValue == USER_TYPE_HANDYMAN && registrationData != null)
          Column(
            children: [
              16.height,
              // First Dropdown: Provider Name
              DropdownButtonFormField<Provider>(
                items: registrationData?.providers?.map((provider) {
                  return DropdownMenuItem<Provider>(
                    child: Text(
                      provider.name ?? '',
                      style: primaryTextStyle(),
                    ),
                    value: provider,
                  );
                }).toList(),
                dropdownColor: context.cardColor,
                decoration: inputDecoration(context, hint: 'Select Provider'),
                value: selectedProvider,
                validator: (value) {
                  if (value == null) return 'Please select provider';
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    selectedProvider = value;
                    // Reset handyman commission when provider changes
                    selectedHandymanCommission = null;
                  });
                },
              ),
              
              16.height,
              
              // Second Dropdown: Handyman Commission (with duplicates removed)
              DropdownButtonFormField<HandymanType>(
                items: uniqueHandymanCommissions.map((handymanType) {
                  return DropdownMenuItem<HandymanType>(
                    child: Text(
                      '${handymanType.commission}% ${handymanType.type}',
                      style: primaryTextStyle(),
                    ),
                    value: handymanType,
                  );
                }).toList(),
                dropdownColor: context.cardColor,
                decoration: inputDecoration(context, hint: 'Select Commission'),
                value: selectedHandymanCommission,
                validator: (value) {
                  if (value == null) return 'Please select commission';
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    selectedHandymanCommission = value;
                  });
                },
              ),
            ],
          ),

        24.height,

        // Password Field (Moved to end)
        AppTextField(
          textFieldType: TextFieldType.PASSWORD,
          controller: passwordCont,
          focus: passwordFocus,
          obscureText: true,
          suffixPasswordVisibleWidget: ic_show.iconImage(size: 10).paddingAll(14),
          suffixPasswordInvisibleWidget: ic_hide.iconImage(size: 10).paddingAll(14),
          errorThisFieldRequired: languages.hintRequired,
          decoration: inputDecoration(context, hint: languages.hintPassword),
          validator: (val) {
            if (val == null || val.isEmpty) {
              return languages.hintRequired;
            } else if (val.length < 8) {
              return languages.passwordLengthShouldBe;
            }
            return null;
          },
        ),

        20.height,

        // Next Button
        AppButton(
          text: languages.lblNext,
          height: 40,
          color: primaryColor,
          textStyle: boldTextStyle(color: white),
          width: context.width() - context.navigationBarHeight,
          onTap: () async {
            if (formKey.currentState!.validate()) {
              if (selectedUserTypeValue == null) {
                toast(languages.userRole);
                return;
              }

              // Validate Provider-specific fields
              if (selectedUserTypeValue == USER_TYPE_PROVIDER) {
                if (selectedProviderCommission == null) {
                  toast('Please select commission');
                  return;
                }
              }

              // Validate Handyman-specific fields
              if (selectedUserTypeValue == USER_TYPE_HANDYMAN) {
                if (selectedProvider == null) {
                  toast('Please select provider');
                  return;
                }
                if (selectedHandymanCommission == null) {
                  toast('Please select commission');
                  return;
                }
              }

              // Log all user entered values
              _logUserEnteredValues();

              // Prepare request map
              Map<String, dynamic> request = {
                'first_name': fNameCont.text.trim(),
                'last_name': lNameCont.text.trim(),
                'username': userNameCont.text.trim(),
                'email': emailCont.text.trim(),
                'mobile': mobileCont.text.trim(),
                'password': passwordCont.text.trim(),
                'user_type': selectedUserTypeValue,
                'designation': designationCont.text.trim(),
              };

              if (selectedUserTypeValue == USER_TYPE_PROVIDER) {
                request['commission'] = selectedProviderCommission?.commission;
                request['commission_type'] = selectedProviderCommission?.type;
                request['provider_type_id'] = selectedProviderCommission?.id;
                
                UploadDocumentsScreen(formRequest: request).launch(context,
                    pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
              } else {
                // Handyman data
                request['provider_id'] = selectedProvider?.id;
                request['provider_name'] = selectedProvider?.name;
                request['commission'] = selectedHandymanCommission?.commission;
                request['commission_type'] = selectedHandymanCommission?.type;
                request['handyman_type_id'] = selectedHandymanCommission?.id;
                
                toast("Registration successful! Please sign in.");
                push(SignInScreen(),
                    isNewTask: true,
                    pageRouteAnimation: PageRouteAnimation.Fade);
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildFooterWidget() {
    return Column(
      children: [
        16.height,
        RichTextWidget(
          list: [
            TextSpan(
              text: "${languages.alreadyHaveAccountTxt}? ",
              style: secondaryTextStyle(),
            ),
            TextSpan(
              text: languages.signIn,
              style: boldTextStyle(color: primaryColor),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  finish(context);
                },
            ),
          ],
        ),
        30.height,
      ],
    );
  }
}