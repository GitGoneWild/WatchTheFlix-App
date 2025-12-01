// Repository Interfaces
// Defines interfaces for data access across all modules.
// Implementations can be swapped without affecting dependent code.

import 'api_result.dart';
import 'base_models.dart';

/// Profile repository interface
abstract class IProfileRepository {
  /// Get all profiles
  Future<ApiResult<List<Profile>>> getProfiles();

  /// Get a profile by ID
  Future<ApiResult<Profile>> getProfile(String id);

  /// Add a new profile
  Future<ApiResult<Profile>> addProfile(Profile profile);

  /// Update an existing profile
  Future<ApiResult<Profile>> updateProfile(Profile profile);

  /// Delete a profile
  Future<ApiResult<void>> deleteProfile(String id);

  /// Set the active profile
  Future<ApiResult<void>> setActiveProfile(String id);

  /// Get the active profile
  Future<ApiResult<Profile?>> getActiveProfile();
}

/// Channel repository interface
abstract class IChannelRepository {
  /// Get all channels for a profile
  Future<ApiResult<List<DomainChannel>>> getChannels(String profileId);

  /// Get channels by category
  Future<ApiResult<List<DomainChannel>>> getChannelsByCategory(
    String profileId,
    String categoryId,
  );

  /// Get a channel by ID
  Future<ApiResult<DomainChannel>> getChannel(String profileId, String channelId);

  /// Search channels
  Future<ApiResult<List<DomainChannel>>> searchChannels(
    String profileId,
    String query,
  );

  /// Get favorite channels
  Future<ApiResult<List<DomainChannel>>> getFavorites();

  /// Add to favorites
  Future<ApiResult<void>> addFavorite(DomainChannel channel);

  /// Remove from favorites
  Future<ApiResult<void>> removeFavorite(String channelId);

  /// Get recent channels
  Future<ApiResult<List<DomainChannel>>> getRecentChannels();

  /// Add to recent channels
  Future<ApiResult<void>> addRecentChannel(DomainChannel channel);

  /// Refresh channels from source
  Future<ApiResult<List<DomainChannel>>> refreshChannels(String profileId);
}

/// VOD (Video on Demand) repository interface
abstract class IVodRepository {
  /// Get all movies for a profile
  Future<ApiResult<List<VodItem>>> getMovies(String profileId);

  /// Get movies by category
  Future<ApiResult<List<VodItem>>> getMoviesByCategory(
    String profileId,
    String categoryId,
  );

  /// Get a movie by ID
  Future<ApiResult<VodItem>> getMovie(String profileId, String movieId);

  /// Search movies
  Future<ApiResult<List<VodItem>>> searchMovies(
    String profileId,
    String query,
  );

  /// Refresh movies from source
  Future<ApiResult<List<VodItem>>> refreshMovies(String profileId);
}

/// Series repository interface
abstract class ISeriesRepository {
  /// Get all series for a profile
  Future<ApiResult<List<DomainSeries>>> getSeries(String profileId);

  /// Get series by category
  Future<ApiResult<List<DomainSeries>>> getSeriesByCategory(
    String profileId,
    String categoryId,
  );

  /// Get series details with seasons and episodes
  Future<ApiResult<DomainSeries>> getSeriesDetails(
    String profileId,
    String seriesId,
  );

  /// Search series
  Future<ApiResult<List<DomainSeries>>> searchSeries(
    String profileId,
    String query,
  );

  /// Refresh series from source
  Future<ApiResult<List<DomainSeries>>> refreshSeries(String profileId);
}

/// Category repository interface
abstract class ICategoryRepository {
  /// Get live TV categories
  Future<ApiResult<List<DomainCategory>>> getLiveCategories(String profileId);

  /// Get movie categories
  Future<ApiResult<List<DomainCategory>>> getMovieCategories(String profileId);

  /// Get series categories
  Future<ApiResult<List<DomainCategory>>> getSeriesCategories(String profileId);

  /// Refresh categories from source
  Future<ApiResult<void>> refreshCategories(String profileId);
}

/// EPG (Electronic Program Guide) repository interface
abstract class IEpgRepository {
  /// Get EPG for a channel
  Future<ApiResult<List<EpgInfo>>> getChannelEpg(
    String profileId,
    String channelId,
  );

  /// Get EPG for all channels
  Future<ApiResult<Map<String, List<EpgInfo>>>> getAllEpg(String profileId);

  /// Get current/next program for a channel
  Future<ApiResult<EpgInfo?>> getCurrentProgram(
    String profileId,
    String channelId,
  );

  /// Refresh EPG data
  Future<ApiResult<void>> refreshEpg(String profileId);
}

/// Auth provider interface
abstract class IAuthProvider {
  /// Authenticate with credentials
  Future<ApiResult<bool>> authenticate(XtreamCredentialsModel credentials);

  /// Check if authenticated
  Future<ApiResult<bool>> isAuthenticated(String profileId);

  /// Logout
  Future<ApiResult<void>> logout(String profileId);
}
