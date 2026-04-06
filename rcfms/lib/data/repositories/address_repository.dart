import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Repository for Philippine Address Data (Province -> City -> Barangay)
/// Loads data from `assets/data/locations.json`
class AddressRepository {
  // Static cache to store data in memory across instances
  static final Map<String, Map<String, List<String>>> _addressData = {};
  static bool _hasLoaded = false;

  bool get isLoaded => _hasLoaded;

  /// Loads and parses the JSON data (only once)
  Future<void> initialize() async {
    if (_hasLoaded) return;

    try {
      final String response =
          await rootBundle.loadString('assets/data/locations.json');

      // Use compute to parse JSON in a background isolate to prevent UI freeze
      final Map<String, dynamic> data = await compute(_parseJson, response);

      // Structure: Region -> province_list -> Province -> municipality_list -> City -> barangay_list
      data.forEach((regionKey, regionValue) {
        final provinceList =
            regionValue['province_list'] as Map<String, dynamic>?;

        if (provinceList != null) {
          provinceList.forEach((provinceName, provinceValue) {
            final municipalityList =
                provinceValue['municipality_list'] as Map<String, dynamic>?;

            if (municipalityList != null) {
              final Map<String, List<String>> cities = {};

              municipalityList.forEach((cityName, cityValue) {
                final barangayList =
                    List<String>.from(cityValue['barangay_list'] ?? []);
                barangayList.sort();
                cities[cityName] = barangayList;
              });

              _addressData[provinceName] = cities;
            }
          });
        }
      });
      _hasLoaded = true;
    } catch (e) {
      // debugPrint('Error loading address data: $e');
      // Fallback or empty
    }
  }

  // Static function for compute
  static Map<String, dynamic> _parseJson(String jsonString) {
    return json.decode(jsonString);
  }

  /// Get list of provinces
  List<String> getProvinces() {
    final provinces = _addressData.keys.toList();
    provinces.sort();
    return provinces;
  }

  /// Get list of cities/municipalities for a province
  /// [isCity] logic is approximate as JSON doesn't strictly distinguish city vs municipality types in keys
  /// We will rely on name matching or return all if isCity is null
  List<String> getCities(String province, {bool? isCity}) {
    if (!_addressData.containsKey(province)) return [];

    var locations = _addressData[province]!.keys.toList();

    if (isCity != null) {
      if (isCity) {
        locations = locations
            .where((l) =>
                l.toLowerCase().contains('city') ||
                l == 'Manila' ||
                l == 'Quezon City')
            .toList();
      } else {
        // This filter might be too aggressive if cities don't have "City" in name,
        // but strictly speaking most PH cities do.
        locations = locations
            .where((l) => !l.toLowerCase().contains('city') && l != 'Manila')
            .toList();
      }
    }

    locations.sort();
    return locations;
  }

  /// Get list of barangays for a city
  List<String> getBarangays(String province, String city) {
    if (!_addressData.containsKey(province)) return [];
    if (!_addressData[province]!.containsKey(city)) return [];
    return _addressData[province]![city]!;
  }
}
