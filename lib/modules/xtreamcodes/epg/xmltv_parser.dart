// XMLTV Parser
// Parses XMLTV format EPG data into domain models.

import 'package:xml/xml.dart';

import '../../core/logging/app_logger.dart';
import 'epg_models.dart';

/// XMLTV Parser for parsing EPG data from XMLTV format.
///
/// XMLTV is a standard format for EPG data with the following structure:
/// ```xml
/// <tv>
///   <channel id="channel1">
///     <display-name>Channel 1</display-name>
///     <icon src="http://..." />
///   </channel>
///   <programme start="20240101120000 +0000" stop="20240101130000 +0000" channel="channel1">
///     <title>Program Title</title>
///     <desc>Description</desc>
///   </programme>
/// </tv>
/// ```
class XmltvParser {
  /// Parse XMLTV content and return EPG data.
  ///
  /// [xmlContent] The raw XMLTV XML content.
  /// [sourceUrl] Optional source URL for reference.
  EpgData parse(String xmlContent, {String? sourceUrl}) {
    try {
      final document = XmlDocument.parse(xmlContent);
      final tvElement = document.findElements('tv').firstOrNull;

      if (tvElement == null) {
        moduleLogger.warning(
          'No <tv> element found in XMLTV content',
          tag: 'XmltvParser',
        );
        return EpgData.empty();
      }

      // Parse channels
      final channels = _parseChannels(tvElement);
      moduleLogger.debug(
        'Parsed ${channels.length} channels from XMLTV',
        tag: 'XmltvParser',
      );

      // Parse programs
      final programs = _parsePrograms(tvElement);
      moduleLogger.debug(
        'Parsed ${programs.values.fold(0, (sum, list) => sum + list.length)} programs from XMLTV',
        tag: 'XmltvParser',
      );

      return EpgData(
        channels: channels,
        programs: programs,
        fetchedAt: DateTime.now().toUtc(),
        sourceUrl: sourceUrl,
      );
    } on XmlParserException catch (e) {
      moduleLogger.error(
        'Failed to parse XMLTV: XML parsing error',
        tag: 'XmltvParser',
        error: e,
      );
      return EpgData.empty();
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to parse XMLTV',
        tag: 'XmltvParser',
        error: e,
        stackTrace: stackTrace,
      );
      return EpgData.empty();
    }
  }

  /// Parse channel elements from XMLTV.
  Map<String, EpgChannel> _parseChannels(XmlElement tvElement) {
    final channels = <String, EpgChannel>{};

    for (final channelElement in tvElement.findElements('channel')) {
      final id = channelElement.getAttribute('id');
      if (id == null || id.isEmpty) continue;

      final displayNames = <String>[];
      for (final nameElement in channelElement.findElements('display-name')) {
        final name = nameElement.innerText.trim();
        if (name.isNotEmpty) {
          displayNames.add(name);
        }
      }

      String? iconUrl;
      final iconElement = channelElement.findElements('icon').firstOrNull;
      if (iconElement != null) {
        iconUrl = iconElement.getAttribute('src');
      }

      channels[id] = EpgChannel.fromXmlData(
        id: id,
        displayNames: displayNames,
        iconUrl: iconUrl,
      );
    }

    return channels;
  }

  /// Parse program elements from XMLTV.
  Map<String, List<EpgProgram>> _parsePrograms(XmlElement tvElement) {
    final programs = <String, List<EpgProgram>>{};

    for (final programElement in tvElement.findElements('programme')) {
      final program = _parseProgram(programElement);
      if (program != null) {
        programs.putIfAbsent(program.channelId, () => []).add(program);
      }
    }

    // Sort programs by start time for each channel
    for (final channelPrograms in programs.values) {
      channelPrograms.sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    return programs;
  }

  /// Parse a single programme element.
  EpgProgram? _parseProgram(XmlElement programElement) {
    final channelId = programElement.getAttribute('channel');
    final startStr = programElement.getAttribute('start');
    final stopStr = programElement.getAttribute('stop');

    if (channelId == null || startStr == null || stopStr == null) {
      return null;
    }

    final startTime = _parseXmltvDateTime(startStr);
    final endTime = _parseXmltvDateTime(stopStr);

    if (startTime == null || endTime == null) {
      moduleLogger.warning(
        'Invalid date format in programme: start=$startStr, stop=$stopStr',
        tag: 'XmltvParser',
      );
      return null;
    }

    // Parse title (required)
    final titleElement = programElement.findElements('title').firstOrNull;
    final title = titleElement?.innerText.trim() ?? '';
    if (title.isEmpty) {
      return null;
    }

    // Parse optional elements
    final descElement = programElement.findElements('desc').firstOrNull;
    final description = descElement?.innerText.trim();

    final subTitleElement = programElement.findElements('sub-title').firstOrNull;
    final subtitle = subTitleElement?.innerText.trim();

    final categoryElement = programElement.findElements('category').firstOrNull;
    final category = categoryElement?.innerText.trim();

    final iconElement = programElement.findElements('icon').firstOrNull;
    final iconUrl = iconElement?.getAttribute('src');

    // Parse episode number (various formats)
    String? episodeNumber;
    final episodeElements = programElement.findElements('episode-num');
    for (final epElement in episodeElements) {
      final system = epElement.getAttribute('system');
      final value = epElement.innerText.trim();
      if (value.isNotEmpty) {
        // Prefer onscreen format for display
        if (system == 'onscreen') {
          episodeNumber = value;
          break;
        }
        episodeNumber ??= value;
      }
    }

    // Parse language
    String? language;
    if (titleElement != null) {
      language = titleElement.getAttribute('lang');
    }

    return EpgProgram(
      channelId: channelId,
      title: title,
      description: description,
      startTime: startTime,
      endTime: endTime,
      category: category,
      language: language,
      episodeNumber: episodeNumber,
      iconUrl: iconUrl,
      subtitle: subtitle,
    );
  }

  /// Parse XMLTV datetime format.
  ///
  /// XMLTV format: "YYYYMMDDHHmmss +ZZZZ" or "YYYYMMDDHHmmss"
  /// Examples:
  /// - "20240115120000 +0000"
  /// - "20240115120000 -0500"
  /// - "20240115120000"
  DateTime? _parseXmltvDateTime(String dateTimeStr) {
    try {
      // Remove any extra whitespace
      dateTimeStr = dateTimeStr.trim();

      // Extract the date part (first 14 characters: YYYYMMDDHHmmss)
      if (dateTimeStr.length < 14) return null;

      final datePart = dateTimeStr.substring(0, 14);
      final year = int.parse(datePart.substring(0, 4));
      final month = int.parse(datePart.substring(4, 6));
      final day = int.parse(datePart.substring(6, 8));
      final hour = int.parse(datePart.substring(8, 10));
      final minute = int.parse(datePart.substring(10, 12));
      final second = int.parse(datePart.substring(12, 14));

      // Parse timezone offset if present
      Duration offset = Duration.zero;
      if (dateTimeStr.length > 14) {
        final tzPart = dateTimeStr.substring(14).trim();
        offset = _parseTimezoneOffset(tzPart);
      }

      // Create UTC datetime
      final localTime = DateTime(year, month, day, hour, minute, second);
      // Subtract offset to get UTC time
      return localTime.toUtc().subtract(offset);
    } catch (e) {
      moduleLogger.warning(
        'Failed to parse XMLTV datetime: $dateTimeStr',
        tag: 'XmltvParser',
        error: e,
      );
      return null;
    }
  }

  /// Parse timezone offset string like "+0500" or "-0330".
  Duration _parseTimezoneOffset(String tzStr) {
    try {
      tzStr = tzStr.trim();
      if (tzStr.isEmpty) return Duration.zero;

      final isNegative = tzStr.startsWith('-');
      tzStr = tzStr.replaceAll(RegExp(r'[+-]'), '');

      // Handle both HHMM and HH:MM formats
      tzStr = tzStr.replaceAll(':', '');

      if (tzStr.length < 4) return Duration.zero;

      final hours = int.parse(tzStr.substring(0, 2));
      final minutes = int.parse(tzStr.substring(2, 4));

      final duration = Duration(hours: hours, minutes: minutes);
      return isNegative ? -duration : duration;
    } catch (e) {
      return Duration.zero;
    }
  }

  /// Validate if content appears to be XMLTV format.
  bool isValidXmltv(String content) {
    final trimmed = content.trim();
    return trimmed.contains('<tv') && trimmed.contains('</tv>');
  }
}
