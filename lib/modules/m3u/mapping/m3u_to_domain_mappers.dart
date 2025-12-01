// M3uToDomainMappers
// Maps M3U entries to domain models (Channel, VodItem).

import '../../core/models/base_models.dart';
import '../parsing/m3u_parser.dart';

/// Mapper class for converting M3U entries to domain models
class M3uToDomainMappers {
  M3uToDomainMappers._();

  /// Map M3U entry to DomainChannel
  static DomainChannel mapToChannel(M3uEntry entry, {String? id}) {
    return DomainChannel(
      id: id ?? entry.tvgId ?? _generateId(entry),
      name: entry.name,
      streamUrl: entry.url,
      logoUrl: entry.tvgLogo,
      groupTitle: entry.groupTitle,
      categoryId: entry.groupTitle,
      type: _mapContentType(entry.contentType),
      metadata: entry.attributes.isNotEmpty ? entry.attributes : null,
    );
  }

  /// Map M3U entry to VodItem (for movies)
  static VodItem mapToVodItem(M3uEntry entry, {String? id}) {
    return VodItem(
      id: id ?? entry.tvgId ?? _generateId(entry),
      name: entry.name,
      streamUrl: entry.url,
      posterUrl: entry.tvgLogo,
      categoryId: entry.groupTitle,
      type: _mapContentType(entry.contentType),
      metadata: entry.attributes.isNotEmpty ? entry.attributes : null,
    );
  }

  /// Map list of M3U entries to channels
  static List<DomainChannel> mapToChannels(List<M3uEntry> entries) {
    return entries.asMap().entries.map((e) {
      return mapToChannel(e.value, id: e.key.toString());
    }).toList();
  }

  /// Map list of M3U entries to VodItems
  static List<VodItem> mapToVodItems(List<M3uEntry> entries) {
    return entries.asMap().entries.map((e) {
      return mapToVodItem(e.value, id: e.key.toString());
    }).toList();
  }

  /// Filter and map entries by content type
  static List<DomainChannel> mapLiveChannels(List<M3uEntry> entries) {
    return entries
        .where((e) => e.contentType == 'live')
        .toList()
        .asMap()
        .entries
        .map((e) => mapToChannel(e.value, id: 'live_${e.key}'))
        .toList();
  }

  /// Filter and map movie entries
  static List<VodItem> mapMovies(List<M3uEntry> entries) {
    return entries
        .where((e) => e.contentType == 'movie')
        .toList()
        .asMap()
        .entries
        .map((e) => mapToVodItem(e.value, id: 'movie_${e.key}'))
        .toList();
  }

  /// Extract unique categories from entries
  static List<DomainCategory> extractCategories(List<M3uEntry> entries) {
    final categoryMap = <String, int>{};

    for (final entry in entries) {
      final group = entry.groupTitle ?? 'Uncategorized';
      categoryMap[group] = (categoryMap[group] ?? 0) + 1;
    }

    return categoryMap.entries.map((e) {
      return DomainCategory(
        id: e.key.toLowerCase().replaceAll(' ', '_'),
        name: e.key,
        channelCount: e.value,
      );
    }).toList();
  }

  static ContentType _mapContentType(String type) {
    switch (type) {
      case 'movie':
        return ContentType.movie;
      case 'series':
        return ContentType.series;
      default:
        return ContentType.live;
    }
  }

  static String _generateId(M3uEntry entry) {
    return entry.url.hashCode.abs().toString();
  }
}
