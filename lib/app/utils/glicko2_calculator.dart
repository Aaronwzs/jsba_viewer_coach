import 'dart:math';

import 'package:jsba_app/app/model/player_rating_model.dart';

class Glicko2Calculator {
  static const double _scale = 173.7178;
  static const double _tau = 0.5;
  static const double _epsilon = 0.000001;
  static const double _minRd = 30.0;

  static ({PlayerRatingModel player, PlayerRatingModel opponent}) calculate({
    required PlayerRatingModel player,
    required PlayerRatingModel opponent,
    required bool playerWon,
  }) {
    final now = DateTime.now();
    final playerScore = playerWon ? 1.0 : 0.0;
    final opponentScore = playerWon ? 0.0 : 1.0;

    final updatedPlayer = _updateRating(
      subject: player,
      opponent: opponent,
      score: playerScore,
    );

    final updatedOpponent = _updateRating(
      subject: opponent,
      opponent: player,
      score: opponentScore,
    );

    return (
      player: updatedPlayer.copyWith(
        matchCount: player.matchCount + 1,
        winCount: playerWon ? player.winCount + 1 : player.winCount,
        lossCount: playerWon ? player.lossCount : player.lossCount + 1,
        lastMatchDate: now,
        updatedAt: now,
      ),
      opponent: updatedOpponent.copyWith(
        matchCount: opponent.matchCount + 1,
        winCount: playerWon ? opponent.winCount : opponent.winCount + 1,
        lossCount: playerWon ? opponent.lossCount + 1 : opponent.lossCount,
        lastMatchDate: now,
        updatedAt: now,
      ),
    );
  }

  static PlayerRatingModel _updateRating({
    required PlayerRatingModel subject,
    required PlayerRatingModel opponent,
    required double score,
  }) {
    final mu = (subject.rating - 1500.0) / _scale;
    final phi = subject.ratingDeviation / _scale;
    final sigma = subject.volatility;
    final muJ = (opponent.rating - 1500.0) / _scale;
    final phiJ = opponent.ratingDeviation / _scale;

    final g = _g(phiJ);
    final e = _e(mu, muJ, g);
    final v = 1.0 / (g * g * e * (1.0 - e));
    final delta = v * g * (score - e);
    final sigmaNew = _updateVolatility(phi, sigma, v, delta);
    final phiStar = sqrt(phi * phi + sigmaNew * sigmaNew);
    final phiNew = 1.0 / sqrt(1.0 / (phiStar * phiStar) + 1.0 / v);
    final muNew = mu + phiNew * phiNew * g * (score - e);
    final ratingNew = _scale * muNew + 1500.0;
    final rdNew = (_scale * phiNew).clamp(_minRd, 350.0);

    return subject.copyWith(
      rating: ratingNew,
      ratingDeviation: rdNew,
      volatility: sigmaNew,
    );
  }

  static double _g(double phi) {
    return 1.0 / sqrt(1.0 + 3.0 * phi * phi / (pi * pi));
  }

  static double _e(double mu, double muJ, double g) {
    return 1.0 / (1.0 + exp(-g * (mu - muJ)));
  }

  static double _updateVolatility(
    double phi,
    double sigma,
    double v,
    double delta,
  ) {
    final a = log(sigma * sigma);
    final deltaSq = delta * delta;
    final phiSq = phi * phi;
    final tauSq = _tau * _tau;

    double f(double x) {
      final ex = exp(x);
      final numerator = ex * (deltaSq - phiSq - v - ex);
      final denominator = 2.0 * pow(phiSq + v + ex, 2.0);
      return (numerator / denominator) - ((x - a) / tauSq);
    }

    var aValue = a;
    double bValue;

    if (deltaSq > phiSq + v) {
      bValue = log(deltaSq - phiSq - v);
    } else {
      var k = 1.0;
      while (f(a - k * _tau) < 0 && k < 100) {
        k += 1.0;
      }
      bValue = a - k * _tau;
    }

    var fA = f(aValue);
    var fB = f(bValue);

    while ((bValue - aValue).abs() > _epsilon) {
      final cValue = aValue + (aValue - bValue) * fA / (fB - fA);
      final fC = f(cValue);

      if (fC * fB <= 0) {
        aValue = bValue;
        fA = fB;
      } else {
        fA /= 2.0;
      }

      bValue = cValue;
      fB = fC;
    }

    return exp(aValue / 2.0);
  }
}
