class Employee {
  final int id;
  final String? surname;
  final String? name;
  final String? patronymic;
  final String? email;
  final String? password;
  final bool? status;

  Employee({
    required this.id,
    this.surname,
    this.name,
    this.patronymic,
    this.email,
    this.password,
    this.status,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as int,
      surname: json['surname'] as String? ,
      name: json['name'] as String?,
      patronymic: json['patronymic'] as String?,
      email: json['email'] as String?,
      password: json['password'] as String?,
      status: json['status'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'surname': surname,
      'name': name,
      'patronymic': patronymic,
      'email': email,
      'password': password,
      'status': status,
    };
  }
}

// Модель пользователя (таблица users)
class User {
  final int id;
  final String? name;
  final String? email;
  final String? password;
  final DateTime? dateRegistration;
  final List<int>? avatar; // BYTEA -> List<int>
  final bool? status;
  final DateTime? lastEntry;

  User({
    required this.id,
    this.name,
    this.email,
    this.password,
    this.dateRegistration,
    this.avatar,
    this.status,
    this.lastEntry,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String?,
      email: json['email'] as String?,
      password: json['password'] as String?,
      dateRegistration: json['date_registration'] != null
          ? DateTime.parse(json['date_registration'] as String)
          : null,
      avatar: json['avatar'] as List<int>?,
      status: json['status'] as bool?,
      lastEntry: json['last_entry'] != null
          ? DateTime.parse(json['last_entry'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'date_registration': dateRegistration?.toIso8601String(),
      'avatar': avatar,
      'status': status,
      'last_entry': lastEntry?.toIso8601String(),
    };
  }
}

// Модель типа задачи (таблица type_task)
class TypeTask {
  final int id;
  final String? name;
  final String? view;

  TypeTask({required this.id, this.name, this.view});

  factory TypeTask.fromJson(Map<String, dynamic> json) {
    return TypeTask(
      id: json['id'] as int,
      name: json['name'] as String?,
      view: json['view'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'view': view,
    };
  }
}

// Модель курса (таблица courses)
class Course {
  final int id;
  final int? idEmployee;
  final String? name;
  final String? description;
  final DateTime? dateCreate;
  final double? price;
  final int? complexity;
  final bool? status;
  final int? icon;

  Course({
    required this.id,
    this.idEmployee,
    this.name,
    this.description,
    this.dateCreate,
    this.price,
    this.complexity,
    this.status,
    this.icon,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as int,
      idEmployee: json['id_employee'] as int?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      dateCreate: json['date_create'] != null
          ? DateTime.parse(json['date_create'] as String)
          : null,
      price: (json['price'] as num?)?.toDouble(),
      complexity: json['complexity'] as int?,
      status: json['status'] as bool?,
      icon: json['icon'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_employee': idEmployee,
      'name': name,
      'description': description,
      'date_create': dateCreate?.toIso8601String(),
      'price': price,
      'complexity': complexity,
      'status': status,
      'icon': icon,
    };
  }
}

// Модель модуля (таблица module)
class Module {
  final int id;
  final int? idCourses;
  final String? name;
  final String? description;
  final int? orderModule;
  final bool? status;

  Module({
    required this.id,
    this.idCourses,
    this.name,
    this.description,
    this.orderModule,
    this.status,
  });

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      id: json['id'] as int,
      idCourses: json['id_courses'] as int?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      orderModule: json['order_module'] as int?,
      status: json['status'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_courses': idCourses,
      'name': name,
      'description': description,
      'order_module': orderModule,
      'status': status,
    };
  }
}

// Модель подмодуля (таблица submodule)
class Submodule {
  final int id;
  final int? idModule;
  final String? name;
  final String? description;
  final String? content;
  final int? leadTime;
  final bool? status;

  Submodule({
    required this.id,
    this.idModule,
    this.name,
    this.description,
    this.content,
    this.leadTime,
    this.status,
  });

  factory Submodule.fromJson(Map<String, dynamic> json) {
    return Submodule(
      id: json['id'] as int,
      idModule: json['id_module'] as int?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      content: json['content'] as String?,
      leadTime: json['lead_time'] as int?,
      status: json['status'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_module': idModule,
      'name': name,
      'description': description,
      'content': content,
      'lead_time': leadTime,
      'status': status,
    };
  }
}

// Модель теста (таблица test)
class Test {
  final int id;
  final String? name;
  final String? question;
  final String? rightAnswer;
  final String? wrongAnswer1;
  final String? wrongAnswer2;
  final String? wrongAnswer3;
  final bool? status;

  Test({
    required this.id,
    this.name,
    this.question,
    this.rightAnswer,
    this.wrongAnswer1,
    this.wrongAnswer2,
    this.wrongAnswer3,
    this.status,
  });

  factory Test.fromJson(Map<String, dynamic> json) {
    return Test(
      id: json['id'] as int,
      name: json['name'] as String?,
      question: json['question'] as String?,
      rightAnswer: json['right_answer'] as String?,
      wrongAnswer1: json['wrong_answer1'] as String?,
      wrongAnswer2: json['wrong_answer2'] as String?,
      wrongAnswer3: json['wrong_answer3'] as String?,
      status: json['status'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'question': question,
      'right_answer': rightAnswer,
      'wrong_answer1': wrongAnswer1,
      'wrong_answer2': wrongAnswer2,
      'wrong_answer3': wrongAnswer3,
      'status': status,
    };
  }
}

// Связующая таблица test_module (таблица test_module)
class TestModule {
  final int id;
  final int? idModule;
  final int? idTest;

  TestModule({required this.id, this.idModule, this.idTest});

  factory TestModule.fromJson(Map<String, dynamic> json) {
    return TestModule(
      id: json['id'] as int,
      idModule: json['id_module'] as int?,
      idTest: json['id_test'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_module': idModule,
      'id_test': idTest,
    };
  }
}

// Модель performs (таблица performs)
class Performs {
  final int id;
  final int? idSubmodule;
  final int? idModule;
  final bool? status;

  Performs({required this.id, this.idSubmodule, this.idModule, this.status});

  factory Performs.fromJson(Map<String, dynamic> json) {
    return Performs(
      id: json['id'] as int,
      idSubmodule: json['id_submodule'] as int?,
      idModule: json['id_module'] as int?,
      status: json['status'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_submodule': idSubmodule,
      'id_module': idModule,
      'status': status,
    };
  }
}

// Модель tasks_module (таблица tasks_module)
class TasksModule {
  final int id;
  final int? idSubmodule;
  final int? idType;

  TasksModule({required this.id, this.idSubmodule, this.idType});

  factory TasksModule.fromJson(Map<String, dynamic> json) {
    return TasksModule(
      id: json['id'] as int,
      idSubmodule: json['id_submodule'] as int?,
      idType: json['id_type'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_submodule': idSubmodule,
      'id_type': idType,
    };
  }
}

// Модель прохождения курса (таблица passing)
class Passing {
  final int id;
  final int? idUser;
  final int? idCourses;
  final DateTime? datePassage;
  final bool? status;

  Passing({
    required this.id,
    this.idUser,
    this.idCourses,
    this.datePassage,
    this.status,
  });

  factory Passing.fromJson(Map<String, dynamic> json) {
    return Passing(
      id: json['id'] as int,
      idUser: json['id_user'] as int?,
      idCourses: json['id_courses'] as int?,
      datePassage: json['date_passage'] != null
          ? DateTime.parse(json['date_passage'] as String)
          : null,
      status: json['status'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_user': idUser,
      'id_courses': idCourses,
      'date_passage': datePassage?.toIso8601String(),
      'status': status,
    };
  }
}

// Модель обратной связи (таблица feedback)
class FeedbackModel {
  final int id;
  final int? idUser;
  final int? idCourses;
  final double? estimation;
  final String? description;

  FeedbackModel({
    required this.id,
    this.idUser,
    this.idCourses,
    this.estimation,
    this.description,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'] as int,
      idUser: json['id_user'] as int?,
      idCourses: json['id_courses'] as int?,
      estimation: (json['estimation'] as num?)?.toDouble(),
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_user': idUser,
      'id_courses': idCourses,
      'estimation': estimation,
      'description': description,
    };
  }
}
