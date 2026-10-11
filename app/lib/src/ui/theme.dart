import 'package:flutter/material.dart';

/// The Messenger look: a blue accent, flat surfaces, large rounded bubbles.
///
/// Colours are derived from one seed so light and dark stay in step, and the
/// handful of chat-specific colours (own bubble, other bubble, timestamps) are
/// collected here rather than sprinkled through the widgets.
class RatatoskTheme {
  const RatatoskTheme._();

  static const seed = Color(0xFF0084FF);

  /// A slightly lighter blue for dark mode, where the full-strength accent is
  /// heavy against a dark surface but still has to carry white text.
  static const _darkAccent = Color(0xFF3D9BFF);
  static const _bubbleRadius = Radius.circular(18);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    // `fromSeed` maps the seed onto Material 3's tonal palette, which turns a
    // vivid blue into a muted one. The rest of the tonal palette is welcome, but
    // the accent itself must be the actual colour: message bubbles use it too,
    // and buttons in a different blue than the bubbles read as a mistake.
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness).copyWith(
      primary: isDark ? _darkAccent : seed,
      onPrimary: Colors.white,
      primaryContainer: isDark ? const Color(0xFF10365C) : const Color(0xFFD6E9FF),
      onPrimaryContainer: isDark ? const Color(0xFFCFE4FF) : const Color(0xFF00325C),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF242526) : Colors.white,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB),
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      extensions: [
        ChatColors(
          ownBubble: isDark ? _darkAccent : seed,
          ownText: Colors.white,
          otherBubble: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB),
          otherText: isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505),
          timestamp: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
          bubbleRadius: _bubbleRadius,
        ),
      ],
    );
  }

  /// The chat colours a `ThemeExtension` exposes, so widgets read them from the
  /// theme instead of hardcoding hex values.
  static ChatColors of(BuildContext context) =>
      Theme.of(context).extension<ChatColors>() ?? ChatColors.fallback;
}

/// Colors specific to chat bubbles and their metadata.
@immutable
class ChatColors extends ThemeExtension<ChatColors> {
  const ChatColors({
    required this.ownBubble,
    required this.ownText,
    required this.otherBubble,
    required this.otherText,
    required this.timestamp,
    required this.bubbleRadius,
  });

  final Color ownBubble;
  final Color ownText;
  final Color otherBubble;
  final Color otherText;
  final Color timestamp;
  final Radius bubbleRadius;

  static const fallback = ChatColors(
    ownBubble: RatatoskTheme.seed,
    ownText: Colors.white,
    otherBubble: Color(0xFFE4E6EB),
    otherText: Color(0xFF050505),
    timestamp: Color(0xFF65676B),
    bubbleRadius: Radius.circular(18),
  );

  @override
  ChatColors copyWith({
    Color? ownBubble,
    Color? ownText,
    Color? otherBubble,
    Color? otherText,
    Color? timestamp,
    Radius? bubbleRadius,
  }) =>
      ChatColors(
        ownBubble: ownBubble ?? this.ownBubble,
        ownText: ownText ?? this.ownText,
        otherBubble: otherBubble ?? this.otherBubble,
        otherText: otherText ?? this.otherText,
        timestamp: timestamp ?? this.timestamp,
        bubbleRadius: bubbleRadius ?? this.bubbleRadius,
      );

  @override
  ChatColors lerp(ThemeExtension<ChatColors>? other, double t) {
    if (other is! ChatColors) return this;
    return ChatColors(
      ownBubble: Color.lerp(ownBubble, other.ownBubble, t)!,
      ownText: Color.lerp(ownText, other.ownText, t)!,
      otherBubble: Color.lerp(otherBubble, other.otherBubble, t)!,
      otherText: Color.lerp(otherText, other.otherText, t)!,
      timestamp: Color.lerp(timestamp, other.timestamp, t)!,
      bubbleRadius: Radius.lerp(bubbleRadius, other.bubbleRadius, t)!,
    );
  }
}
