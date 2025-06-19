import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../movie.dart';
import '../models/user_profile.dart';
import '../screens/movie_detail_screen.dart';


class MovieCardSwiper extends StatelessWidget {
  final List<Movie> movies;
  final UserProfile currentUser;
  final CardSwiperOnSwipe onSwipe;
  

  const MovieCardSwiper({
    super.key,
    required this.movies,
    required this.currentUser,
    required this.onSwipe,
  });

  @override
  Widget build(BuildContext context) {
    return CardSwiper(
      cardsCount: movies.length,
      numberOfCardsDisplayed: 1,
      onSwipe: onSwipe,
      cardBuilder: (context, index, percentX, percentY) {
        if (index >= movies.length) return const SizedBox.shrink();

        final movie = movies[index];
        final leftIntensity = percentX < 0 ? (-percentX.toDouble()).clamp(0.0, 1.0) : 0.0;
        final rightIntensity = percentX > 0 ? percentX.toDouble().clamp(0.0, 1.0) : 0.0;

        return Container(
          margin: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.yellow.shade800, width: 2.w),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14.r),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: const Color(0xFF1A1A1A)),
                Column(
                  children: [
                    Expanded(
                      child: Image.network(
                        movie.posterUrl,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[800],
                            child: Icon(Icons.broken_image, size: 100.sp, color: Colors.white24),
                          );
                        },
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
                      child: Text(
                        movie.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: ElevatedButton(
                        onPressed: () => showMovieDetails(
                          context: context,
                          movie: movie,
                          currentUser: currentUser,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE5A00D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        ),
                        child: Text(
                          "View more",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (leftIntensity > 0)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.red.withAlpha((179 * leftIntensity).toInt()),
                            Colors.red.withAlpha(0),
                          ],
                          stops: const [0.0, 0.3],
                        ),
                      ),
                    ),
                  ),
                if (rightIntensity > 0)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [
                            Colors.green.withAlpha((179 * rightIntensity).toInt()),
                            Colors.green.withAlpha(0),
                          ],
                          stops: const [0.0, 0.3],
                        ),
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => showMovieDetails(
                        context: context,
                        movie: movie,
                        currentUser: currentUser,
                      ),
                      splashColor: Colors.white.withAlpha(26),
                      highlightColor: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
