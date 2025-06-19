// File: lib/data/popular_movies_data.dart

import '../movie.dart';

class PopularMoviesData {
  static List<Movie> getOnboardingMovies() {
    return [
      // Action Movies
      Movie(
        id: 'avengers_endgame',
        title: 'Avengers: Endgame',
        posterUrl: 'https://image.tmdb.org/t/p/w500/or06FN3Dka5tukK1e9sl16pB3iy.jpg',
        overview: 'The Avengers assemble once more to reverse Thanos\' actions and save the universe.',
        cast: ['Robert Downey Jr.', 'Chris Evans', 'Scarlett Johansson'],
        genres: ['Action', 'Adventure', 'Sci-Fi'],
        tags: ['Action-Packed', 'Epic', 'Emotional'],
        rating: 8.4,
        runtime: 181,
        releaseDate: '2019-04-26',
        originalLanguage: 'en',
      ),
      
      Movie(
        id: 'john_wick',
        title: 'John Wick',
        posterUrl: 'https://image.tmdb.org/t/p/w500/fZPSd91yGE9fCcCe6OoQr6E3Bev.jpg',
        overview: 'An ex-hitman comes out of retirement to track down the gangsters who killed his dog.',
        cast: ['Keanu Reeves', 'Michael Nyqvist', 'Alfie Allen'],
        genres: ['Action', 'Thriller'],
        tags: ['Action-Packed', 'Intense', 'Stylish'],
        rating: 7.4,
        runtime: 101,
        releaseDate: '2014-10-24',
        originalLanguage: 'en',
      ),

      // Comedy Movies
      Movie(
        id: 'the_hangover',
        title: 'The Hangover',
        posterUrl: 'https://image.tmdb.org/t/p/w500/uluhlXqJpXomPh5cvdpd4PCh0Th.jpg',
        overview: 'Three buddies wake up from a bachelor party in Las Vegas with no memory of the previous night.',
        cast: ['Bradley Cooper', 'Ed Helms', 'Zach Galifianakis'],
        genres: ['Comedy'],
        tags: ['Feel-Good', 'Funny', 'Wild'],
        rating: 7.7,
        runtime: 100,
        releaseDate: '2009-06-05',
        originalLanguage: 'en',
      ),

      Movie(
        id: 'superbad',
        title: 'Superbad',
        posterUrl: 'https://image.tmdb.org/t/p/w500/ek8e8txUyUwd2BNqj6lFEerJfbq.jpg',
        overview: 'Two co-dependent high school seniors are forced to deal with separation anxiety.',
        cast: ['Jonah Hill', 'Michael Cera', 'Christopher Mintz-Plasse'],
        genres: ['Comedy'],
        tags: ['Feel-Good', 'Funny', 'Coming-of-Age'],
        rating: 7.6,
        runtime: 113,
        releaseDate: '2007-08-17',
        originalLanguage: 'en',
      ),

      // Drama Movies
      Movie(
        id: 'shawshank_redemption',
        title: 'The Shawshank Redemption',
        posterUrl: 'https://image.tmdb.org/t/p/w500/q6y0Go1tsGEsmtFryDOJo3dEmqu.jpg',
        overview: 'Two imprisoned men bond over years, finding solace and eventual redemption through acts of common decency.',
        cast: ['Tim Robbins', 'Morgan Freeman', 'Bob Gunton'],
        genres: ['Drama'],
        tags: ['Inspiring', 'Emotional', 'Epic'],
        rating: 9.3,
        runtime: 142,
        releaseDate: '1994-09-23',
        originalLanguage: 'en',
      ),

      Movie(
        id: 'forrest_gump',
        title: 'Forrest Gump',
        posterUrl: 'https://image.tmdb.org/t/p/w500/saHP97rTPS5eLmrLQEcANmKrsFl.jpg',
        overview: 'The story of a man with a low IQ who witnesses and influences major historical events.',
        cast: ['Tom Hanks', 'Robin Wright', 'Gary Sinise'],
        genres: ['Drama', 'Romance'],
        tags: ['Feel-Good', 'Inspiring', 'Emotional'],
        rating: 8.8,
        runtime: 142,
        releaseDate: '1994-07-06',
        originalLanguage: 'en',
      ),

      // Horror Movies
      Movie(
        id: 'get_out',
        title: 'Get Out',
        posterUrl: 'https://image.tmdb.org/t/p/w500/tFXcEccSQMf3lfhfXKSU9iRBpa3.jpg',
        overview: 'A young African-American visits his white girlfriend\'s parents for the weekend.',
        cast: ['Daniel Kaluuya', 'Allison Williams', 'Catherine Keener'],
        genres: ['Horror', 'Thriller'],
        tags: ['Scary', 'Mind-Bending', 'Intense'],
        rating: 7.7,
        runtime: 104,
        releaseDate: '2017-02-24',
        originalLanguage: 'en',
      ),

      Movie(
        id: 'a_quiet_place',
        title: 'A Quiet Place',
        posterUrl: 'https://image.tmdb.org/t/p/w500/nAU74GmpUk7t5iklEp3bufwDq4n.jpg',
        overview: 'A family must live in silence to hide from creatures that hunt by sound.',
        cast: ['Emily Blunt', 'John Krasinski', 'Millicent Simmonds'],
        genres: ['Horror', 'Thriller'],
        tags: ['Scary', 'Intense', 'Emotional'],
        rating: 7.5,
        runtime: 90,
        releaseDate: '2018-04-06',
        originalLanguage: 'en',
      ),

      // Romance Movies
      Movie(
        id: 'the_notebook',
        title: 'The Notebook',
        posterUrl: 'https://image.tmdb.org/t/p/w500/qom1SZSENdmHFNZBXbtJAU0WTlC.jpg',
        overview: 'A poor yet passionate young man falls in love with a rich young woman.',
        cast: ['Ryan Gosling', 'Rachel McAdams', 'James Garner'],
        genres: ['Romance', 'Drama'],
        tags: ['Romantic', 'Emotional', 'Feel-Good'],
        rating: 7.8,
        runtime: 117,
        releaseDate: '2004-06-25',
        originalLanguage: 'en',
      ),

      Movie(
        id: 'la_la_land',
        title: 'La La Land',
        posterUrl: 'https://image.tmdb.org/t/p/w500/uDO8zWDhfWwoFdKS4fzkUJt0Rf0.jpg',
        overview: 'A jazz musician and an aspiring actress meet and fall in love in Los Angeles.',
        cast: ['Ryan Gosling', 'Emma Stone', 'John Legend'],
        genres: ['Romance', 'Drama', 'Music'],
        tags: ['Romantic', 'Feel-Good', 'Musical'],
        rating: 8.0,
        runtime: 128,
        releaseDate: '2016-12-09',
        originalLanguage: 'en',
      ),

      // Sci-Fi Movies
      Movie(
        id: 'inception',
        title: 'Inception',
        posterUrl: 'https://image.tmdb.org/t/p/w500/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg',
        overview: 'A thief who steals corporate secrets through dream-sharing technology.',
        cast: ['Leonardo DiCaprio', 'Marion Cotillard', 'Tom Hardy'],
        genres: ['Sci-Fi', 'Action', 'Thriller'],
        tags: ['Mind-Bending', 'Action-Packed', 'Complex'],
        rating: 8.8,
        runtime: 148,
        releaseDate: '2010-07-16',
        originalLanguage: 'en',
      ),

      Movie(
        id: 'the_matrix',
        title: 'The Matrix',
        posterUrl: 'https://image.tmdb.org/t/p/w500/f89U3ADr1oiB1s9GkdPOEpXUk5H.jpg',
        overview: 'A computer hacker learns about the true nature of his reality.',
        cast: ['Keanu Reeves', 'Laurence Fishburne', 'Carrie-Anne Moss'],
        genres: ['Sci-Fi', 'Action'],
        tags: ['Mind-Bending', 'Action-Packed', 'Revolutionary'],
        rating: 8.7,
        runtime: 136,
        releaseDate: '1999-03-31',
        originalLanguage: 'en',
      ),

      // Fantasy Movies
      Movie(
        id: 'lord_of_the_rings',
        title: 'The Lord of the Rings: The Fellowship of the Ring',
        posterUrl: 'https://image.tmdb.org/t/p/w500/6oom5QYQ2yQTMJIbnvbkBL9cHo6.jpg',
        overview: 'A hobbit sets out on a quest to destroy a powerful ring.',
        cast: ['Elijah Wood', 'Ian McKellen', 'Viggo Mortensen'],
        genres: ['Fantasy', 'Adventure'],
        tags: ['Epic', 'Adventure', 'Magical'],
        rating: 8.8,
        runtime: 178,
        releaseDate: '2001-12-19',
        originalLanguage: 'en',
      ),

      Movie(
        id: 'harry_potter',
        title: 'Harry Potter and the Philosopher\'s Stone',
        posterUrl: 'https://image.tmdb.org/t/p/w500/wuMc08IPKEatf9rnMNXvIDxqP4W.jpg',
        overview: 'A young wizard discovers his magical heritage on his 11th birthday.',
        cast: ['Daniel Radcliffe', 'Emma Watson', 'Rupert Grint'],
        genres: ['Fantasy', 'Adventure', 'Family'],
        tags: ['Magical', 'Adventure', 'Feel-Good'],
        rating: 7.6,
        runtime: 152,
        releaseDate: '2001-11-16',
        originalLanguage: 'en',
      ),

      // Thriller Movies  
      Movie(
        id: 'gone_girl',
        title: 'Gone Girl',
        posterUrl: 'https://image.tmdb.org/t/p/w500/gdiLTof3rbPDAmPaCf4g6op46bj.jpg',
        overview: 'A man becomes the prime suspect when his wife disappears on their anniversary.',
        cast: ['Ben Affleck', 'Rosamund Pike', 'Neil Patrick Harris'],
        genres: ['Thriller', 'Mystery', 'Drama'],
        tags: ['Mind-Bending', 'Twisty', 'Dark'],
        rating: 8.1,
        runtime: 149,
        releaseDate: '2014-10-01',
        originalLanguage: 'en',
      ),
    ];
  }

  // Virtual friends for matching tutorial
  static List<Map<String, dynamic>> getVirtualFriends() {
    return [
      {
        'name': 'Alex',
        'avatar': '🎬',
        'description': 'Loves crowd-pleasers and blockbusters',
        'preferredGenres': ['Action', 'Comedy', 'Sci-Fi'],
        'likedMovies': ['avengers_endgame', 'the_hangover', 'inception'],
        'personality': 'balanced', // likes popular movies
      },
      {
        'name': 'Sam', 
        'avatar': '💥',
        'description': 'Action movie fanatic',
        'preferredGenres': ['Action', 'Thriller', 'Sci-Fi'],
        'likedMovies': ['john_wick', 'the_matrix', 'gone_girl'],
        'personality': 'action_lover',
      },
      {
        'name': 'Riley',
        'avatar': '🎭', 
        'description': 'Loves deep, meaningful films',
        'preferredGenres': ['Drama', 'Romance', 'Thriller'],
        'likedMovies': ['shawshank_redemption', 'the_notebook', 'get_out'],
        'personality': 'indie_artsy',
      },
    ];
  }
}