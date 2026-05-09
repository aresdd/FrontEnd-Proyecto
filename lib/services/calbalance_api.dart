import 'dart:convert';

import '../models/models.dart';
import 'api_client.dart';

Map<String, dynamic> _safeJsonMap(String body) {
  final decoded = jsonDecode(body);
  if (decoded is Map<String, dynamic>) return decoded;
  throw FormatException('Expected JSON object, got: ${body.length > 200 ? body.substring(0, 200) : body}');
}

List<dynamic> _safeJsonList(String body) {
  final decoded = jsonDecode(body);
  if (decoded is List) return decoded;
  throw FormatException('Expected JSON array, got: ${body.length > 200 ? body.substring(0, 200) : body}');
}

class CalBalanceApi {
  CalBalanceApi(this._client);

  final ApiClient _client;

  Future<String> login(String email, String password) async {
    final r = await _client.post(
      '/auth/login',
      auth: false,
      body: {'email': email, 'password': password},
    );
    final j = _safeJsonMap(r.body);
    final token = j['token']?.toString() ?? '';
    await _client.session.setToken(token);
    return token;
  }

  Future<String> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final r = await _client.post(
      '/auth/register',
      auth: false,
      body: {'email': email, 'password': password, 'name': name},
    );
    final j = _safeJsonMap(r.body);
    final token = j['token']?.toString() ?? '';
    await _client.session.setToken(token);
    return token;
  }

  Future<void> logout() => _client.session.setToken(null);

  Future<String> usersMe() async {
    final r = await _client.get('/users/me');
    try {
      final decoded = jsonDecode(r.body);
      if (decoded is String) return decoded;
    } catch (_) {}
    return r.body;
  }

  Future<UserInfoResponse> usersMeInfo() async {
    final r = await _client.get('/users/me/info');
    return UserInfoResponse.fromJson(_safeJsonMap(r.body));
  }

  /// Sends only non-null fields (backend applies partial updates).
  Future<UserInfoResponse> usersUpdateInfo({
    ActivityLevel? activityLevel,
    DateTime? birthDate,
    double? heightCm,
  }) async {
    final body = <String, dynamic>{};
    if (activityLevel != null) body['activityLevel'] = activityLevel.toApi();
    if (birthDate != null) {
      final d = birthDate;
      body['birthDate'] =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
    if (heightCm != null) body['heightCm'] = heightCm;
    final r = await _client.patch('/users/me/edit', body: body);
    return UserInfoResponse.fromJson(_safeJsonMap(r.body));
  }

  /// Marks the current user as inactive (soft deactivate); session should be cleared after success.
  Future<void> usersMeDeactivate() async {
    await _client.delete('/users/me/delete');
  }

  Future<MealResponse> mealsCreate({
    required String mealType,
    required String mealDateIso,
  }) async {
    final r = await _client.post(
      '/meals/create',
      body: {'mealType': mealType, 'mealDate': mealDateIso},
    );
    return MealResponse.fromJson(_safeJsonMap(r.body));
  }

  Future<MealResponse> mealsGetById(int id) async {
    final r = await _client.get('/meals/$id');
    return MealResponse.fromJson(_safeJsonMap(r.body));
  }

  Future<DailySummaryResponse> mealsDaySummary(String dateIso) async {
    final r = await _client.get('/meals/day', query: {'date': dateIso});
    return DailySummaryResponse.fromJson(_safeJsonMap(r.body));
  }

  Future<MealItemResponse> mealItemsCreate({
    required int mealId,
    int? foodId,
    int? dishId,
    required double grams,
  }) async {
    final body = <String, dynamic>{
      'mealId': mealId,
      'grams': grams,
    };
    if (foodId != null) body['foodId'] = foodId;
    if (dishId != null) body['dishId'] = dishId;

    final r = await _client.post('/meal-items/create', body: body);
    return MealItemResponse.fromJson(_safeJsonMap(r.body));
  }

  Future<MealItemResponse> mealItemsUpdateGrams(int id, double grams) async {
    final r = await _client.patch(
      '/meal-items/$id/grams',
      body: {'grams': grams},
    );
    return MealItemResponse.fromJson(_safeJsonMap(r.body));
  }

  Future<void> mealItemsDelete(int id) async {
    await _client.delete('/meal-items/$id/delete');
  }

  Future<DishResponse> dishesCreate({
    required String name,
    String? description,
    required List<Map<String, dynamic>> foods,
  }) async {
    final r = await _client.post(
      '/dishes/create',
      body: {
        'name': name,
        'description': description,
        'foods': foods,
      },
    );
    return DishResponse.fromJson(_safeJsonMap(r.body));
  }

  Future<List<DishResponse>> dishesList() async {
    final r = await _client.get('/dishes/list');
    return _safeJsonList(r.body)
        .map((e) => DishResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<FoodsResponse>> foodsSearch(String query) async {
    final r = await _client.get('/foods/search', query: {'query': query});
    return _safeJsonList(r.body)
        .map((e) => FoodsResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FoodsResponse> foodsCreate({
    required String name,
    String? brand,
    required double caloriesPer100g,
    required double proteinPer100g,
    required double carbsPer100g,
    required double fatPer100g,
  }) async {
    final r = await _client.post(
      '/foods/create',
      body: {
        'name': name,
        'brand': brand,
        'caloriesPer100g': caloriesPer100g,
        'proteinPer100g': proteinPer100g,
        'carbsPer100g': carbsPer100g,
        'fatPer100g': fatPer100g,
      },
    );
    return FoodsResponse.fromJson(_safeJsonMap(r.body));
  }

  Future<BodyProgressResponse> progressCreate({
    double? weightKg,
    double? bodyFatPercent,
    double? muscleMassKg,
  }) async {
    final r = await _client.post(
      '/progress',
      body: {
        'weightKg': weightKg,
        'bodyFatPercent': bodyFatPercent,
        'muscleMassKg': muscleMassKg,
      },
    );
    return BodyProgressResponse.fromJson(_safeJsonMap(r.body));
  }

  Future<List<BodyProgressResponse>> progressAll() async {
    final r = await _client.get('/progress/all');
    return _safeJsonList(r.body)
        .map((e) => BodyProgressResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BodyProgressResponse> progressLatest() async {
    final r = await _client.get('/progress/latest');
    return BodyProgressResponse.fromJson(_safeJsonMap(r.body));
  }

  /// Partial update: only keys present in [body] are sent (nulls omitted).
  Future<BodyProgressResponse> progressUpdate(
    int id, {
    double? weightKg,
    double? bodyFatPercent,
    double? muscleMassKg,
  }) async {
    final body = <String, dynamic>{};
    if (weightKg != null) body['weightKg'] = weightKg;
    if (bodyFatPercent != null) body['bodyFatPercent'] = bodyFatPercent;
    if (muscleMassKg != null) body['muscleMassKg'] = muscleMassKg;
    final r = await _client.patch('/progress/$id/edit', body: body);
    return BodyProgressResponse.fromJson(_safeJsonMap(r.body));
  }

  Future<NutritionGoalResponse> goalsCreate({
    required String goalType,
    int? dailyCalories,
    int? proteinG,
    int? carbsG,
    int? fatG,
    String? startDateIso,
    String? endDateIso,
  }) async {
    final r = await _client.post(
      '/goals/create',
      body: {
        'goalType': goalType,
        'dailyCalories': dailyCalories,
        'proteinG': proteinG,
        'carbsG': carbsG,
        'fatG': fatG,
        if (startDateIso != null) 'startDate': startDateIso,
        if (endDateIso != null) 'endDate': endDateIso,
      },
    );
    return NutritionGoalResponse.fromJson(_safeJsonMap(r.body));
  }

  Future<NutritionGoalResponse> goalsCurrent() async {
    final r = await _client.get('/goals/current');
    return NutritionGoalResponse.fromJson(_safeJsonMap(r.body));
  }

  Future<NutritionGoalResponse> goalsByDate(String dateIso) async {
    final r = await _client.get('/goals/by-date', query: {'date': dateIso});
    return NutritionGoalResponse.fromJson(_safeJsonMap(r.body));
  }

  Future<List<NutritionGoalResponse>> goalsAll() async {
    final r = await _client.get('/goals/all');
    return _safeJsonList(r.body)
        .map((e) => NutritionGoalResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<NutritionGoalResponse> goalsUpdate(
    int id, {
    required String goalType,
    int? dailyCalories,
    int? proteinG,
    int? carbsG,
    int? fatG,
    String? startDateIso,
    String? endDateIso,
  }) async {
    final r = await _client.put(
      '/goals/$id/edit',
      body: {
        'goalType': goalType,
        'dailyCalories': dailyCalories,
        'proteinG': proteinG,
        'carbsG': carbsG,
        'fatG': fatG,
        if (startDateIso != null) 'startDate': startDateIso,
        if (endDateIso != null) 'endDate': endDateIso,
      },
    );
    return NutritionGoalResponse.fromJson(_safeJsonMap(r.body));
  }

  Future<void> goalsDelete(int id) async {
    await _client.delete('/goals/$id/delete');
  }

  Future<DailyNutritionSummaryResponse> summaryDay({String? dateIso}) async {
    final r = await _client.get(
      '/summary/day',
      query: dateIso == null ? null : {'date': dateIso},
    );
    return DailyNutritionSummaryResponse.fromJson(_safeJsonMap(r.body));
  }

  Future<String> patataTest() async {
    final r = await _client.get('/patata/test');
    try {
      final decoded = jsonDecode(r.body.trim());
      if (decoded is String) return decoded;
    } catch (_) {}
    return r.body.trim();
  }
}
