class CarouselResponse {
  final bool status;
  final List<String> carouselImages;

  CarouselResponse({
    required this.status,
    required this.carouselImages,
  });

  factory CarouselResponse.fromJson(Map<String, dynamic> json) {
    return CarouselResponse(
      status: json['status'] ?? false,
      carouselImages: List<String>.from(json['carousel_images'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'carousel_images': carouselImages,
    };
  }
}