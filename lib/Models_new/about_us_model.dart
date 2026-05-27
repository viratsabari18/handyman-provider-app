class AboutUsModel {
  bool? status;
  String? data;

  AboutUsModel({
    this.status,
    this.data,
  });

  AboutUsModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    data = json['data'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> dataMap = <String, dynamic>{};

    dataMap['status'] = status;
    dataMap['data'] = data;

    return dataMap;
  }
}