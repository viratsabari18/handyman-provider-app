import 'package:flutter/material.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/base_response.dart';
import 'package:handyman_provider_flutter/models/user_bank_model.dart';
import 'package:handyman_provider_flutter/networks/network_utils.dart';
import 'package:handyman_provider_flutter/screens/cash_management/model/cash_detail_model.dart';
import 'package:handyman_provider_flutter/screens/cash_management/model/payment_history_model.dart';
import 'package:handyman_provider_flutter/utils/common.dart';
import 'package:handyman_provider_flutter/utils/constant.dart';
import 'package:nb_utils/nb_utils.dart';

// Future<List<PaymentHistoryData>> getPaymentHistory({required String bookingId}) async {
//   String bId = "booking_id=$bookingId";
//   PaymentHistoryModel res = PaymentHistoryModel.fromJson(await handleResponse(await buildHttpResponse('payment-history?$bId', method: HttpMethodType.GET)));

//   return res.data.validate();
// }

Future<List<PaymentHistoryData>> getPaymentHistory({required String bookingId}) async {
  // Simulate network delay
  await Future.delayed(Duration(seconds: 1));
  
  // Create mock payment history data
  List<PaymentHistoryData> mockData = [
    PaymentHistoryData(
      id: 1,
      paymentId: 1001,
      bookingId: int.tryParse(bookingId) ?? 1,
      action: "credit",
      text: "Payment received from customer",
  
      status: "completed",
      senderId: 5,  // customer id
      receiverId: 2, // provider id
      parentId: null,
      txnId: "TXN_${DateTime.now().millisecondsSinceEpoch}_001",
      otherTransactionDetail: "Payment for AC Repair service",
      datetime: DateTime.now().subtract(Duration(days: 2)),
      totalAmount: 500,
    ),
    PaymentHistoryData(
      id: 2,
      paymentId: 1002,
      bookingId: int.tryParse(bookingId) ?? 1,
      action: "debit",
      text: "Platform fee deducted",

      status: "completed",
      senderId: 2,  // provider id
      receiverId: 1, // admin id
      parentId: null,
      txnId: "TXN_${DateTime.now().millisecondsSinceEpoch}_002",
      otherTransactionDetail: "Service fee (10%)",
      datetime: DateTime.now().subtract(Duration(days: 2, hours: 1)),
      totalAmount: 50,
    ),
    PaymentHistoryData(
      id: 3,
      paymentId: 1003,
      bookingId: int.tryParse(bookingId) ?? 1,
      action: "credit",
      text: "Handyman payment",

      status: "pending",
      senderId: 2,  // provider id
      receiverId: 3, // handyman id
      parentId: null,
      txnId: "TXN_${DateTime.now().millisecondsSinceEpoch}_003",
      otherTransactionDetail: "Payment to handyman for service completion",
      datetime: DateTime.now().subtract(Duration(days: 1)),
      totalAmount: 300,
    ),
    PaymentHistoryData(
      id: 4,
      paymentId: 1004,
      bookingId: int.tryParse(bookingId) ?? 1,
      action: "credit",
      text: "Wallet payment",
      type: "wallet",
      status: "completed",
      senderId: 5,  // customer id
      receiverId: 2, // provider id
      parentId: 1001,
      txnId: "TXN_${DateTime.now().millisecondsSinceEpoch}_004",
      otherTransactionDetail: "Partial payment via wallet",
      datetime: DateTime.now().subtract(Duration(days: 3)),
      totalAmount: 200,
    ),
    PaymentHistoryData(
      id: 5,
      paymentId: 1005,
      bookingId: int.tryParse(bookingId) ?? 1,
      action: "debit",
      text: "Refund processed",

      status: "completed",
      senderId: 2,  // provider id
      receiverId: 5, // customer id
      parentId: null,
      txnId: "TXN_${DateTime.now().millisecondsSinceEpoch}_005",
      otherTransactionDetail: "Refund due to cancellation",
      datetime: DateTime.now().subtract(Duration(days: 4)),
      totalAmount: 100,
    ),
  ];
  
  // Return only relevant data for this booking
  return mockData.where((item) => item.bookingId == int.tryParse(bookingId)).toList();
}

Future<(num, num, List<PaymentHistoryData>)> getCashDetails({
  int? page,
  int? providerId,
  String? toDate,
  String? fromDate,
  String? statusType,
  required List<PaymentHistoryData> list,
  Function(bool)? lastPageCallback,
  bool disableLoader = false,
}) async {
  final queryParams = <String, dynamic>{
    if (page != null) 'page': page.toString(),
    if (fromDate != null) 'from': fromDate,
    if (toDate != null) 'to': toDate,
    if (statusType != null) 'status': statusType,
    'per_page': PER_PAGE_ITEM,
  };

  try {
    final response = await buildHttpResponse('cash-detail?${queryParams.joinWithMap('&')}', method: HttpMethodType.GET);
    final res = CashHistoryModel.fromJson(await handleResponse(response));

    if (page == 1) {
      list.clear();
    }

    list.addAll(res.data.validate());
    lastPageCallback?.call(res.data.validate().length != PER_PAGE_ITEM);
    appStore.setLoading(false);
    return (res.totalCashInHand.validate(), res.todayCash.validate(), list);
  } catch (e) {
    if (!disableLoader) {
      appStore.setLoading(false);
    }

    throw e;
  }
}

Future<UserBankDetails> getUserBankDetail({required int userId}) async {
  return UserBankDetails.fromJson(await handleResponse(await buildHttpResponse('user-bank-detail?user_id=$userId', method: HttpMethodType.GET)));
}

Future<BaseResponseModel> transferCashAPI({required Map<String, dynamic> req}) async {
  return BaseResponseModel.fromJson(await handleResponse(await buildHttpResponse('transfer-payment', method: HttpMethodType.POST, request: req)));
}

Future<void> transferAmountAPI(
  BuildContext context, {
  required PaymentHistoryData paymentData,
  required String status,
  required String action,
  bool isFinishRequired = true,
  Function()? onTap,
}) async {
  await showConfirmDialogCustom(
    context,
    title: languages.confirmationRequestTxt,
    positiveText: languages.lblYes,
    negativeText: languages.lblNo,
    primaryColor: context.primaryColor,
    onAccept: (p0) async {
      Map<String, dynamic> req = {
        "payment_id": paymentData.paymentId.validate(),
        "booking_id": paymentData.bookingId.validate(),
        "action": action,
        "type": paymentData.type,
        "sender_id": paymentData.senderId,
        "receiver_id": paymentData.receiverId,
        "txn_id": paymentData.txnId,
        "other_transaction_detail": "",
        "datetime": formatBookingDate(DateTime.now().toString(), format: DATE_FORMAT_7),
        "total_amount": paymentData.totalAmount,
        "status": status,
        "p_id": paymentData.id,
        "parent_id": paymentData.parentId,
      };
      log(req);
      appStore.setLoading(true);

      await transferCashAPI(req: req).then((value) {
        onTap?.call();
        if (isFinishRequired) {
          finish(context);
        }
        toast(value.message.validate());

        appStore.setLoading(false);
      }).catchError((e) {
        toast(e.toString());
        appStore.setLoading(false);
      });
    },
  );
}
