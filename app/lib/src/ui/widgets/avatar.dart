import 'package:flutter/material.dart';

import '../../gen/ratatosk/v1/common.pb.dart';

/// A circular avatar: the picture when there is one, initials on the accent
/// colour otherwise. The colour comes from the server, so the same person keeps
/// the same colour in every conversation.
class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.color,
    this.id,
    this.size = 48,
    this.presence,
  });

  /// Builds an avatar for a user.
  factory Avatar.user(
    User user, {
    Key? key,
    double size = 48,
    Presence? presence,
    String Function(String path)? resolveUrl,
  }) {
    return Avatar(
      key: key,
      name: user.displayName.isEmpty ? user.username : user.displayName,
      imageUrl: user.avatarUrl.isEmpty || resolveUrl == null ? null : resolveUrl(user.avatarUrl),
      color: user.accentColor,
      id: user.id,
      size: size,
      presence: presence,
    );
  }

  final String name;

  /// An already-resolved URL (with the session token attached, if needed).
  final String? imageUrl;
  final String? color;
  final String? id;

  /// Only drawn when [presence] is given, and only for one-to-one avatars.
  final Presence? presence;

  final double size;

  @override
  Widget build(BuildContext context) {
    final background = _parseColor(color, id ?? name);
    final initials = _initials(name);
    final image = imageUrl;

    Widget circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: image != null && image.isNotEmpty
          ? Image.network(
              image,
              fit: BoxFit.cover,
              // A broken picture must not leave a hole in the layout.
              errorBuilder: (_, __, ___) => _initialsLabel(initials),
            )
          : _initialsLabel(initials),
    );

    final presenceValue = presence;
    if (presenceValue == null ||
        presenceValue == Presence.PRESENCE_UNSPECIFIED ||
        presenceValue == Presence.PRESENCE_OFFLINE) {
      return circle;
    }
    final dotColor = presenceValue == Presence.PRESENCE_ONLINE
        ? const Color(0xFF31A24C)
        : const Color(0xFFF7B928);
    circle = Stack(
      clipBehavior: Clip.none,
      children: [
        circle,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: size * 0.28,
            height: size * 0.28,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: size * 0.05,
              ),
            ),
          ),
        ),
      ],
    );
    return circle;
  }

  Widget _initialsLabel(String initials) => Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.38,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return _firstChar(parts.first).toUpperCase();
    return (_firstChar(parts.first) + _firstChar(parts.last)).toUpperCase();
  }

  /// The first character of a string, in code points rather than UTF-16 units,
  /// so an emoji or an accented letter is not cut in half.
  static String _firstChar(String value) {
    if (value.isEmpty) return '?';
    return String.fromCharCode(value.runes.first);
  }

  static Color _parseColor(String? hex, String fallbackSeed) {
    final value = hex?.replaceFirst('#', '');
    if (value != null && (value.length == 6 || value.length == 8)) {
      final parsed = int.tryParse(value, radix: 16);
      if (parsed != null) {
        return Color(value.length == 6 ? 0xFF000000 | parsed : parsed);
      }
    }
    // No colour from the server: derive a stable one from the id, so the same
    // person does not change colour between rebuilds.
    final palette = [
      const Color(0xFF1DA1F2),
      const Color(0xFF17BF63),
      const Color(0xFFF45D22),
      const Color(0xFF794BC4),
      const Color(0xFFE0245E),
      const Color(0xFF00B7C2),
    ];
    return palette[fallbackSeed.hashCode.abs() % palette.length];
  }
}
