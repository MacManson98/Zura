// Comprehensive Cinematic Identity Generator — Massive Coverage
String getFilmIdentity(String genre, String vibe) {
  final lookup = {
    // 🎬 ACTION - All combinations
    'Action|Action-Packed': 'Adrenaline Junkie',
    'Action|Twisty': 'Explosive Strategist',
    'Action|Emotional': 'Heart-Pounding Warrior',
    'Action|Mind-bending': 'Reality-Breaking Fighter',
    'Action|Feel-good': 'Heroic Optimist',
    'Action|Romantic': 'Action Romance Enthusiast',
    'Action|Based on a true story': 'Real-Life Hero Worshipper',
    'Action|Scary': 'Fearless Action Seeker',
    'Action|Artsy/Indie': 'Avant-Garde Brawler',
    'Action|Dark': 'Brutal Force Admirer',
    'Action|Inspiring': 'Motivational Fighter',
    'Action|Intense': 'High-Octane Thrill Seeker',
    'Action|Adventure': 'Action Adventure Enthusiast',

    // 🏃‍♂️ ADVENTURE - All combinations
    'Adventure|Action-Packed': 'Thrill-Seeking Explorer',
    'Adventure|Feel-good': 'Optimistic Adventurer',
    'Adventure|Inspiring': 'Journey Catalyst',
    'Adventure|Emotional': 'Heart-Led Explorer',
    'Adventure|Mind-bending': 'Reality Voyager',
    'Adventure|Twisty': 'Unexpected Pathfinder',
    'Adventure|Romantic': 'Love-Quest Wanderer',
    'Adventure|Based on a true story': 'Real-World Explorer',
    'Adventure|Scary': 'Danger-Seeking Nomad',
    'Adventure|Artsy/Indie': 'Bohemian Wanderer',
    'Adventure|Dark': 'Shadow Traveler',
    'Adventure|Intense': 'Extreme Adventure Seeker',

    // ❤️ ROMANCE - All combinations
    'Romance|Romantic': 'Hopeless Romantic',
    'Romance|Emotional': 'Tearjerking Love Seeker',
    'Romance|Feel-good': 'Love-Soaked Dreamer',
    'Romance|Mind-bending': 'Time-Traveling Lover',
    'Romance|Twisty': 'Unexpected Soulmate Hunter',
    'Romance|Based on a true story': 'Real Love Story Devotee',
    'Romance|Scary': 'Gothic Romance Enthusiast',
    'Romance|Artsy/Indie': 'Indie Heartthrob',
    'Romance|Action-Packed': 'Action Romance Fan',
    'Romance|Dark': 'Dark Romance Seeker',
    'Romance|Inspiring': 'Love-Inspired Optimist',
    'Romance|Intense': 'Passionate Love Devotee',

    // 👽 SCI-FI - All combinations
    'Sci-Fi|Mind-bending': 'Cosmic Thinker',
    'Sci-Fi|Action-Packed': 'Space Battle Enthusiast',
    'Sci-Fi|Emotional': 'Galactic Heart',
    'Sci-Fi|Twisty': 'Reality Hacker',
    'Sci-Fi|Feel-good': 'Optimistic Space Explorer',
    'Sci-Fi|Romantic': 'Intergalactic Lover',
    'Sci-Fi|Based on a true story': 'Science Fact Seeker',
    'Sci-Fi|Scary': 'Cosmic Horror Fan',
    'Sci-Fi|Dark': 'Dystopian Philosopher',
    'Sci-Fi|Inspiring': 'Future Visionary',
    'Sci-Fi|Artsy/Indie': 'Cerebral Futurist',
    'Sci-Fi|Intense': 'High-Tech Thriller Lover',

    // 😂 COMEDY - All combinations
    'Comedy|Feel-good': 'Joyful Jester',
    'Comedy|Mind-bending': 'Absurdist Humorist',
    'Comedy|Romantic': 'Witty Charmer',
    'Comedy|Twisty': 'Comedic Plot Twister',
    'Comedy|Scary': 'Horror-Comedy Enthusiast',
    'Comedy|Based on a true story': 'Real-Life Comedy Seeker',
    'Comedy|Action-Packed': 'Action-Comedy Hero',
    'Comedy|Emotional': 'Heartfelt Humor Lover',
    'Comedy|Artsy/Indie': 'Quirky Comedy Connoisseur',
    'Comedy|Dark': 'Dark Humor Specialist',
    'Comedy|Inspiring': 'Uplifting Comedy Fan',

    // 😱 HORROR - All combinations
    'Horror|Scary': 'Fear Addiction Specialist',
    'Horror|Twisty': 'Horror Plot Master',
    'Horror|Mind-bending': 'Psychological Terror Seeker',
    'Horror|Emotional': 'Haunted Soul',
    'Horror|Feel-good': 'Light Horror Enthusiast',
    'Horror|Romantic': 'Gothic Romance Lover',
    'Horror|Based on a true story': 'True Crime Horror Fan',
    'Horror|Action-Packed': 'Action Horror Warrior',
    'Horror|Dark': 'Darkness Embracer',
    'Horror|Artsy/Indie': 'Arthouse Horror Connoisseur',

    // 🕵️‍♂️ THRILLER - All combinations
    'Thriller|Twisty': 'Suspense Plot Addict',
    'Thriller|Scary': 'Edge-of-Seat Thrill Seeker',
    'Thriller|Emotional': 'Psychological Thriller Fan',
    'Thriller|Mind-bending': 'Mental Thriller Specialist',
    'Thriller|Feel-good': 'Light Thriller Enthusiast',
    'Thriller|Romantic': 'Romantic Suspense Lover',
    'Thriller|Action-Packed': 'Action Thriller Devotee',
    'Thriller|Based on a true story': 'True Crime Investigator',
    'Thriller|Dark': 'Dark Conspiracy Hunter',
    'Thriller|Artsy/Indie': 'Cerebral Tension Lover',

    // 🧙 FANTASY - All combinations
    'Fantasy|Emotional': 'Magical Heart Seeker',
    'Fantasy|Mind-bending': 'Reality Alchemist',
    'Fantasy|Twisty': 'Fantasy Plot Weaver',
    'Fantasy|Feel-good': 'Whimsical Dreamer',
    'Fantasy|Romantic': 'Fairy Tale Romantic',
    'Fantasy|Based on a true story': 'Mythology Believer',
    'Fantasy|Action-Packed': 'Epic Quest Warrior',
    'Fantasy|Scary': 'Dark Fantasy Seeker',
    'Fantasy|Artsy/Indie': 'Artistic Fantasy Lover',
    'Fantasy|Dark': 'Shadow Realm Explorer',
    'Fantasy|Inspiring': 'Magic-Inspired Optimist',

    // 👶 ANIMATION - All combinations
    'Animation|Feel-good': 'Animated Joy Seeker',
    'Animation|Emotional': 'Animated Tearjerker Fan',
    'Animation|Twisty': 'Animated Plot Lover',
    'Animation|Romantic': 'Animated Romance Enthusiast',
    'Animation|Mind-bending': 'Cerebral Animation Fan',
    'Animation|Action-Packed': 'Animated Action Lover',
    'Animation|Inspiring': 'Uplifting Animation Devotee',
    'Animation|Scary': 'Spooky Animation Fan',
    'Animation|Artsy/Indie': 'Independent Animation Lover',
    'Animation|Based on a true story': 'Biographical Animation Seeker',
    'Animation|Dark': 'Dark Animation Enthusiast',

    // 🎭 DRAMA - All combinations
    'Drama|Emotional': 'Emotional Drama Devotee',
    'Drama|Twisty': 'Dramatic Plot Specialist',
    'Drama|Based on a true story': 'True Story Drama Fan',
    'Drama|Feel-good': 'Uplifting Drama Lover',
    'Drama|Romantic': 'Romantic Drama Enthusiast',
    'Drama|Scary': 'Dark Drama Seeker',
    'Drama|Mind-bending': 'Psychological Drama Fan',
    'Drama|Action-Packed': 'Action Drama Devotee',
    'Drama|Dark': 'Heavy Drama Specialist',
    'Drama|Artsy/Indie': 'Auteur Drama Lover',
    'Drama|Inspiring': 'Inspirational Drama Fan',

    // 🕵 MYSTERY - All combinations
    'Mystery|Mind-bending': 'Mental Puzzle Solver',
    'Mystery|Twisty': 'Mystery Plot Addict',
    'Mystery|Emotional': 'Emotional Mystery Fan',
    'Mystery|Romantic': 'Romantic Mystery Lover',
    'Mystery|Scary': 'Dark Mystery Hunter',
    'Mystery|Feel-good': 'Cozy Mystery Enthusiast',
    'Mystery|Action-Packed': 'Action Mystery Fan',
    'Mystery|Based on a true story': 'True Crime Mystery Devotee',
    'Mystery|Artsy/Indie': 'Cerebral Mystery Lover',
    'Mystery|Dark': 'Noir Mystery Specialist',

    // 🎵 MUSIC/MUSICAL - All combinations
    'Music|Feel-good': 'Musical Joy Seeker',
    'Music|Emotional': 'Musical Heart Toucher',
    'Music|Romantic': 'Musical Romance Fan',
    'Music|Based on a true story': 'Musical Biography Lover',
    'Music|Inspiring': 'Uplifting Musical Devotee',
    'Music|Dark': 'Dark Musical Enthusiast',
    'Music|Artsy/Indie': 'Independent Music Film Fan',

    // 🏛 HISTORY - All combinations
    'History|Based on a true story': 'Historical Truth Seeker',
    'History|Emotional': 'Historical Drama Fan',
    'History|Action-Packed': 'Historical Action Enthusiast',
    'History|Inspiring': 'Historical Hero Worshipper',
    'History|Dark': 'Dark History Explorer',
    'History|Romantic': 'Historical Romance Lover',

    // 🔫 CRIME - All combinations
    'Crime|Twisty': 'Crime Plot Mastermind',
    'Crime|Dark': 'Crime Noir Specialist',
    'Crime|Action-Packed': 'Crime Action Fan',
    'Crime|Based on a true story': 'True Crime Devotee',
    'Crime|Emotional': 'Crime Drama Enthusiast',
    'Crime|Mind-bending': 'Psychological Crime Fan',

    // 🏕 FAMILY - All combinations
    'Family|Feel-good': 'Family Fun Seeker',
    'Family|Inspiring': 'Family Values Champion',
    'Family|Emotional': 'Family Drama Lover',
    'Family|Adventure': 'Family Adventure Fan',

    // 🎯 SPORT - All combinations
    'Sport|Inspiring': 'Sports Inspiration Seeker',
    'Sport|Emotional': 'Sports Drama Fan',
    'Sport|Based on a true story': 'True Sports Story Lover',
    'Sport|Feel-good': 'Uplifting Sports Enthusiast',

    // 🚗 CAR/RACING - All combinations
    'Car|Action-Packed': 'Speed Demon',
    'Car|Feel-good': 'Car Culture Enthusiast',

    // 🎪 CIRCUS/CARNIVAL
    'Circus|Feel-good': 'Big Top Dreamer',
    'Circus|Dark': 'Dark Carnival Seeker',

    // Generic Genre Fallbacks
    'Action|Any': 'Action Movie Lover',
    'Adventure|Any': 'Adventure Seeker',
    'Romance|Any': 'Romance Enthusiast',
    'Sci-Fi|Any': 'Science Fiction Fan',
    'Comedy|Any': 'Comedy Connoisseur',
    'Horror|Any': 'Horror Aficionado',
    'Thriller|Any': 'Thriller Enthusiast',
    'Fantasy|Any': 'Fantasy Devotee',
    'Animation|Any': 'Animation Lover',
    'Drama|Any': 'Drama Appreciator',
    'Mystery|Any': 'Mystery Enthusiast',
    'Music|Any': 'Musical Fan',
    'History|Any': 'History Buff',
    'Crime|Any': 'Crime Story Fan',
    'Family|Any': 'Family Movie Lover',
    'Sport|Any': 'Sports Movie Fan',
    'Documentary|Any': 'Documentary Enthusiast',

    // Generic Vibe Fallbacks
    'Any|Action-Packed': 'High-Energy Film Lover',
    'Any|Mind-bending': 'Cerebral Cinema Fan',
    'Any|Emotional': 'Heart-Driven Movie Lover',
    'Any|Twisty': 'Plot Twist Addict',
    'Any|Feel-good': 'Uplifting Cinema Seeker',
    'Any|Romantic': 'Love Story Enthusiast',
    'Any|Based on a true story': 'Reality-Based Film Fan',
    'Any|Scary': 'Thrill-Seeking Movie Lover',
    'Any|Artsy/Indie': 'Independent Cinema Devotee',
    'Any|Dark': 'Dark Cinema Explorer',
    'Any|Inspiring': 'Motivational Movie Fan',
    'Any|Intense': 'High-Stakes Cinema Lover',

    // Ultimate Fallbacks
    'Any|Any': 'Cinema Enthusiast',
    '|': 'Movie Explorer',
    'Unknown|Unknown': 'Film Discovery Adventurer',
  };

  // Clean and normalize inputs
  final cleanGenre = genre.trim();
  final cleanVibe = vibe.trim();
  
  // Try exact match first
  final exactKey = '$cleanGenre|$cleanVibe';
  if (lookup.containsKey(exactKey)) {
    return lookup[exactKey]!;
  }
  
  // Try genre with Any vibe
  final genreKey = '$cleanGenre|Any';
  if (lookup.containsKey(genreKey)) {
    return lookup[genreKey]!;
  }
  
  // Try Any genre with specific vibe
  final vibeKey = 'Any|$cleanVibe';
  if (lookup.containsKey(vibeKey)) {
    return lookup[vibeKey]!;
  }
  
  // Return ultimate fallback
  return lookup['Any|Any'] ?? 'Movie Explorer';
}