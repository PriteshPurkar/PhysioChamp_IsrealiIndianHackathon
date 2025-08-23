/// Simple region groupings by your row layout:
/// Rows:
/// 1: 1..3
/// 2: 4..7
/// 3: 8..11
/// 4: 12..15
/// 5: 16..19
/// 6: 20..23
/// 7: 24..25
/// 8: 26..27
/// 9: 28..29
/// 10: 30..32
/// 11: 33..35
/// 12: 36..38
/// 13: 39..40

const toeIndices   = <int>{
  1,2,3, 4,5,6,7, // rows 1–2
};

const midIndices   = <int>{
  8,9,10,11, 12,13,14,15, 16,17,18,19, 20,21,22,23, 24,25, 26,27 // rows 3–8
};

const heelIndices  = <int>{
  28,29, 30,31,32, 33,34,35, 36,37,38, 39,40 // rows 9–13
};

String regionForSensor(int idx) {
  if (toeIndices.contains(idx)) return 'toe';
  if (heelIndices.contains(idx)) return 'heel';
  return 'mid';
}