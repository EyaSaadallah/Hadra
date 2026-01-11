class UserModel {
  final String uid;
  final String email;
  final String? phoneNumber;
  final String? name;
  final String? username;
  final String? profilePic;
  final String? bio;
  final String? address;
  final String? password;
  final int followersCount;
  final int followingCount;
  final int postsCount;

  UserModel({
    required this.uid,
    required this.email,
    this.phoneNumber,
    this.name,
    this.username,
    this.profilePic,
    this.bio,
    this.address,
    this.password,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'phoneNumber': phoneNumber,
      'name': name,
      'username': username,
      'profilePic': profilePic,
      'bio': bio,
      'address': address,
      'password': password,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'],
      name: map['name'],
      username: map['username'],
      profilePic: map['profilePic'],
      bio: map['bio'],
      address: map['address'],
      password: map['password'],
      followersCount: map['followersCount'] ?? 0,
      followingCount: map['followingCount'] ?? 0,
      postsCount: map['postsCount'] ?? 0,
    );
  }
}
