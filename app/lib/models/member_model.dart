class MemberModel {
  final String memberId;
  final String phoneNumber;
  final String? profileImageUrl;
  final String? prefix;
  final String firstName;
  final String lastName;
  final String? aboutMe;
  final String? addressDetail;
  final String? province;
  final String? district;
  final String? subdistrict;
  final String? postalCode;
  final DateTime? memberSince;

  const MemberModel({
    required this.memberId,
    required this.phoneNumber,
    this.profileImageUrl,
    this.prefix,
    required this.firstName,
    required this.lastName,
    this.aboutMe,
    this.addressDetail,
    this.province,
    this.district,
    this.subdistrict,
    this.postalCode,
    this.memberSince,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) => MemberModel(
        memberId: json['memberId'] as String,
        phoneNumber: json['phoneNumber'] as String,
        profileImageUrl: json['profileImageUrl'] as String?,
        prefix: json['prefix'] as String?,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        aboutMe: json['aboutMe'] as String?,
        addressDetail: json['addressDetail'] as String?,
        province: json['province'] as String?,
        district: json['district'] as String?,
        subdistrict: json['subdistrict'] as String?,
        postalCode: json['postalCode'] as String?,
        memberSince: json['memberSince'] != null
            ? DateTime.parse(json['memberSince'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'memberId': memberId,
        'phoneNumber': phoneNumber,
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
        if (prefix != null) 'prefix': prefix,
        'firstName': firstName,
        'lastName': lastName,
        if (aboutMe != null) 'aboutMe': aboutMe,
        if (addressDetail != null) 'addressDetail': addressDetail,
        if (province != null) 'province': province,
        if (district != null) 'district': district,
        if (subdistrict != null) 'subdistrict': subdistrict,
        if (postalCode != null) 'postalCode': postalCode,
        if (memberSince != null) 'memberSince': memberSince!.toIso8601String(),
      };

  MemberModel copyWith({
    String? profileImageUrl,
    String? prefix,
    String? firstName,
    String? lastName,
    String? aboutMe,
    String? addressDetail,
    String? province,
    String? district,
    String? subdistrict,
    String? postalCode,
  }) => MemberModel(
        memberId: memberId,
        phoneNumber: phoneNumber,
        profileImageUrl: profileImageUrl ?? this.profileImageUrl,
        prefix: prefix ?? this.prefix,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        aboutMe: aboutMe ?? this.aboutMe,
        addressDetail: addressDetail ?? this.addressDetail,
        province: province ?? this.province,
        district: district ?? this.district,
        subdistrict: subdistrict ?? this.subdistrict,
        postalCode: postalCode ?? this.postalCode,
        memberSince: memberSince,
      );
}
