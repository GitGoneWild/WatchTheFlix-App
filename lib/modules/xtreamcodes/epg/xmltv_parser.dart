// XMLTV Parser
// Parser for XMLTV EPG data format.

import 'package:xml/xml.dart';

import '../../core/logging/app_logger.dart';
import '../../core/models/api_result.dart';
import 'epg_models.dart';

/// XMLTV parser interface
abstract class IXmltvParser {
  /// Parse XMLTV content
  ApiResult<XmltvData> parse(String xmlContent);
}

/// XMLTV parsed data
class XmltvData {
  const XmltvData({
    required this.channels,
    required this.programs,
  });

  final List<EpgChannel> channels;
  final List<EpgProgram> programs;
}

/// XMLTV parser implementation
class XmltvParser implements IXmltvParser {
  @override
  ApiResult<XmltvData> parse(String xmlContent) {
    try {
      moduleLogger.info('Parsing XMLTV data', tag: 'XmltvParser');

      final document = XmlDocument.parse(xmlContent);
      final root = document.findElements('tv').firstOrNull;

      if (root == null) {
        return ApiResult.failure(
          const ApiError(
            type: ApiErrorType.parse,
            message: 'Invalid XMLTV format: missing <tv> root element',
          ),
        );
      }

      final channels = _parseChannels(root);
      final programs = _parsePrograms(root);

      moduleLogger.info(
        'Parsed ${channels.length} channels and ${programs.length} programs',
        tag: 'XmltvParser',
      );

      return ApiResult.success(
        XmltvData(channels: channels, programs: programs),
      );
    } on XmlException catch (e, stackTrace) {
      moduleLogger.error(
        'XML parsing error',
        tag: 'XmltvParser',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(
        ApiError(
          type: ApiErrorType.parse,
          message: 'XML parsing failed: ${e.message}',
        ),
      );
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Unexpected error parsing XMLTV',
        tag: 'XmltvParser',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  /// Parse channel elements
  List<EpgChannel> _parseChannels(XmlElement root) {
    final channelElements = root.findElements('channel');
    final channels = <EpgChannel>[];

    for (final element in channelElements) {
      try {
        final id = element.getAttribute('id');
        if (id == null || id.isEmpty) continue;

        final displayNameElement = element.findElements('display-name').firstOrNull;
        final displayName = displayNameElement?.innerText ?? id;

        final iconElement = element.findElements('icon').firstOrNull;
        final icon = iconElement?.getAttribute('src');

        channels.add(
          EpgChannel(
            id: id,
            displayName: displayName,
            icon: icon,
          ),
        );
      } catch (e) {
        moduleLogger.warning(
          'Failed to parse channel',
          tag: 'XmltvParser',
          error: e,
        );
      }
    }

    return channels;
  }

  /// Parse programme elements
  List<EpgProgram> _parsePrograms(XmlElement root) {
    final programElements = root.findElements('programme');
    final programs = <EpgProgram>[];

    for (final element in programElements) {
      try {
        final channelId = element.getAttribute('channel');
        final startStr = element.getAttribute('start');
        final stopStr = element.getAttribute('stop');

        if (channelId == null || startStr == null || stopStr == null) {
          continue;
        }

        final start = _parseXmltvTime(startStr);
        final stop = _parseXmltvTime(stopStr);

        if (start == null || stop == null) continue;

        final titleElement = element.findElements('title').firstOrNull;
        final title = titleElement?.innerText ?? '';

        if (title.isEmpty) continue;

        final descElement = element.findElements('desc').firstOrNull;
        final description = descElement?.innerText;

        final categoryElement = element.findElements('category').firstOrNull;
        final category = categoryElement?.innerText;

        final iconElement = element.findElements('icon').firstOrNull;
        final icon = iconElement?.getAttribute('src');

        programs.add(
          EpgProgram(
            channelId: channelId,
            start: start,
            stop: stop,
            title: title,
            description: description,
            category: category,
            icon: icon,
          ),
        );
      } catch (e) {
        moduleLogger.warning(
          'Failed to parse program',
          tag: 'XmltvParser',
          error: e,
        );
      }
    }

    return programs;
  }

  /// Parse XMLTV timestamp format (YYYYMMDDHHmmss +HHMM)
  DateTime? _parseXmltvTime(String timeStr) {
    try {
      // Remove timezone part for simplicity (format: 20231201120000 +0000)
      final parts = timeStr.split(' ');
      final dateTimeStr = parts[0];

      if (dateTimeStr.length < 14) return null;

      final year = int.parse(dateTimeStr.substring(0, 4));
      final month = int.parse(dateTimeStr.substring(4, 6));
      final day = int.parse(dateTimeStr.substring(6, 8));
      final hour = int.parse(dateTimeStr.substring(8, 10));
      final minute = int.parse(dateTimeStr.substring(10, 12));
      final second = int.parse(dateTimeStr.substring(12, 14));

      var dateTime = DateTime.utc(year, month, day, hour, minute, second);

      // Handle timezone offset if present
      if (parts.length > 1) {
        final tzStr = parts[1];
        if (tzStr.length >= 5) {
          final sign = tzStr[0] == '+' ? 1 : -1;
          final tzHours = int.tryParse(tzStr.substring(1, 3)) ?? 0;
          final tzMinutes = int.tryParse(tzStr.substring(3, 5)) ?? 0;
          final offset = Duration(hours: sign * tzHours, minutes: sign * tzMinutes);
          dateTime = dateTime.subtract(offset);
        }
      }

      return dateTime.toLocal();
    } catch (e) {
      moduleLogger.warning(
        'Failed to parse time: $timeStr',
        tag: 'XmltvParser',
        error: e,
      );
      return null;
    }
  }
}
