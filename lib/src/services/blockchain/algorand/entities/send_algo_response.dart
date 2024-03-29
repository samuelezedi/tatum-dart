import 'package:json_annotation/json_annotation.dart';

part 'send_algo_response.g.dart';

@JsonSerializable()
class SendAlgoResponse {
  final String txId;

  SendAlgoResponse({required this.txId});

  factory SendAlgoResponse.fromJson(Map<String, dynamic>? json) =>
      _$SendAlgoResponseFromJson(json!);

  Map<String, dynamic> toJson() => _$SendAlgoResponseToJson(this);
}

@JsonSerializable()
class TXIDResponse {
  final String txId;
  final String? confirmed;

  TXIDResponse({required this.txId, this.confirmed});

  factory TXIDResponse.fromJson(Map<String, dynamic>? json) =>
      _$TXIDResponseFromJson(json!);

  Map<String, dynamic> toJson() => _$TXIDResponseToJson(this);
}
