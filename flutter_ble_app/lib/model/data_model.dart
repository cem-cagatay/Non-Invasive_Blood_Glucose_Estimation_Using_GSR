class ReceivedDataModel {
  final int bloodSugar;

  ReceivedDataModel({
    required this.bloodSugar,
  });

  factory ReceivedDataModel.fromJson(Map<String, dynamic> json) {
    return ReceivedDataModel(
      bloodSugar: json['bloodSugar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bloodSugar': bloodSugar,
    };
  }
}

class SendDataModel {
  final double bloodSugar;

  SendDataModel({required this.bloodSugar});

  Map<String, dynamic> toJson() {
    return {
      'bloodSugar': bloodSugar,
    };
  }
}