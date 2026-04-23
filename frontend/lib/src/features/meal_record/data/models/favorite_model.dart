import 'menu_model.dart';

class FavoriteModel {
  final String id;
  final MenuModel menu;

  const FavoriteModel({required this.id, required this.menu});

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: json['id'].toString(),
      menu: MenuModel.fromJson(json['menu'] as Map<String, dynamic>),
    );
  }
}