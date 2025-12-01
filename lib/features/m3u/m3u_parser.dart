import '../../core/errors/exceptions.dart';
import '../../core/utils/logger.dart';
import '../../data/models/channel_model.dart';

/// M3U Parser interface
abstract class M3UParser {
  /// Parse M3U content
  List<ChannelModel> parse(String content);

  /// Validate M3U content
  bool isValid(String content);
}

/// M3U Parser implementation
class M3UParserImpl implements M3UParser {
  /// M3U header tags
  static const String m3uHeader = '#EXTM3U';
  static const String extInf = '#EXTINF';

  @override
  List<ChannelModel> parse(String content) {
    if (!isValid(content)) {
      throw const ParseException(message: 'Invalid M3U content');
    }

    final channels = <ChannelModel>[];
    final lines = content.split('\n');

    String? currentName;
    String? currentLogo;
    String? currentGroup;
    String? currentId;
    Map<String, dynamic> currentMetadata = {};

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
        currentId = parsed['tvg-id'] ??
            parsed['channel-id'] ??
            DateTime.now().microsecondsSinceEpoch.toString();
        currentMetadata = Map.from(parsed)
          ..remove('name')
          ..remove('tvg-logo')
          ..remove('logo')
          ..remove('group-title')
          ..remove('tvg-id')
          ..remove('channel-id');
      } else if (!line.startsWith('#') && currentName != null) {
        // This is a URL line
        try {
          final uri = Uri.tryParse(line);
          if (uri != null && uri.hasScheme) {
            channels.add(
              ChannelModel(
                id: currentId ?? channels.length.toString(),
                name: currentName,
                streamUrl: line,
                logoUrl: currentLogo,
                groupTitle: currentGroup,
                categoryId: currentGroup,
                type: _determineContentType(line, currentGroup),
                metadata: currentMetadata.isNotEmpty ? currentMetadata : null,
              ),
            );
          }
        } catch (e) {
          AppLogger.warning('Failed to parse channel URL: $line');
        }

        // Reset for next entry
        currentName = null;
        currentLogo = null;
        currentGroup = null;
        currentId = null;
        currentMetadata = {};
      }
    }

    AppLogger.info('Parsed ${channels.length} channels from M3U');
    return channels;
  }

  @override
  bool isValid(String content) {
    final trimmed = content.trim();
    return trimmed.startsWith(m3uHeader) || trimmed.contains(extInf);
  }

  /// Parse EXTINF line and extract attributes
  Map<String, String?> _parseExtInf(String line) {
    final result = <String, String?>{};

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

  /// Determine content type based on URL and group
  String _determineContentType(String url, String? group) {
    final lowerUrl = url.toLowerCase();
    final lowerGroup = group?.toLowerCase() ?? '';

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
}
