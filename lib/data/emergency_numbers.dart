class EmergencyEntry {
  final String service;
  final String number;
  final String icon;

  const EmergencyEntry(this.service, this.number, this.icon);
}

class CountryEmergencyInfo {
  final String country;
  final List<String> matchKeywords;
  final List<EmergencyEntry> entries;
  final String embassyHint;

  const CountryEmergencyInfo({
    required this.country,
    required this.matchKeywords,
    required this.entries,
    this.embassyHint = '',
  });
}

/// Offline, pre-loaded directory of emergency numbers by destination.
/// Matched loosely against the trip's destination text; falls back to a
/// universal set (112/911) plus generic guidance when no match is found.
const List<CountryEmergencyInfo> kEmergencyDirectory = [
  CountryEmergencyInfo(
    country: 'United States',
    matchKeywords: ['usa', 'united states', 'america', 'new york', 'los angeles', 'chicago', 'miami', 'san francisco'],
    entries: [
      EmergencyEntry('Police / Fire / Ambulance', '911', '🚨'),
      EmergencyEntry('Poison Control', '1-800-222-1222', '☎️'),
    ],
    embassyHint: 'Contact your home country\'s embassy or consulate in Washington, D.C.',
  ),
  CountryEmergencyInfo(
    country: 'India',
    matchKeywords: ['india', 'mumbai', 'delhi', 'bangalore', 'bengaluru', 'goa', 'chennai', 'kolkata', 'jaipur', 'hyderabad'],
    entries: [
      EmergencyEntry('All-in-one Emergency', '112', '🚨'),
      EmergencyEntry('Police', '100', '👮'),
      EmergencyEntry('Ambulance', '108', '🚑'),
      EmergencyEntry('Fire', '101', '🚒'),
      EmergencyEntry('Women Helpline', '1091', '☎️'),
      EmergencyEntry('Tourist Helpline', '1363', '🧭'),
    ],
    embassyHint: 'Contact your home country\'s embassy in New Delhi.',
  ),
  CountryEmergencyInfo(
    country: 'United Kingdom',
    matchKeywords: ['uk', 'united kingdom', 'england', 'london', 'scotland', 'wales', 'manchester', 'edinburgh'],
    entries: [
      EmergencyEntry('Police / Fire / Ambulance (Emergency)', '999', '🚨'),
      EmergencyEntry('Non-emergency Police', '101', '👮'),
      EmergencyEntry('Non-emergency Medical (NHS)', '111', '🚑'),
    ],
    embassyHint: 'Contact your home country\'s embassy or High Commission in London.',
  ),
  CountryEmergencyInfo(
    country: 'European Union',
    matchKeywords: ['france', 'paris', 'germany', 'berlin', 'italy', 'rome', 'spain', 'madrid', 'barcelona', 'netherlands', 'amsterdam', 'greece', 'athens', 'portugal', 'lisbon', 'europe', 'switzerland', 'austria'],
    entries: [
      EmergencyEntry('EU-wide Emergency', '112', '🚨'),
    ],
    embassyHint: 'Contact your home country\'s embassy in the national capital.',
  ),
  CountryEmergencyInfo(
    country: 'Japan',
    matchKeywords: ['japan', 'tokyo', 'osaka', 'kyoto', 'yokohama'],
    entries: [
      EmergencyEntry('Police', '110', '👮'),
      EmergencyEntry('Ambulance / Fire', '119', '🚑'),
      EmergencyEntry('Japan Tourist Hotline', '050-3816-2787', '🧭'),
    ],
    embassyHint: 'Contact your home country\'s embassy in Tokyo.',
  ),
  CountryEmergencyInfo(
    country: 'Australia',
    matchKeywords: ['australia', 'sydney', 'melbourne', 'brisbane', 'perth'],
    entries: [
      EmergencyEntry('Police / Fire / Ambulance', '000', '🚨'),
    ],
    embassyHint: 'Contact your home country\'s embassy in Canberra.',
  ),
  CountryEmergencyInfo(
    country: 'Thailand',
    matchKeywords: ['thailand', 'bangkok', 'phuket', 'chiang mai', 'pattaya'],
    entries: [
      EmergencyEntry('Tourist Police', '1155', '👮'),
      EmergencyEntry('Police', '191', '🚨'),
      EmergencyEntry('Ambulance', '1669', '🚑'),
    ],
    embassyHint: 'Contact your home country\'s embassy in Bangkok.',
  ),
  CountryEmergencyInfo(
    country: 'United Arab Emirates',
    matchKeywords: ['uae', 'dubai', 'abu dhabi', 'sharjah', 'emirates'],
    entries: [
      EmergencyEntry('Police', '999', '👮'),
      EmergencyEntry('Ambulance', '998', '🚑'),
      EmergencyEntry('Fire', '997', '🚒'),
    ],
    embassyHint: 'Contact your home country\'s embassy in Abu Dhabi.',
  ),
];

const CountryEmergencyInfo kDefaultEmergencyInfo = CountryEmergencyInfo(
  country: 'General / Unmatched Destination',
  matchKeywords: [],
  entries: [
    EmergencyEntry('International Emergency (many countries)', '112', '🚨'),
    EmergencyEntry('US/Canada Emergency', '911', '🚨'),
  ],
  embassyHint: 'Look up your home country\'s embassy contact before you travel, and save it here offline.',
);

CountryEmergencyInfo findEmergencyInfoFor(String destination) {
  final query = destination.toLowerCase();
  for (final info in kEmergencyDirectory) {
    for (final keyword in info.matchKeywords) {
      if (query.contains(keyword)) return info;
    }
  }
  return kDefaultEmergencyInfo;
}
