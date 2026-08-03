/// 球隊名稱 → logo 資產路徑（對應 AL_teamlogo / NL_teamlogo 檔名）
class TeamLogos {
  static const _alDir = 'assets/stadium_photos/AL_teamlogo';
  static const _nlDir = 'assets/stadium_photos/NL_teamlogo';

  static const Map<String, String> _byTeam = {
    // American League
    'Baltimore Orioles': '$_alDir/ALE-BAL-Insignia_II.png',
    'Oakland Athletics': '$_alDir/Athletics_logo.svg.webp',
    'Boston Red Sox': '$_alDir/Boston_Red_Sox.png',
    'Chicago White Sox': '$_alDir/Chicago_White_Sox.svg.webp',
    'Detroit Tigers': '$_alDir/Detroit_Tigers_logo.svg.webp',
    'Cleveland Guardians': '$_alDir/Guardians_winged__G_.png',
    'Houston Astros': '$_alDir/Houston-Astros-Logo.svg.webp',
    'Kansas City Royals': '$_alDir/Kansas_City_Royals_logo.svg.webp',
    'Los Angeles Angels': '$_alDir/Los_Angeles_Angels_curved_wordmark.svg.webp',
    'Minnesota Twins':
        '$_alDir/Minnesota_Twins_wordmark_logo_(2023_rebrand).svg.webp',
    'New York Yankees': '$_alDir/New_York_Yankees_Primary_Logo.svg.webp',
    'Seattle Mariners': '$_alDir/Seattle_Mariners_logo.svg.webp',
    'Tampa Bay Rays': '$_alDir/Tampa_Bay_Rays_Logo.svg.webp',
    'Texas Rangers': '$_alDir/Texas_Rangers.svg.webp',
    'Toronto Blue Jays': '$_alDir/TorontoBlueJays2012primary.png',

    // National League
    'Arizona Diamondbacks': '$_nlDir/Arizona_Diamondbacks_logo_teal.svg.webp',
    'Atlanta Braves': '$_nlDir/Atlanta_Braves.svg.webp',
    'Chicago Cubs': '$_nlDir/Chicago_Cubs_logo.svg.webp',
    'Cincinnati Reds': '$_nlDir/Cincinnati_Reds_Logo.svg.webp',
    'Colorado Rockies': '$_nlDir/Colorado_Rockies_Cap_Insignia.svg.webp',
    'Los Angeles Dodgers': '$_nlDir/Los_Angeles_Dodgers_Logo.svg.webp',
    'Miami Marlins': '$_nlDir/Miami_Marlins_logo.png',
    'Milwaukee Brewers': '$_nlDir/Milwaukee_Brewers_logo.svg.webp',
    'New York Mets': '$_nlDir/New_York_Mets.svg.webp',
    'Philadelphia Phillies': '$_nlDir/Philadelphia_Phillies.png',
    'Pittsburgh Pirates': '$_nlDir/Pittsburgh_Pirates_logo_2014.svg.webp',
    'San Francisco Giants': '$_nlDir/San_Francisco_Giants_Logo.svg.webp',
    'San Diego Padres': '$_nlDir/SD_Logo_Brown.svg.webp',
    'St. Louis Cardinals': '$_nlDir/St._Louis_Cardinals_Logo.svg.webp',
    'Washington Nationals': '$_nlDir/Washington_Nationals_logo.svg.webp',
  };

  static String? pathForTeam(String team) => _byTeam[team];
}
