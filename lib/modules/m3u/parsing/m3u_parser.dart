// M3uParser
// Parses M3U/M3U8 playlist content and extracts channel information.

import '../../core/logging/app_logger.dart';

/// Parsed M3U entry
class M3uEntry {
  final String name;
  final String url;
  final String? tvgId;
  final String? tvgName;
  final String? tvgLogo;
  final String? groupTitle;
  final int duration;
  final Map<String, String> attributes;

  const M3uEntry({
    required this.name,
    required this.url,
    this.tvgId,
    this.tvgName,
    this.tvgLogo,
    this.groupTitle,
    this.duration = -1,
    this.attributes = const {},
  });

  /// Get content type based on URL and group
  String get contentType {
    final lowerUrl = url.toLowerCase();
    final lowerGroup = groupTitle?.toLowerCase() ?? '';

    if (lowerGroup.contains('movie') ||
        lowerGroup.contains('film') ||
        lowerUrl.contains('/movie/')) {
      return 'movie';
    }
    if (lowerGroup.contains('series') ||
        lowerGroup.contains('show') ||
        lowerUrl.contains('/series/')) {
      return 'series';
    }
    return 'live';
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'tvg_id': tvgId,
      'tvg_name': tvgName,
      'tvg_logo': tvgLogo,
      'group_title': groupTitle,
      'duration': duration,
      'attributes': attributes,
      'content_type': contentType,
    };
  }
}

/// M3U parser interface
abstract class IM3uParser {
  /// Parse M3U content and return list of entries
  List<M3uEntry> parse(String content);

  /// Validate M3U content
  bool isValid(String content);
}

/// M3U parser implementation
class M3uParser implements IM3uParser {
  /// M3U header tags
  static const String m3uHeader = '#EXTM3U';
  static const String extInf = '#EXTINF';
  static const String extGrp = '#EXTGRP';
  static const String extVlcOpt = '#EXTVLCOPT';

  @override
  List<M3uEntry> parse(String content) {
    if (!isValid(content)) {
      moduleLogger.warning('Invalid M3U content provided', tag: 'M3uParser');
      return [];
    }

    final entries = <M3uEntry>[];
    final lines = content.split('\n');

    String? currentName;
    String? currentLogo;
    String? currentGroup;
    String? currentId;
    int currentDuration = -1;
    Map<String, String> currentAttributes = {};

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.isEmpty || line == m3uHeader) {
        continue;
      }

      if (line.startsWith(extInf)) {
        // Parse EXTINF line
        final parsed = _parseExtInf(line);
        currentName = parsed['name'];
        currentLogo = parsed['tvg-logo'] ?? parsed['logo'];
        currentGroup = parsed['group-title'];
        currentId = parsed['tvg-id'] ?? parsed['channel-id'];
        currentDuration = int.tryParse(parsed['duration'] ?? '') ?? -1;

        // Extract all attributes
        currentAttributes = Map.from(parsed)
          ..remove('name')
          ..remove('duration');
      } else if (line.startsWith(extGrp)) {
        // Parse EXTGRP line (group override)
        currentGroup = line.substring(extGrp.length + 1).trim();
      } else if (!line.startsWith('#') && currentName != null) {
        // This is a URL line
        try {
          final uri = Uri.tryParse(line);
          if (uri != null && uri.hasScheme) {
            entries.add(
              M3uEntry(
                name: currentName,
                url: line,
                tvgId: currentId,
                tvgName: currentAttributes['tvg-name'],
                tvgLogo: currentLogo,
                groupTitle: currentGroup,
                duration: currentDuration,
                attributes: currentAttributes,
              ),
            );
          }
        } catch (e) {
          moduleLogger.warning(
            'Failed to parse URL: $line',
            tag: 'M3uParser',
            error: e,
          );
        }

        // Reset for next entry
        currentName = null;
        currentLogo = null;
        currentGroup = null;
        currentId = null;
        currentDuration = -1;
        currentAttributes = {};
      }
    }

    moduleLogger.info(
      'Parsed ${entries.length} entries from M3U',
      tag: 'M3uParser',
    );
    return entries;
  }

  @override
  bool isValid(String content) {
    final trimmed = content.trim();
    return trimmed.startsWith(m3uHeader) || trimmed.contains(extInf);
  }

  /// Parse EXTINF line and extract attributes
  Map<String, String?> _parseExtInf(String line) {
    final result = <String, String?>{};

    // Extract duration (number after #EXTINF:)
    final durationMatch = RegExp(r'#EXTINF:\s*(-?\d+)').firstMatch(line);
    if (durationMatch != null) {
      result['duration'] = durationMatch.group(1);
    }

    // Extract the name (after the last comma)
    final lastCommaIndex = line.lastIndexOf(',');
    if (lastCommaIndex != -1) {
      result['name'] = line.substring(lastCommaIndex + 1).trim();
    }

    // Extract attributes using regex
    final attributeRegex = RegExp(r'(\w[\w-]*)="([^"]*)"');
    final matches = attributeRegex.allMatches(line);

    for (final match in matches) {
      final key = match.group(1)?.toLowerCase();
      final value = match.group(2);
      if (key != null) {
        result[key] = value;
      }
    }

    return result;
  }
}
