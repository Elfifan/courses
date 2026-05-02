import '../repositories/achievement_repository.dart';


class Employee {
  final int id;
  final String? surname;
  final String? name;
  final String? patronymic;
  final String? email;
  final String? password;
  final bool? status;
  final String? role;

  Employee({
    required this.id,
    this.surname,
    this.name,
    this.patronymic,
    this.email,
    this.password,
    this.status,
    this.role,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as int,
      surname: json['surname'] as String?,
      name: json['name'] as String?,
      patronymic: json['patronymic'] as String?,
      email: json['email'] as String?,
      password: json['password'] as String?,
      status: json['status'] as bool?,
      role: json['role'] as String?,
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
      'role': role,
    };
  }
}

// Модель для кодов восстановления пароля
class PasswordRecoveryCode {
  final int id;
  final String email;
  final String code;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool used;

  PasswordRecoveryCode({
    required this.id,
    required this.email,
    required this.code,
    required this.createdAt,
    required this.expiresAt,
    required this.used,
  });

  factory PasswordRecoveryCode.fromJson(Map<String, dynamic> json) {
    return PasswordRecoveryCode(
      id: json['id'] as int,
      email: json['email'] as String,
      code: json['code'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      used: json['used'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'code': code,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'used': used,
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
    return {'id': id, 'name': name, 'view': view};
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
  final String? status;
  final String? icon;

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
      status: json['status'] as String?,
      icon: json['icon'] as String?,
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
  final int? orderModule;
  final bool? status;

  Module({
    required this.id,
    this.idCourses,
    this.name,
    this.orderModule,
    this.status,
  });

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      id: json['id'] as int,
      idCourses: json['id_courses'] as int?,
      name: json['name'] as String?,
      orderModule: json['order_module'] as int?,
      status: json['status'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_courses': idCourses,
      'name': name,
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
  final int? orderSubmodule;

  Submodule({
    required this.id,
    this.idModule,
    this.name,
    this.description,
    this.content,
    this.leadTime,
    this.status,
    this.orderSubmodule,
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
      orderSubmodule: json['order_submodule'] as int?,
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
      'order_submodule': orderSubmodule,
    };
  }
}

class Test {
  final int id;
  final String? name;
  final String? question;
  final String? rightAnswer;
  final String? wrongAnswer1;
  final String? wrongAnswer2;
  final String? wrongAnswer3;
  final bool? status;
  final int? difficulty;
  final String? category;

  Test({
    required this.id,
    this.name,
    this.question,
    this.rightAnswer,
    this.wrongAnswer1,
    this.wrongAnswer2,
    this.wrongAnswer3,
    this.status,
    this.difficulty,
    this.category,
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
      difficulty: json['difficulty'] as int?,
      category: json['category'] as String?,
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
      'difficulty': difficulty,
      'category': category,
    };
  }
}

class StudentTestResult {
  final int id;
  final int? idUser;
  final int? idTest;
  final int? idSubmodule;
  final String? selectedAnswer;
  final bool? isCorrect;
  final DateTime? dateCompleted;

  StudentTestResult({
    required this.id,
    this.idUser,
    this.idTest,
    this.idSubmodule,
    this.selectedAnswer,
    this.isCorrect,
    this.dateCompleted,
  });

  factory StudentTestResult.fromJson(Map<String, dynamic> json) {
    return StudentTestResult(
      id: json['id'] as int,
      idUser: json['id_user'] as int?,
      idTest: json['id_test'] as int?,
      idSubmodule: json['id_submodule'] as int?,
      selectedAnswer: json['selected_answer'] as String?,
      isCorrect: json['is_correct'] as bool?,
      dateCompleted: json['date_completed'] != null
          ? DateTime.parse(json['date_completed'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_user': idUser,
      'id_test': idTest,
      'id_submodule': idSubmodule,
      'selected_answer': selectedAnswer,
      'is_correct': isCorrect,
      'date_completed': dateCompleted?.toIso8601String(),
    };
  }
}

class PracticalTask {
  final int id;
  final int? idSubmodule;
  final String? name;
  final String? description;
  final String? content;
  final int? orderTask;
  final int? difficulty;
  final bool? status;

  PracticalTask({
    required this.id,
    this.idSubmodule,
    this.name,
    this.description,
    this.content,
    this.orderTask,
    this.difficulty,
    this.status,
  });

  factory PracticalTask.fromJson(Map<String, dynamic> json) {
    return PracticalTask(
      id: json['id'] as int,
      idSubmodule: json['id_submodule'] as int?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      content: json['content'] as String?,
      orderTask: json['order_task'] as int?,
      difficulty: json['difficulty'] as int?,
      status: json['status'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_submodule': idSubmodule,
      'name': name,
      'description': description,
      'content': content,
      'order_task': orderTask,
      'difficulty': difficulty,
      'status': status,
    };
  }
}

class StudentPracticalResult {
  final int id;
  final int? idUser;
  final int? idTask;
  final int? idSubmodule;
  final String? submission;
  final String? status;
  final double? score;
  final DateTime? dateSubmitted;

  StudentPracticalResult({
    required this.id,
    this.idUser,
    this.idTask,
    this.idSubmodule,
    this.submission,
    this.status,
    this.score,
    this.dateSubmitted,
  });

  factory StudentPracticalResult.fromJson(Map<String, dynamic> json) {
    return StudentPracticalResult(
      id: json['id'] as int,
      idUser: json['id_user'] as int?,
      idTask: json['id_task'] as int?,
      idSubmodule: json['id_submodule'] as int?,
      submission: json['submission'] as String?,
      status: json['status'] as String?,
      score: (json['score'] as num?)?.toDouble(),
      dateSubmitted: json['date_submitted'] != null
          ? DateTime.parse(json['date_submitted'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_user': idUser,
      'id_task': idTask,
      'id_submodule': idSubmodule,
      'submission': submission,
      'status': status,
      'score': score,
      'date_submitted': dateSubmitted?.toIso8601String(),
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
class Feedback {
  final int id;
  final int? idUser;
  final int? idCourses;
  final double? estimation;
  final String? description;
  final bool? status;

  Feedback({
    required this.id,
    this.idUser,
    this.idCourses,
    this.estimation,
    this.description,
    this.status,
  });

  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      id: json['id'] as int,
      idUser: json['id_user'] as int?,
      idCourses: json['id_courses'] as int?,
      estimation: (json['estimation'] as num?)?.toDouble(),
      description: json['description'] as String?,
      status: json['status'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_user': idUser,
      'id_courses': idCourses,
      'estimation': estimation,
      'description': description,
      'status': status,
    };
  }
}

// Модель ответа на обратную связь (таблица response_feedback)
class ResponseFeedback {
  final int id;
  final DateTime createdAt;
  final int? idEmployee;
  final int? idFeedback;
  final String? answer;

  ResponseFeedback({
    required this.id,
    required this.createdAt,
    this.idEmployee,
    this.idFeedback,
    this.answer,
  });

  factory ResponseFeedback.fromJson(Map<String, dynamic> json) {
    return ResponseFeedback(
      id: json['id'] as int,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      idEmployee: json['id_employee'] as int?,
      idFeedback: json['id_feedback'] as int?,
      answer: json['answer'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'id_employee': idEmployee,
      'id_feedback': idFeedback,
      'answer': answer,
    };
  }
}


class Achievement {
  final int id;
  final DateTime createdAt;
  final String name;
  final String? description;
  final bool status;
  final String? imageUrl; // <-- ТЕПЕРЬ ЭТО URL ИЗ STORAGE

  Achievement({
    required this.id,
    required this.createdAt,
    required this.name,
    this.description,
    required this.status,
    this.imageUrl,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    // Получаем путь из БД (поле 'image')
    final String? imagePath = json['image'] as String?;

    // Преобразуем путь в полный URL через репозиторий
    // ВАЖНО: Убедитесь, что AchievementRepository импортирован или
    // используйте этот метод статически, как показано ниже.
    // Чтобы избежать циклических зависимостей, можно просто хранить путь,
    // а URL формировать на уровне UI. Но для удобства оставим так.
    String? imageUrl;
    try {
      // Небольшая задержка для избежания циклического импорта на этапе анализа.
      // Импортируйте 'achievement_repository.dart' вверху файла.
      imageUrl = AchievementRepository.getImageUrl(imagePath);
    } catch (e) {
      // На случай, если что-то пойдет не так
      imageUrl = null;
    }

    // Обработка даты
    DateTime createdAt;
    final createdAtValue = json['created_at'];
    if (createdAtValue is String) {
      createdAt = DateTime.tryParse(createdAtValue) ?? DateTime.now();
    } else if (createdAtValue is DateTime) {
      createdAt = createdAtValue;
    } else {
      createdAt = DateTime.now();
    }

    // Обработка статуса
    final statusValue = json['status'];
    final bool status = statusValue is bool
        ? statusValue
        : statusValue?.toString().toLowerCase() == 'true';

    // Обработка ID
    final idValue = json['id'];
    final int id = idValue is int
        ? idValue
        : int.tryParse(idValue?.toString() ?? '') ?? 0;

    return Achievement(
      id: id,
      createdAt: createdAt,
      name: json['name'] as String? ?? 'Без названия',
      description: json['description'] as String?,
      status: status,
      imageUrl: imageUrl,
    );
  }

  // toJson больше НЕ ИСПОЛЬЗУЕТСЯ для сохранения, так как сохранение теперь через File.
  // Оставлен для возможной отладки.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'name': name,
      'description': description,
      'status': status,
      // URL не сохраняем обратно, это вычисляемое поле
    };
  }
}

class UserAchievement {
  final int id;
  final int idUser;
  final int idAchievement;

  UserAchievement({
    required this.id,
    required this.idUser,
    required this.idAchievement,
  });

  factory UserAchievement.fromMap(Map<String, dynamic> map) {
    return UserAchievement(
      id: map['id'],
      idUser: map['id_user'],
      idAchievement: map['id_achievement'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'id_user': idUser, 'id_achievement': idAchievement};
  }
}

class SubmoduleTest {
  final int id;
  final int? idSubmodule;
  final int? idTest;
  final int? orderTest;

  SubmoduleTest({
    required this.id,
    this.idSubmodule,
    this.idTest,
    this.orderTest,
  });

  factory SubmoduleTest.fromJson(Map<String, dynamic> json) {
    return SubmoduleTest(
      id: json['id'] as int,
      idSubmodule: json['id_submodule'] as int?,
      idTest: json['id_test'] as int?,
      orderTest: json['order_test'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_submodule': idSubmodule,
      'id_test': idTest,
      'order_test': orderTest,
    };
  }
}
