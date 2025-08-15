class User {
  final String id;
  final String name;
  final String email;
  final String? photoURL;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.photoURL, 
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      photoURL: json['photoURL'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoURL': photoURL,
    };
  }
  
  int get historyCount => 0; 
  int get favoritesCount => 0;
}