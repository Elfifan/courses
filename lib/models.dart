// models.dart

class Module {
  final String title;
  final List<String> submodules;

  Module({required this.title, required this.submodules});

  factory Module.fromJson(Map<String, dynamic> json) {
    var submodulesFromJson = json['submodules'] as List<dynamic>? ?? [];
    List<String> submodulesList = submodulesFromJson.cast<String>();

    return Module(
      title: json['title'] ?? '',
      submodules: submodulesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'submodules': submodules,
    };
  }
}

// Модель курса с модулями
class Course {
  final String icon;       // эмодзи или изображение
  final String type; 
  final String name;
  final int students;
  final String status;
  final String image;
  final String price;
  final double rating;
  final String description;
  final List<Module> modules;

  Course({
    required this.icon,
    required this.type,
    required this.name,
    required this.students,
    required this.status,
    required this.image,
    required this.price,
    required this.rating,
    required this.description,
    required this.modules,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    var modulesFromJson = json['modules'] as List<dynamic>? ?? [];
    List<Module> modulesList =
        modulesFromJson.map((m) => Module.fromJson(m)).toList();

    return Course(
      icon: json['icon'] ?? '',
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      students: json['students'] ?? 0,
      status: json['status'] ?? '',
      image: json['image'] ?? '',
      price: json['price'] ?? '',
      rating: (json['rating'] != null)
          ? (json['rating'] as num).toDouble()
          : 0.0,
      description: json['description'] ?? '',
      modules: modulesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'students': students,
      'status': status,
      'image': image,
      'price': price,
      'rating': rating,
      'description': description,
      'modules': modules.map((m) => m.toJson()).toList(),
    };
  }
}


// Модель студента
class Student {
  final String name;
  final String email;
  final String status;
  final String avatar;
  final String? phone;
  final String? joinDate;
  final String? course;
  final int? progress;

  Student({
    required this.name,
    required this.email,
    required this.status,
    required this.avatar,
    this.phone,
    this.joinDate,
    this.course,
    this.progress,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      status: json['status'] ?? '',
      avatar: json['avatar'] ?? '',
      phone: json['phone'],
      joinDate: json['joinDate'],
      course: json['course'],
      progress: json['progress'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'status': status,
      'avatar': avatar,
      'phone': phone,
      'joinDate': joinDate,
      'course': course,
      'progress': progress,
    };
  }
}


// Модель сотрудника
class Staff {
  final String name;
  final String role;
  final String email;
  final String department;
  final String avatar;
  final String status;
  final String phone;
  final String joinDate;

  Staff({
    required this.name,
    required this.role,
    required this.email,
    required this.department,
    required this.avatar,
    required this.status,
    required this.phone,
    required this.joinDate,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      email: json['email'] ?? '',
      department: json['department'] ?? '',
      avatar: json['avatar'] ?? '',
      status: json['status'] ?? '',
      phone: json['phone'] ?? '',
      joinDate: json['joinDate'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'role': role,
      'email': email,
      'department': department,
      'avatar': avatar,
      'status': status,
      'phone': phone,
      'joinDate': joinDate,
    };
  }
}
