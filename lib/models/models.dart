double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

class MacroBlock {
  MacroBlock({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;

  factory MacroBlock.fromJson(Map<String, dynamic>? j) {
    if (j == null) {
      return MacroBlock(calories: null, protein: null, carbs: null, fat: null);
    }
    return MacroBlock(
      calories: _toDouble(j['calories']),
      protein: _toDouble(j['protein']),
      carbs: _toDouble(j['carbs']),
      fat: _toDouble(j['fat']),
    );
  }
}

class MacroProgress {
  MacroProgress({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;

  factory MacroProgress.fromJson(Map<String, dynamic>? j) {
    if (j == null) {
      return MacroProgress(
        calories: null,
        protein: null,
        carbs: null,
        fat: null,
      );
    }
    return MacroProgress(
      calories: _toDouble(j['calories']),
      protein: _toDouble(j['protein']),
      carbs: _toDouble(j['carbs']),
      fat: _toDouble(j['fat']),
    );
  }
}

class DailyNutritionSummaryResponse {
  DailyNutritionSummaryResponse({
    required this.date,
    required this.goal,
    required this.consumed,
    required this.remaining,
    required this.progress,
  });

  final String? date;
  final MacroBlock goal;
  final MacroBlock consumed;
  final MacroBlock remaining;
  final MacroProgress progress;

  factory DailyNutritionSummaryResponse.fromJson(Map<String, dynamic> j) {
    return DailyNutritionSummaryResponse(
      date: j['date']?.toString(),
      goal: MacroBlock.fromJson(j['goal'] as Map<String, dynamic>?),
      consumed: MacroBlock.fromJson(j['consumed'] as Map<String, dynamic>?),
      remaining: MacroBlock.fromJson(j['remaining'] as Map<String, dynamic>?),
      progress: MacroProgress.fromJson(j['progress'] as Map<String, dynamic>?),
    );
  }
}

class MealTotals {
  MealTotals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;

  factory MealTotals.fromJson(Map<String, dynamic>? j) {
    if (j == null) {
      return MealTotals(
        calories: null,
        protein: null,
        carbs: null,
        fat: null,
      );
    }
    return MealTotals(
      calories: _toDouble(j['calories']),
      protein: _toDouble(j['protein']),
      carbs: _toDouble(j['carbs']),
      fat: _toDouble(j['fat']),
    );
  }
}

class MealSummaryRow {
  MealSummaryRow({
    required this.mealId,
    required this.mealType,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final int? mealId;
  final String? mealType;
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;

  factory MealSummaryRow.fromJson(Map<String, dynamic> j) {
    return MealSummaryRow(
      mealId: _toInt(j['mealId']),
      mealType: j['mealType']?.toString(),
      calories: _toDouble(j['calories']),
      protein: _toDouble(j['protein']),
      carbs: _toDouble(j['carbs']),
      fat: _toDouble(j['fat']),
    );
  }
}

class DailySummaryResponse {
  DailySummaryResponse({
    required this.date,
    required this.totals,
    required this.meals,
  });

  final String? date;
  final MealTotals totals;
  final List<MealSummaryRow> meals;

  factory DailySummaryResponse.fromJson(Map<String, dynamic> j) {
    final rawMeals = j['meals'] as List<dynamic>? ?? [];
    return DailySummaryResponse(
      date: j['date']?.toString(),
      totals: MealTotals.fromJson(j['totals'] as Map<String, dynamic>?),
      meals: rawMeals
          .map((e) => MealSummaryRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MealItemResponse {
  MealItemResponse({
    required this.id,
    required this.mealId,
    required this.foodId,
    required this.dishId,
    required this.foodName,
    required this.dishName,
    required this.grams,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final int? id;
  final int? mealId;
  final int? foodId;
  final int? dishId;
  final String? foodName;
  final String? dishName;
  final double? grams;
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;

  factory MealItemResponse.fromJson(Map<String, dynamic> j) {
    return MealItemResponse(
      id: _toInt(j['id']),
      mealId: _toInt(j['mealId']),
      foodId: _toInt(j['foodId']),
      dishId: _toInt(j['dishId']),
      foodName: j['foodName']?.toString(),
      dishName: j['dishName']?.toString(),
      grams: _toDouble(j['grams']),
      calories: _toDouble(j['calories']),
      protein: _toDouble(j['protein']),
      carbs: _toDouble(j['carbs']),
      fat: _toDouble(j['fat']),
    );
  }
}

class MealResponse {
  MealResponse({
    required this.id,
    required this.mealType,
    required this.mealDate,
    required this.items,
    required this.totals,
  });

  final int? id;
  final String? mealType;
  final String? mealDate;
  final List<MealItemResponse> items;
  final MealTotals? totals;

  factory MealResponse.fromJson(Map<String, dynamic> j) {
    final rawItems = j['items'] as List<dynamic>? ?? [];
    return MealResponse(
      id: _toInt(j['id']),
      mealType: j['mealType']?.toString(),
      mealDate: j['mealDate']?.toString(),
      items: rawItems
          .map((e) => MealItemResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      totals: j['totals'] != null
          ? MealTotals.fromJson(j['totals'] as Map<String, dynamic>)
          : null,
    );
  }
}

class FoodsResponse {
  FoodsResponse({
    required this.id,
    required this.name,
    required this.brand,
    required this.barcode,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    required this.source,
  });

  final int? id;
  final String? name;
  final String? brand;
  final String? barcode;
  final double? caloriesPer100g;
  final double? proteinPer100g;
  final double? carbsPer100g;
  final double? fatPer100g;
  final String? source;

  factory FoodsResponse.fromJson(Map<String, dynamic> j) {
    return FoodsResponse(
      id: _toInt(j['id']),
      name: j['name']?.toString(),
      brand: j['brand']?.toString(),
      barcode: j['barcode']?.toString(),
      caloriesPer100g: _toDouble(j['caloriesPer100g']),
      proteinPer100g: _toDouble(j['proteinPer100g']),
      carbsPer100g: _toDouble(j['carbsPer100g']),
      fatPer100g: _toDouble(j['fatPer100g']),
      source: j['source']?.toString(),
    );
  }
}

class DishIngredientLine {
  DishIngredientLine({
    required this.foodId,
    required this.foodName,
    required this.grams,
  });

  final int? foodId;
  final String? foodName;
  final double? grams;

  factory DishIngredientLine.fromJson(Map<String, dynamic> j) {
    return DishIngredientLine(
      foodId: _toInt(j['foodId']),
      foodName: j['foodName']?.toString(),
      grams: _toDouble(j['grams']),
    );
  }
}

class DishResponse {
  DishResponse({
    required this.id,
    required this.name,
    required this.description,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.totalGrams,
    required this.ingredients,
  });

  final int? id;
  final String? name;
  final String? description;
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? totalGrams;
  final List<DishIngredientLine> ingredients;

  factory DishResponse.fromJson(Map<String, dynamic> j) {
    final rawIng = j['ingredients'] as List<dynamic>? ?? [];
    return DishResponse(
      id: _toInt(j['id']),
      name: j['name']?.toString(),
      description: j['description']?.toString(),
      calories: _toDouble(j['calories']),
      protein: _toDouble(j['protein']),
      carbs: _toDouble(j['carbs']),
      fat: _toDouble(j['fat']),
      totalGrams: _toDouble(j['totalGrams']),
      ingredients: rawIng
          .map((e) => DishIngredientLine.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class BodyProgressResponse {
  BodyProgressResponse({
    required this.id,
    required this.weightKg,
    required this.bodyFatPercent,
    required this.muscleMassKg,
    required this.recordedAt,
  });

  final int? id;
  final double? weightKg;
  final double? bodyFatPercent;
  final double? muscleMassKg;
  final String? recordedAt;

  factory BodyProgressResponse.fromJson(Map<String, dynamic> j) {
    return BodyProgressResponse(
      id: _toInt(j['id']),
      weightKg: _toDouble(j['weightKg']),
      bodyFatPercent: _toDouble(j['bodyFatPercent']),
      muscleMassKg: _toDouble(j['muscleMassKg']),
      recordedAt: j['recordedAt']?.toString(),
    );
  }
}

class NutritionGoalResponse {
  NutritionGoalResponse({
    required this.id,
    required this.goalType,
    required this.dailyCalories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.startDate,
    required this.endDate,
  });

  final int? id;
  final String? goalType;
  final int? dailyCalories;
  final int? proteinG;
  final int? carbsG;
  final int? fatG;
  final String? startDate;
  final String? endDate;

  factory NutritionGoalResponse.fromJson(Map<String, dynamic> j) {
    return NutritionGoalResponse(
      id: _toInt(j['id']),
      goalType: j['goalType']?.toString(),
      dailyCalories: _toInt(j['dailyCalories']),
      proteinG: _toInt(j['proteinG']),
      carbsG: _toInt(j['carbsG']),
      fatG: _toInt(j['fatG']),
      startDate: j['startDate']?.toString(),
      endDate: j['endDate']?.toString(),
    );
  }
}

DateTime? _parseIsoDate(dynamic v) {
  if (v == null) return null;
  final s = v.toString();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s);
}

/// Matches backend [com.example...ActivityLevel].
enum ActivityLevel {
  low,
  moderate,
  high;

  static ActivityLevel? fromApi(String? s) {
    if (s == null || s.isEmpty) return null;
    switch (s.toUpperCase()) {
      case 'LOW':
        return ActivityLevel.low;
      case 'MODERATE':
        return ActivityLevel.moderate;
      case 'HIGH':
        return ActivityLevel.high;
      default:
        return null;
    }
  }

  String toApi() {
    switch (this) {
      case ActivityLevel.low:
        return 'LOW';
      case ActivityLevel.moderate:
        return 'MODERATE';
      case ActivityLevel.high:
        return 'HIGH';
    }
  }

  String get labelEs {
    switch (this) {
      case ActivityLevel.low:
        return 'Baja';
      case ActivityLevel.moderate:
        return 'Moderada';
      case ActivityLevel.high:
        return 'Alta';
    }
  }
}

class UserInfoResponse {
  UserInfoResponse({
    required this.id,
    required this.activityLevel,
    required this.birthDate,
    required this.heightCm,
    required this.createdAt,
  });

  final int? id;
  final ActivityLevel? activityLevel;
  final DateTime? birthDate;
  final double? heightCm;
  final DateTime? createdAt;

  factory UserInfoResponse.fromJson(Map<String, dynamic> j) {
    return UserInfoResponse(
      id: _toInt(j['id']),
      activityLevel: ActivityLevel.fromApi(j['activityLevel']?.toString()),
      birthDate: _parseIsoDate(j['birthDate']),
      heightCm: _toDouble(j['heightCm']),
      createdAt: _parseIsoDate(j['createdAt']),
    );
  }
}
