import 'dart:math' as math;

/// Enumeration of consumption methods.
enum ConsumptionMethod {
  joint,
  bong,
  vape,
  dab,
}

/// A single inhalation event (a puff) logged by the user.
class InhalationEvent {
  /// Timestamp (ms since epoch) when the inhalation occurred.
  final int timestampMs;

  /// Consumption method used.
  final ConsumptionMethod method;

  /// Duration of the inhale in seconds.
  final double inhaleDurationSec;

  /// User's perceived inhalation strength (0.25 to 2.0; default 1.0).
  final double perceivedStrength;

  InhalationEvent({
    required this.timestampMs,
    required this.method,
    required this.inhaleDurationSec,
    required this.perceivedStrength,
  });
}

/// A THC model that estimates the user's current THC content (in mg) using:
/// 1. Estimated THC delivery (based on method, duration, perceived strength).
/// 2. A diminishing absorption function for long inhales.
/// 3. Exponential elimination with demographic adjustments.
class THCModelNoMgInput {
  // -------------------------------------
  // 1. User Demographics & Metabolism
  // -------------------------------------

  /// Baseline elimination half-life (hours) for the reference user.
  /// For the psychoactive phase, studies often report an initial half-life of ~1.5 hours.
  double baseHalfLifeHours;

  /// Age in years.
  final int ageYears;

  /// "male" or "female".
  final String sex;

  /// Body fat percentage (e.g. 15.0 means 15%).
  final double bodyFatPercent;

  /// Daily caloric burn (e.g., 2000 kcal for an average adult).
  final double dailyCaloricBurn;

  // -------------------------------------
  // 2. Absorption Parameters
  // -------------------------------------

  /// Maximum fraction of THC that can be absorbed from a single hit,
  /// if the user inhales/holds long enough (typically ~95%).
  final double maxAbsorptionFraction;

  /// Rate constant for the saturating absorption function (per second).
  /// Using ~1.0 means ~95% absorption is achieved in about 3 seconds.
  final double absorptionRateConstant;

  // -------------------------------------
  // 3. Logged Inhalation Events
  // -------------------------------------

  final List<InhalationEvent> _events = [];

  // -------------------------------------
  // 4. Constructor
  // -------------------------------------

  THCModelNoMgInput({
    this.baseHalfLifeHours = 1.5,
    this.ageYears = 30,
    this.sex = "male",
    this.bodyFatPercent = 15.0,
    this.dailyCaloricBurn = 2000.0,
    this.maxAbsorptionFraction = 0.95,
    this.absorptionRateConstant = 1.0,
  });

  // -------------------------------------
  // 5. Base THC Delivery Rates (mg/sec at perceivedStrength = 1.0)
  // -------------------------------------
  //
  // These values are approximate estimates from scientific literature:
  // - Joint: ~1.5 mg/s
  // - Bong: ~2.0 mg/s
  // - Vape: ~2.5 mg/s
  // - Dab: ~5.0 mg/s
  //
  final Map<ConsumptionMethod, double> _methodBaseRateMgPerSec = {
    ConsumptionMethod.joint: 1.5,
    ConsumptionMethod.bong: 2.0,
    ConsumptionMethod.vape: 2.5,
    ConsumptionMethod.dab: 5.0,
  };

  // -------------------------------------
  // 6. Log an Inhalation Event
  // -------------------------------------

  /// Log an inhalation event using the consumption method, duration, and perceived strength.
  void logInhalation({
    required DateTime timestamp,
    required ConsumptionMethod method,
    required double inhaleDurationSec,
    required double perceivedStrength,
  }) {
    _events.add(
      InhalationEvent(
        timestampMs: timestamp.millisecondsSinceEpoch,
        method: method,
        inhaleDurationSec: inhaleDurationSec,
        perceivedStrength: perceivedStrength,
      ),
    );
  }

  // -------------------------------------
  // 7. Elimination Rate Calculation
  // -------------------------------------

  /// Base elimination rate per hour derived from [baseHalfLifeHours]:
  /// k = ln(2) / t1/2.
  double get _baseEliminationRatePerHour {
    return math.log(2) / baseHalfLifeHours;
  }

  /// Adjusted elimination rate per hour, modified by demographics.
  double get _adjustedEliminationRatePerHour {
    double k = _baseEliminationRatePerHour;

    // Age: older individuals tend to clear THC more slowly.
    if (ageYears >= 50) {
      k *= 0.8; // 20% slower for 50+.
    } else if (ageYears <= 25) {
      k *= 1.1; // 10% faster for younger users.
    }

    // Sex: females may have a slightly slower elimination rate.
    if (sex.toLowerCase() == "female") {
      k *= 0.9; // ~10% slower.
    }

    // Body fat: higher body fat => slower elimination.
    double refBodyFat = 15.0;
    double fatFactor = (refBodyFat / bodyFatPercent).clamp(0.5, 1.5);
    k *= fatFactor;

    // Metabolic rate: higher daily caloric burn => faster elimination.
    double refBurn = 2000.0;
    double burnFactor = (dailyCaloricBurn / refBurn).clamp(0.5, 2.0);
    k *= burnFactor;

    return k;
  }

  /// Adjusted elimination rate per millisecond.
  double get _adjustedEliminationRatePerMs {
    // 1 hour = 3,600,000 ms.
    return _adjustedEliminationRatePerHour / 3_600_000.0;
  }

  // -------------------------------------
  // 8. THC Delivery and Absorption Estimation
  // -------------------------------------

  /// Estimate the raw amount of THC (in mg) delivered by an inhalation event,
  /// based on the method, duration, and perceived strength.
  double _rawThcDelivered(InhalationEvent e) {
    double baseRate = _methodBaseRateMgPerSec[e.method] ?? 1.0;
    // Scale base rate by perceived strength.
    double scaledRate = baseRate * e.perceivedStrength;
    // Total THC delivered is base rate * duration.
    return scaledRate * e.inhaleDurationSec;
  }

  /// Diminishing absorption fraction as a function of inhale duration.
  /// Models that most THC is absorbed within the first few seconds.
  double _absorptionFraction(double inhaleDurationSec) {
    double fraction = maxAbsorptionFraction *
        (1 - math.exp(-absorptionRateConstant * inhaleDurationSec));
    return fraction.clamp(0.0, 1.0);
  }

  /// Actual mg of THC absorbed from an event (before elimination).
  double _absorbedThc(InhalationEvent e) {
    double rawMg = _rawThcDelivered(e);
    double frac = _absorptionFraction(e.inhaleDurationSec);
    return rawMg * frac;
  }

  // -------------------------------------
  // 9. Query Current THC Content
  // -------------------------------------

  /// Returns the estimated THC content (in mg) in the user's system at the given [queryTimeMs].
  double getTHCContentAt(int queryTimeMs) {
    double totalMg = 0.0;

    for (final event in _events) {
      if (event.timestampMs <= queryTimeMs) {
        double dtMs = (queryTimeMs - event.timestampMs).toDouble();
        double initialAbsorbed = _absorbedThc(event);

        // Exponential decay: remaining THC = initial * e^(-k * dt).
        double decayFactor = math.exp(-_adjustedEliminationRatePerMs * dtMs);
        totalMg += initialAbsorbed * decayFactor;
      }
    }

    // return totalMg * 1000000000.0;
    return totalMg;
  }

  /// Convenience method to query THC content using a DateTime.
  double getTHCContentAtTime(DateTime queryTime) {
    return getTHCContentAt(queryTime.millisecondsSinceEpoch);
  }

  // -------------------------------------
  // 7. Events Management
  // -------------------------------------

  /// Updates the tracked inhalation events with a new list.
  /// This replaces all existing events with the provided list.
  void updateEvents(List<InhalationEvent> events) {
    _events.clear();
    _events.addAll(events);
  }
}
