/// Centralized API configuration.
///
/// Uses `--dart-define=API_BASE_URL=...` when provided, otherwise falls
/// back to the production Vercel URL. This removes hardcoded URLs scattered
/// across UI files and makes backend migration (pagination, staging) trivial.
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://e-venues.vercel.app',
  );

  static const Duration timeout = Duration(seconds: 12);

  /// Public host portal (venue onboarding web app). Overridable with
  /// `--dart-define=HOST_PORTAL_URL=...` for staging.
  static const String hostPortalUrl = String.fromEnvironment(
    'HOST_PORTAL_URL',
    defaultValue: 'https://haven-venue.vercel.app/login',
  );

  /// Deep link into the portal's onboarding, carrying the account email
  /// so the web login can prefill it. Token is NEVER put in the URL.
  static Uri hostOnboarding({String email = ''}) {
    final query = <String, String>{'next': '/venues/new'};
    if (email.isNotEmpty) query['email'] = email;
    return Uri.parse(hostPortalUrl).replace(queryParameters: query);
  }

  static Uri login() => Uri.parse('$baseUrl/api/login');
  static Uri register() => Uri.parse('$baseUrl/api/register');
  static Uri bookings() => Uri.parse('$baseUrl/api/bookings');

  static Uri myBookings({String? filter, int? page, int? limit}) {
    final query = <String, String>{};
    if (filter != null && filter.isNotEmpty) query['filter'] = filter;
    if (page != null) query['page'] = '$page';
    if (limit != null) query['limit'] = '$limit';
    return Uri.parse('$baseUrl/api/bookings/mine').replace(
      queryParameters: query.isEmpty ? null : query,
    );
  }

  static Uri cancelBooking(String id) =>
      Uri.parse('$baseUrl/api/bookings/$id/cancel');

  static Uri venueAvailability(int id,
      {required String from, required String to}) {
    return Uri.parse('$baseUrl/api/fetch/venues/$id/availability')
        .replace(queryParameters: {'from': from, 'to': to});
  }
  static Uri venueList({
    int? page,
    int? limit,
    String? search,
    String? venueType,
    String? eventType,
    double? minLat,
    double? maxLat,
    double? minLng,
    double? maxLng,
  }) {
    final query = <String, String>{};
    if (page != null) query['page'] = '$page';
    if (limit != null) query['limit'] = '$limit';
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (venueType != null && venueType.isNotEmpty && venueType != 'All') {
      query['venue_type'] = venueType;
    }
    if (eventType != null &&
        eventType.isNotEmpty &&
        eventType != 'Any event') {
      query['event_type'] = eventType;
    }
    if (minLat != null) query['minLat'] = '$minLat';
    if (maxLat != null) query['maxLat'] = '$maxLat';
    if (minLng != null) query['minLng'] = '$minLng';
    if (maxLng != null) query['maxLng'] = '$maxLng';
    return Uri.parse('$baseUrl/api/fetch/venuelist').replace(
      queryParameters: query.isEmpty ? null : query,
    );
  }

  static Uri venueDetail(int id) =>
      Uri.parse('$baseUrl/api/fetch/venues/$id');
}
