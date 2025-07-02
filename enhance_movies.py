#!/usr/bin/env python3
"""
Improved Context-Aware TMDB Movie Tag Enhancer
Better logic to prevent inappropriate tag assignments

Usage:
python enhance_movies_v2.py --input movies.json --output movies_enhanced.json --api-key YOUR_TMDB_KEY
"""

import json
import requests
import time
import argparse
from typing import List, Dict, Set
from ratelimit import limits, sleep_and_retry
from tqdm import tqdm
import logging

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class ImprovedTMDBEnhancer:
    def __init__(self, api_key: str):
        self.api_key = api_key
        self.base_url = "https://api.themoviedb.org/3"
        self.session = requests.Session()
        
        # More conservative, context-aware keyword mappings
        self.keyword_mappings = {
            # Mind-Bending (require stronger indicators)
            'time travel': ['mind-bending', 'sci-fi concept', 'temporal'],
            'alternate reality': ['mind-bending', 'parallel universe', 'surreal'],
            'memory loss': ['psychological', 'mind-bending', 'amnesia'],
            'multiple personality': ['psychological', 'mind-bending', 'identity crisis'],
            'unreliable narrator': ['mind-bending', 'plot twist', 'deception'],
            'non linear narrative': ['mind-bending', 'complex narrative', 'cerebral'],
            'psychological thriller': ['psychological', 'mind-bending', 'cerebral'],
            'consciousness': ['philosophical', 'mind-bending', 'cerebral'],
            'identity crisis': ['psychological', 'mind-bending', 'self-discovery'],
            'paranoia': ['psychological', 'mind-bending', 'mental illness'],
            'philosophy': ['cerebral', 'thought-provoking', 'philosophical'],
            
            # High Stakes (require actual danger/urgency)
            'race against time': ['high stakes', 'urgent', 'time-sensitive'],
            'hostage': ['high stakes', 'intense', 'urgent'],
            'bomb': ['high stakes', 'explosive', 'urgent'],
            'kidnapping': ['high stakes', 'crime', 'urgent'],
            'assassination': ['high stakes', 'political thriller', 'deadly'],
            'terrorism': ['high stakes', 'political thriller', 'urgent'],
            'life or death': ['high stakes', 'intense', 'critical'],
            'countdown': ['high stakes', 'time-sensitive', 'tension'],
            'rescue mission': ['high stakes', 'heroic', 'urgent'],
            'escape': ['high stakes', 'urgent', 'freedom'],
            
            # True Stories (very strict)
            'biography': ['biographical', 'based on true story', 'real person'],
            'based on true story': ['true story', 'biographical', 'real events'],
            'historical event': ['historical', 'based on true events', 'period piece'],
            'real person': ['biographical', 'true story', 'historical figure'],
            'memoir': ['biographical', 'personal story', 'autobiography'],
            'true crime': ['true crime', 'based on true events', 'real case'],
            'historical figure': ['biographical', 'historical', 'famous person'],
            'documentary': ['documentary style', 'factual', 'non-fiction'],
            'docudrama': ['based on true events', 'documentary style', 'real events'],
            
            # Twist Ending (require actual twist indicators)
            'plot twist': ['plot twist', 'surprise ending', 'unexpected'],
            'surprise ending': ['twist ending', 'shocking', 'unexpected'],
            'twist ending': ['twist ending', 'plot twist', 'shocking'],
            'revelation': ['plot twist', 'surprise ending', 'discovery'],
            'red herring': ['plot twist', 'misdirection', 'deception'],
            'conspiracy': ['conspiracy', 'cover-up', 'hidden truth'],
            
            # Action (require actual combat/violence)
            'martial arts': ['action-packed', 'combat', 'fighting'],
            'car chase': ['action-packed', 'fast-paced', 'vehicular'],
            'explosion': ['explosive', 'action-packed', 'destruction'],
            'gunfight': ['action-packed', 'shootout', 'combat'],
            'hand to hand combat': ['action-packed', 'fighting', 'physical combat'],
            'shootout': ['action-packed', 'gunfight', 'combat'],
            'sword fight': ['action-packed', 'combat', 'swordplay'],
            'special forces': ['military action', 'tactical', 'combat'],
            'heist': ['crime', 'elaborate plan', 'theft'],
            
            # Romance (clear romantic indicators)
            'love triangle': ['romantic', 'love story', 'relationship drama'],
            'wedding': ['romantic', 'love story', 'celebration'],
            'love at first sight': ['romantic', 'passionate', 'instant attraction'],
            'forbidden love': ['romantic', 'star-crossed lovers', 'tragic love'],
            'romantic comedy': ['romantic', 'light-hearted', 'comedy romance'],
            'love story': ['romantic', 'love story', 'passionate'],
            'marriage': ['romantic', 'relationship', 'commitment'],
            
            # Horror (actual scary content)
            'ghost': ['supernatural', 'scary', 'paranormal'],
            'haunted house': ['supernatural', 'scary', 'haunted'],
            'demon': ['supernatural', 'terrifying', 'evil'],
            'serial killer': ['psychological horror', 'dark', 'terrifying'],
            'vampire': ['supernatural', 'gothic', 'bloodthirsty'],
            'possession': ['supernatural', 'demonic', 'evil spirits'],
            'murder': ['dark', 'violent', 'crime'],
            'slasher': ['horror', 'killer', 'violent'],
            'supernatural horror': ['supernatural', 'horror', 'scary'],
            
            # Sci-Fi (clear sci-fi concepts)
            'alien': ['sci-fi concept', 'extraterrestrial', 'space'],
            'robot': ['sci-fi concept', 'artificial intelligence', 'technology'],
            'space': ['space opera', 'sci-fi concept', 'futuristic'],
            'future': ['futuristic', 'sci-fi concept', 'dystopian'],
            'artificial intelligence': ['sci-fi concept', 'technology', 'AI'],
            'time machine': ['sci-fi concept', 'time travel', 'temporal'],
            'spaceship': ['sci-fi concept', 'space', 'spacecraft'],
            
            # Family/Kids (clear family content)
            'fairy tale': ['fairy tale', 'magical', 'family-friendly'],
            'princess': ['fairy tale', 'royal', 'magical'],
            'talking animal': ['family-friendly', 'fantasy', 'anthropomorphic'],
            'children': ['family-friendly', 'kids', 'wholesome'],
            'school': ['school setting', 'education', 'youth'],
            'coming of age': ['coming-of-age', 'youth', 'growing up'],
            
            # War/Military (actual military content)
            'soldier': ['military', 'war', 'combat'],
            'battlefield': ['war', 'military conflict', 'combat zone'],
            'vietnam war': ['historical war', 'military history', 'war drama'],
            'world war ii': ['historical war', 'WWII', 'military history'],
            'world war': ['historical war', 'military history', 'war drama'],
            
            # Crime (clear criminal activity)
            'mafia': ['crime', 'organized crime', 'gangster'],
            'gangster': ['crime', 'criminal', 'organized crime'],
            'drug dealer': ['crime', 'drugs', 'criminal'],
            'police': ['law enforcement', 'crime fighting', 'justice'],
            'fbi': ['federal investigation', 'law enforcement', 'crime solving'],
            'prison': ['incarceration', 'criminal justice', 'confinement'],
            'detective': ['investigation', 'mystery', 'crime solving'],
            
            # Spy/Espionage (clear spy content)
            'spy': ['espionage', 'secret agent', 'international intrigue'],
            'espionage': ['spy', 'secret agent', 'covert ops'],
            'secret agent': ['spy', 'espionage', 'international intrigue'],
            'cia': ['intelligence agency', 'spy', 'government'],
            'mi6': ['intelligence agency', 'spy', 'british intelligence'],
        }
        
        # Genre-based exclusions (prevent certain tags for certain genres)
        self.genre_exclusions = {
            'Family': ['psychological horror', 'dark', 'terrifying', 'violent', 'gore'],
            'Comedy': ['terrifying', 'scary', 'psychological horror', 'dark'],
            'Animation': ['violent', 'gore', 'psychological horror', 'terrifying'],
            'Fantasy': ['based on true story', 'biographical', 'real events', 'documentary style'],
            'Science Fiction': ['based on true story', 'biographical'] # Unless clearly biographical sci-fi
        }
        
        # Context filters - only apply certain tags if movie has supporting evidence
        self.context_requirements = {
            'mind-bending': ['Drama', 'Sci-Fi', 'Thriller', 'Mystery'],
            'psychological': ['Drama', 'Thriller', 'Horror'],
            'based on true story': ['Biography', 'Drama', 'History', 'Documentary'],
            'biographical': ['Biography', 'Drama', 'History'],
            'high stakes': ['Action', 'Thriller', 'Crime'],
            'plot twist': ['Mystery', 'Thriller', 'Drama'],
        }
    
    @sleep_and_retry
    @limits(calls=40, period=1)
    def make_request(self, url: str) -> Dict:
        """Make rate-limited request to TMDB API"""
        try:
            response = self.session.get(url, timeout=10)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            logger.error(f"Request failed for {url}: {e}")
            return {}
    
    def get_movie_keywords(self, movie_id: str) -> List[str]:
        """Fetch keywords for a movie from TMDB"""
        url = f"{self.base_url}/movie/{movie_id}/keywords?api_key={self.api_key}"
        data = self.make_request(url)
        
        if 'keywords' in data:
            return [kw['name'].lower() for kw in data['keywords']]
        return []
    
    def search_movie_by_title(self, title: str) -> str:
        """Search for movie ID by title"""
        url = f"{self.base_url}/search/movie?api_key={self.api_key}&query={requests.utils.quote(title)}"
        data = self.make_request(url)
        
        if data.get('results'):
            return str(data['results'][0]['id'])
        return ""
    
    def is_tag_appropriate_for_movie(self, tag: str, movie: Dict, keywords: List[str]) -> bool:
        """Check if a tag is appropriate given movie context"""
        genres = [g.lower() for g in movie.get('genres', [])]
        title = movie.get('title', '').lower()
        overview = movie.get('overview', '').lower()
        
        # Check genre exclusions
        for genre in genres:
            if genre.lower() in self.genre_exclusions:
                if tag in self.genre_exclusions[genre.lower()]:
                    return False
        
        # Check context requirements
        if tag in self.context_requirements:
            required_genres = [g.lower() for g in self.context_requirements[tag]]
            if not any(genre in required_genres for genre in genres):
                return False
        
        # Special checks for specific problematic tags
        if tag in ['based on true story', 'biographical', 'real events']:
            # Don't apply to obvious fantasy/sci-fi unless very clear indicators
            fantasy_indicators = ['magic', 'wizard', 'dragon', 'fairy', 'superhero', 'alien', 'space']
            if any(indicator in title or indicator in overview for indicator in fantasy_indicators):
                # Only allow if we have VERY strong biographical indicators
                strong_bio_keywords = ['biography', 'based on true story', 'real person', 'memoir', 'documentary']
                return any(keyword in keywords for keyword in strong_bio_keywords)
        
        if tag in ['mind-bending', 'psychological']:
            # Don't apply to family/kids movies unless very clear
            if 'family' in genres or 'animation' in genres:
                return False
        
        if tag in ['scary', 'terrifying', 'horror']:
            # Don't apply to family/comedy movies
            if 'family' in genres or 'comedy' in genres:
                return False
        
        return True
    
    def keywords_to_mood_tags(self, keywords: List[str], movie: Dict) -> List[str]:
        """Convert TMDB keywords to appropriate mood-specific tags"""
        mood_tags = set()
        
        for keyword in keywords:
            keyword_clean = keyword.lower().strip()
            
            # Skip obviously irrelevant keywords
            skip_keywords = ['duringcreditsstinger', 'aftercreditsstinger', 'based on video game']
            if keyword_clean in skip_keywords:
                continue
            
            # Direct mapping
            if keyword_clean in self.keyword_mappings:
                candidate_tags = self.keyword_mappings[keyword_clean]
                for tag in candidate_tags:
                    if self.is_tag_appropriate_for_movie(tag, movie, keywords):
                        mood_tags.add(tag)
            
            # More conservative partial matching
            for mapping_key, tags in self.keyword_mappings.items():
                if len(mapping_key.split()) > 1:  # Multi-word keys
                    # Require exact match for multi-word keys
                    if mapping_key == keyword_clean:
                        for tag in tags:
                            if self.is_tag_appropriate_for_movie(tag, movie, keywords):
                                mood_tags.add(tag)
                else:  # Single word keys
                    # More strict single word matching
                    if mapping_key == keyword_clean:  # Exact match only
                        for tag in tags:
                            if self.is_tag_appropriate_for_movie(tag, movie, keywords):
                                mood_tags.add(tag)
        
        return list(mood_tags)
    
    def enhance_movie(self, movie: Dict) -> Dict:
        """Enhance a single movie with appropriate TMDB keywords"""
        movie_id = movie.get('id', '')
        title = movie.get('title', '')
        
        # If no TMDB ID, try to find it by title
        if not movie_id and title:
            movie_id = self.search_movie_by_title(title)
        
        if not movie_id:
            logger.warning(f"No TMDB ID found for: {title}")
            return movie
        
        # Get keywords from TMDB
        keywords = self.get_movie_keywords(movie_id)
        
        if not keywords:
            logger.info(f"No keywords found for: {title}")
            return movie
        
        # Convert to appropriate mood tags
        new_mood_tags = self.keywords_to_mood_tags(keywords, movie)
        
        # Combine with existing tags (but remove inappropriate ones first)
        existing_tags = movie.get('tags', [])
        
        # Filter existing tags that might be inappropriate
        filtered_existing = []
        for tag in existing_tags:
            if self.is_tag_appropriate_for_movie(tag.lower(), movie, keywords):
                filtered_existing.append(tag)
        
        # Combine and deduplicate
        all_tags = list(set(filtered_existing + new_mood_tags))
        
        # Update movie
        enhanced_movie = movie.copy()
        enhanced_movie['tags'] = sorted(all_tags)
        enhanced_movie['tmdb_keywords'] = keywords
        
        removed_count = len(existing_tags) - len(filtered_existing)
        added_count = len(new_mood_tags)
        
        logger.info(f"Enhanced '{title}': +{added_count} new, -{removed_count} inappropriate tags")
        
        return enhanced_movie

def load_movies(file_path: str) -> List[Dict]:
    """Load movies from JSON file"""
    with open(file_path, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_movies(movies: List[Dict], file_path: str):
    """Save movies to JSON file"""
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(movies, f, indent=2, ensure_ascii=False)

def main():
    parser = argparse.ArgumentParser(description='Enhanced movie database with improved context-aware TMDB keywords')
    parser.add_argument('--input', required=True, help='Input JSON file path')
    parser.add_argument('--output', required=True, help='Output JSON file path')
    parser.add_argument('--api-key', required=True, help='TMDB API key')
    parser.add_argument('--limit', type=int, help='Limit number of movies to process (for testing)')
    
    args = parser.parse_args()
    
    # Load movies
    print(f"📚 Loading movies from {args.input}...")
    movies = load_movies(args.input)
    
    if args.limit:
        movies = movies[:args.limit]
        print(f"🔢 Processing limited set: {len(movies)} movies")
    
    print(f"✅ Loaded {len(movies)} movies")
    
    # Initialize enhancer
    enhancer = ImprovedTMDBEnhancer(args.api_key)
    
    # Process movies
    print(f"\n🔧 Enhancing movies with context-aware TMDB keywords...")
    enhanced_movies = []
    
    for movie in tqdm(movies, desc="Processing movies"):
        enhanced_movie = enhancer.enhance_movie(movie)
        enhanced_movies.append(enhanced_movie)
    
    # Save results
    print(f"\n💾 Saving enhanced movies to {args.output}...")
    save_movies(enhanced_movies, args.output)
    
    print(f"\n🎉 Context-aware enhancement complete!")
    print(f"📁 Enhanced data saved to: {args.output}")

if __name__ == "__main__":
    main()