import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String? profileImageUrl;
  final double radius;
  final String? nickname;

  const ProfileAvatar({
    super.key,
    this.profileImageUrl,
    this.radius = 20,
    this.nickname,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = profileImageUrl != null && profileImageUrl!.isNotEmpty;
    final initial = (nickname != null && nickname!.isNotEmpty) ? nickname![0] : null;

    return CircleAvatar(
      radius: radius,
      backgroundImage: hasImage
          ? CachedNetworkImageProvider(profileImageUrl!)
          : null,
      backgroundColor: hasImage
          ? null
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      child: hasImage
          ? null
          : (initial != null
              ? Text(
                  initial,
                  style: TextStyle(
                    fontSize: radius * 0.9,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
              : Icon(Icons.person, size: radius)),
    );
  }
}
