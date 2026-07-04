class Certificate {
  final String id;
  final String dispatchNumber;
  final String name;
  final String fathersName;
  final String gender;
  final String nationality;
  final String issuedDate;
  final String signatureName;
  final String signatureRank;
  final String photoUrl;
  final String statusText;

  Certificate({
    required this.id,
    required this.dispatchNumber,
    required this.name,
    required this.fathersName,
    required this.gender,
    required this.nationality,
    required this.issuedDate,
    required this.signatureName,
    required this.signatureRank,
    required this.photoUrl,
    required this.statusText,
  });

  Certificate copyWith({
    String? id,
    String? dispatchNumber,
    String? name,
    String? fathersName,
    String? gender,
    String? nationality,
    String? issuedDate,
    String? signatureName,
    String? signatureRank,
    String? photoUrl,
    String? statusText,
  }) {
    return Certificate(
      id: id ?? this.id,
      dispatchNumber: dispatchNumber ?? this.dispatchNumber,
      name: name ?? this.name,
      fathersName: fathersName ?? this.fathersName,
      gender: gender ?? this.gender,
      nationality: nationality ?? this.nationality,
      issuedDate: issuedDate ?? this.issuedDate,
      signatureName: signatureName ?? this.signatureName,
      signatureRank: signatureRank ?? this.signatureRank,
      photoUrl: photoUrl ?? this.photoUrl,
      statusText: statusText ?? this.statusText,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dispatchNumber': dispatchNumber,
      'name': name,
      'fathersName': fathersName,
      'gender': gender,
      'nationality': nationality,
      'issuedDate': issuedDate,
      'signatureName': signatureName,
      'signatureRank': signatureRank,
      'photoUrl': photoUrl,
      'statusText': statusText,
    };
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'dispatch_number': dispatchNumber,
      'name': name,
      'fathers_name': fathersName,
      'gender': gender,
      'nationality': nationality,
      'issued_date': issuedDate,
      'signature_name': signatureName,
      'signature_rank': signatureRank,
      'photo_url': photoUrl,
      'status_text': statusText,
    };
  }

  factory Certificate.fromJson(Map<String, dynamic> json) {
    return Certificate(
      id: json['id'] as String? ?? '',
      dispatchNumber: (json['dispatchNumber'] ?? json['dispatch_number']) as String? ?? '',
      name: json['name'] as String? ?? '',
      fathersName: (json['fathersName'] ?? json['fathers_name']) as String? ?? '',
      gender: json['gender'] as String? ?? '',
      nationality: json['nationality'] as String? ?? '',
      issuedDate: (json['issuedDate'] ?? json['issued_date']) as String? ?? '',
      signatureName: (json['signatureName'] ?? json['signature_name']) as String? ?? '',
      signatureRank: (json['signatureRank'] ?? json['signature_rank']) as String? ?? '',
      photoUrl: (json['photoUrl'] ?? json['photo_url'] ?? json['photoBase64']) as String? ?? '',
      statusText: (json['statusText'] ?? json['status_text']) as String? ?? '',
    );
  }
}
