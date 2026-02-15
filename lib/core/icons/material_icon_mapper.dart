import 'package:flutter/material.dart';

/// Maps persisted Material icon code points to const Icons values.
///
/// This avoids dynamic `IconData(...)` creation, which breaks icon tree-shaking
/// on web release builds.
class MaterialIconMapper {
  const MaterialIconMapper._();

  static IconData fromCodePoint(int codePoint) {
    switch (codePoint) {
      // Folder presets
      case 0xe6c4:
        return Icons.folder_rounded;
      case 0xe335:
        return Icons.book_rounded;
      case 0xe153:
        return Icons.science_rounded;
      case 0xeb7b:
        return Icons.calculate_rounded;
      case 0xe3c9:
        return Icons.language_rounded;
      case 0xee94:
        return Icons.music_note_rounded;
      case 0xf06c:
        return Icons.sports_esports_rounded;
      case 0xea22:
        return Icons.history_edu_rounded;

      // Badge icons
      case 0xe838:
        return Icons.star_rounded;
      case 0xea15:
        return Icons.local_fire_department_rounded;
      case 0xe518:
        return Icons.whatshot_rounded;
      case 0xe8e8:
        return Icons.thumb_up_rounded;
      case 0xf0674:
        return Icons.diamond_rounded;
      case 0xea23:
        return Icons.military_tech_rounded;
      case 0xe8ac:
        return Icons.shield_rounded;
      case 0xeb40:
        return Icons.library_books_rounded;
      case 0xe1b1:
        return Icons.emoji_events_rounded;
      case 0xea3b:
        return Icons.workspace_premium_rounded;
      case 0xe3b0:
        return Icons.photo_camera_rounded;
      case 0xe425:
        return Icons.timer_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}
