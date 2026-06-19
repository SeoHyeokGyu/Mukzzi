import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String? profileImageUrl;
  final double radius;

  const ProfileAvatar({
    super.key,
    this.profileImageUrl,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = profileImageUrl != null && profileImageUrl!.isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundImage: hasImage
          ? CachedNetworkImageProvider(profileImageUrl!)
          : null,
      backgroundColor: hasImage
          ? null
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      child: hasImage ? null : Icon(Icons.person, size: radius),
    );
  }
}
