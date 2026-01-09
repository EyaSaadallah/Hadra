class UserModel {
  final String uid;
  final String phoneNumber;
  final String? name;
  final String? profilePic;
  final String? address;
  final String? password;

  UserModel({
    required this.uid,
    required this.phoneNumber,
    this.name,
    this.profilePic,
    this.address,
    this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'name': name,
      'profilePic': profilePic,
      'address': address,
      'password': password,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      name: map['name'],
      profilePic: map['profilePic'],
      address: map['address'],
      password: map['password'],
    );
  }
}
