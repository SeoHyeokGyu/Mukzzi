import '../../../meal_record/data/models/meal_model.dart';
import '../../../profile/data/models/user_model.dart';

class FeedPost {
  final MealRecord meal;
  final UserModel user;

  const FeedPost({
    required this.meal,
    required this.user,
  });

  factory FeedPost.fromJson(Map<String, dynamic> json) {
    return FeedPost(
      meal: MealRecord.fromJson(json),
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class FeedResponse {
  final List<FeedPost> posts;
  final bool hasNext;
  final String? nextCursor;

  const FeedResponse({
    required this.posts,
    required this.hasNext,
    this.nextCursor,
  });

  factory FeedResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final meals = data['meals'] as List<dynamic>? ?? [];
    return FeedResponse(
      posts: meals.map((e) => FeedPost.fromJson(e as Map<String, dynamic>)).toList(),
      hasNext: data['has_next'] as bool? ?? false,
      nextCursor: data['next_cursor']?.toString(),
    );
  }
}
