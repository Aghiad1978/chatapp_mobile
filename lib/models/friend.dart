class Friend {
  Friend({
    required this.friendName,
    required this.email,
    required this.mobile,
    required this.uuid,
    this.image = "assets/images/avatar.png",
  });
  String friendName;
  String email;
  String mobile;
  String uuid;
  String image;

  static Friend friendFromData(Map<String, dynamic> data) {
    return Friend(
        friendName: data["friendName"],
        email: data["email"],
        mobile: data["mobile"],
        uuid: data["uuid"]);
  }

  @override
  String toString() {
    return "Friend(name:$friendName,uuid:$uuid,mobile:$mobile,email:$email)";
  }
}
