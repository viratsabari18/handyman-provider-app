import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:handyman_provider_flutter/auth/component/user_demo_mode_screen.dart';
import 'package:handyman_provider_flutter/auth/forgot_password_dialog.dart';
import 'package:handyman_provider_flutter/auth/sign_up_screen.dart';
import 'package:handyman_provider_flutter/components/app_widgets.dart';
import 'package:handyman_provider_flutter/components/selected_item_widget.dart';
import 'package:handyman_provider_flutter/handyman/handyman_dashboard_screen.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/user_data.dart';

import 'package:handyman_provider_flutter/provider/provider_dashboard_screen.dart';
import 'package:handyman_provider_flutter/utils/common.dart';
import 'package:handyman_provider_flutter/utils/configs.dart';
import 'package:handyman_provider_flutter/utils/constant.dart';
import 'package:handyman_provider_flutter/utils/extensions/string_extension.dart';
import 'package:handyman_provider_flutter/utils/images.dart';
import 'package:nb_utils/nb_utils.dart';

import '../networks/rest_apis.dart';

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  //-------------------------------- Variables -------------------------------//

  TextEditingController emailCont = TextEditingController();
  TextEditingController passwordCont = TextEditingController();

  FocusNode emailFocus = FocusNode();
  FocusNode passwordFocus = FocusNode();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  AutovalidateMode autovalidateMode = AutovalidateMode.disabled;

  bool isRemember = false;
  String? loginError;
  bool isLoginError = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    emailCont.dispose();
    passwordCont.dispose();
    passwordFocus.dispose();
    emailFocus.dispose();
    super.dispose();
  }

  void init() async {
    // Load saved "Remember Me" state
    isRemember = await getBoolAsync(IS_REMEMBERED, defaultValue: false);
    if (isRemember) {
      // Restore credentials only if Remember Me was checked
      emailCont.text = await getStringAsync(USER_EMAIL);
      passwordCont.text = await getStringAsync(USER_PASSWORD);
    } else {
      // Clear fields if not remembered
      emailCont.clear();
      passwordCont.clear();
    }
    setState(() {});
  }

  void _clearLoginError() {
    if (isLoginError) {
      setState(() {
        loginError = null;
        isLoginError = false;
      });
    }
  }

  //------------------------------------ UI ----------------------------------//

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SizedBox(
          height: context.height(),
          width: context.width(),
          child: Stack(
            children: [
              Form(
                key: formKey,
                autovalidateMode: autovalidateMode,
                child: SingleChildScrollView(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: AppBar().preferredSize.height),
                      _buildHelloAgainWithWelcomeText(),

                      if (loginError != null)
                        Container(
                          margin: EdgeInsets.only(bottom: 16),
                          padding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  color: Colors.red, size: 20),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  loginError!,
                                  style: TextStyle(
                                      color: Colors.red.shade700, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),

                      AutofillGroup(
                        onDisposeAction: AutofillContextAction.commit,
                        child: Column(
                          children: [
                            AppTextField(
                              textFieldType: TextFieldType.EMAIL_ENHANCED,
                              controller: emailCont,
                              focus: emailFocus,
                              autoFocus: true,
                              nextFocus: passwordFocus,
                              errorThisFieldRequired: languages.hintRequired,
                              decoration: inputDecoration(
                                context,
                                hint: languages.hintEmailAddressTxt,
                              ),
                              suffix:
                                  ic_message.iconImage(size: 10).paddingAll(14),
                              autoFillHints: [AutofillHints.email],
                              onChanged: (value) => _clearLoginError(),
                              onFieldSubmitted: (val) => FocusScope.of(context)
                                  .requestFocus(passwordFocus),
                            ),
                            16.height,
                            AppTextField(
                              textFieldType: TextFieldType.PASSWORD,
                              controller: passwordCont,
                              focus: passwordFocus,
                              obscureText: true,
                              errorThisFieldRequired: languages.hintRequired,
                              suffixPasswordVisibleWidget:
                                  ic_show.iconImage(size: 10).paddingAll(14),
                              suffixPasswordInvisibleWidget:
                                  ic_hide.iconImage(size: 10).paddingAll(14),
                              errorMinimumPasswordLength:
                                  "${languages.errorPasswordLength} $passwordLengthGlobal",
                              decoration: inputDecoration(context,
                                  hint: languages.hintPassword),
                              autoFillHints: [AutofillHints.password],
                              isValidationRequired: true,
                              onChanged: (value) => _clearLoginError(),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return languages.hintRequired;
                                } else if (val.length < 8 || val.length > 12) {
                                  return languages.passwordLengthShouldBe;
                                }
                                return null;
                              },
                              onFieldSubmitted: (s) => _handleLogin(),
                            ),
                            8.height,
                          ],
                        ),
                      ),

                      _buildForgotRememberWidget(),
                      _buildButtonWidget(),
                      16.height,

                      // Demo mode widget (optional)
                      SnapHelperWidget<bool>(
                        future: isIqonicProduct,
                        onSuccess: (data) {
                          if (data) {
                            return UserDemoModeScreen(
                              onChanged: (email, password) {
                                setState(() {
                                  if (email.isNotEmpty && password.isNotEmpty) {
                                    emailCont.text = email;
                                    passwordCont.text = password;
                                  } else {
                                    emailCont.clear();
                                    passwordCont.clear();
                                  }
                                  loginError = null;
                                  isLoginError = false;
                                });
                              },
                            );
                          }
                          return Offstage();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Observer(
                builder: (_) =>
                    LoaderWidget().center().visible(appStore.isLoading),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //region Widgets
  Widget _buildHelloAgainWithWelcomeText() {
    return Column(
      children: [
        32.height,
        Text(languages.lblLoginTitle, style: boldTextStyle(size: 18)).center(),
        16.height,
        Text(
          languages.lblLoginSubtitle,
          style: secondaryTextStyle(size: 14),
          textAlign: TextAlign.center,
        ).paddingSymmetric(horizontal: 32).center(),
        64.height,
      ],
    );
  }

  Widget _buildForgotRememberWidget() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                2.width,
                SelectedItemWidget(isSelected: isRemember).onTap(() async {
                  await setValue(IS_REMEMBERED, !isRemember);
                  isRemember = !isRemember;
                  setState(() {});
                }),
                TextButton(
                  onPressed: () async {
                    await setValue(IS_REMEMBERED, !isRemember);
                    isRemember = !isRemember;
                    setState(() {});
                  },
                  child:
                      Text(languages.rememberMe, style: secondaryTextStyle()),
                ),
              ],
            ),
            TextButton(
              child: Text(
                languages.forgotPassword,
                style: boldTextStyle(
                  color: primaryColor,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.right,
              ),
              onPressed: () {
                showInDialog(
                  context,
                  contentPadding: EdgeInsets.zero,
                  builder: (_) => ForgotPasswordScreen(),
                );
              },
            ).flexible(),
          ],
        ),
        32.height,
      ],
    );
  }

  Widget _buildButtonWidget() {
    return Column(
      children: [
        AppButton(
          text: languages.signIn,
          height: 40,
          color: primaryColor,
          textStyle: boldTextStyle(color: white),
          width: context.width() - context.navigationBarHeight,
          onTap: _handleLogin,
        ),
        16.height,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(languages.doNotHaveAccount, style: secondaryTextStyle()),
            TextButton(
              onPressed: () {
                setState(() {
                  loginError = null;
                  isLoginError = false;
                });
                SignUpScreen().launch(context);
              },
              child: Text(
                languages.signUp,
                style: boldTextStyle(
                  color: primaryColor,
                  decoration: TextDecoration.underline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleLogin() {
    hideKeyboard(context);
    _clearLoginError();
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      _handleLoginUsers();
    }
  }

  void _handleLoginUsers() async {
    hideKeyboard(context);
    appStore.setLoading(true);

    try {
      // ✅ FIXED: Create a Map with email and password parameters
      final Map<String, dynamic> request = {
        'email': emailCont.text.trim(),
        'password': passwordCont.text,
      };

      final user = await loginUser(request);

      if (user == null) {
        setState(() {
          loginError = "Invalid email or password";
          isLoginError = true;
        });
        appStore.setLoading(false);
        passwordCont.clear();
        FocusScope.of(context).requestFocus(passwordFocus);
        return;
      }

      // Save token
      await setValue("TOKEN", user.apiToken ?? "");

      // Handle Remember Me: save email/password only if checked
      if (isRemember) {
        await setValue(USER_EMAIL, emailCont.text.trim());
        await setValue(USER_PASSWORD, passwordCont.text);
      } else {
        // Clear saved credentials if not remembered
        await removeKey(USER_EMAIL);
        await removeKey(USER_PASSWORD);
      }
      await setValue(IS_REMEMBERED, isRemember);
      await saveUserData(user);
      await authService.verifyFirebaseUser();

      passwordCont.clear();
      redirectWidget(res: user);
    } catch (e) {
      appStore.setLoading(false);

      String errorMessage = e.toString();
      if (errorMessage.contains('Exception:')) {
        errorMessage = errorMessage.replaceAll('Exception:', '').trim();
      }

      if (errorMessage.toLowerCase().contains('email') ||
          errorMessage.toLowerCase().contains('not found')) {
        setState(() {
          loginError = "Email address not found";
          isLoginError = true;
        });
      } else if (errorMessage.toLowerCase().contains('password') ||
          errorMessage.toLowerCase().contains('credential')) {
        setState(() {
          loginError = "Incorrect password. Please try again.";
          isLoginError = true;
        });
      } else {
        setState(() {
          loginError = errorMessage;
          isLoginError = true;
        });
      }

      passwordCont.clear();
      FocusScope.of(context).requestFocus(passwordFocus);
      toast(e.toString());
    }
  }

  void redirectWidget({required UserData res}) async {
    appStore.setLoading(false);
    await appStore.setToken(res.apiToken ?? "");

    if (res.userType == USER_TYPE_PROVIDER) {
      ProviderDashboardScreen().launch(context, isNewTask: true);
    } else if (res.userType == USER_TYPE_HANDYMAN) {
      HandymanDashboardScreen().launch(context, isNewTask: true);
    } else {
      toast("Invalid user type");
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }
}
