#include "edge_ai.h"
#include "model_data.h"
#include <math.h>
#include <Preferences.h>

// =========================================================================
// BỘ SUY LUẬN EDGE AI HYBRID (TRAINED MLP 12->24->12->4 + ĐỘNG HỌC + TỰ THÍCH NGHI)
// Trọng số thực được xuất tự động từ scripts/train_edge_ai.py vào src/model_data.h
// =========================================================================

EdgeAIEngine::EdgeAIEngine() : thresholdOffset(0.0f) {}

bool EdgeAIEngine::init() {
  Preferences p;
  if (p.begin("ai_cfg", true)) {
    thresholdOffset = p.getFloat("thr_off", 0.0f);
    p.end();
  }
  if (thresholdOffset < -0.06f) thresholdOffset = -0.06f;
  if (thresholdOffset > 0.10f) thresholdOffset = 0.10f;

  Serial.printf("[EDGE AI] Khoi dong mo hinh %s (12->24->12->4) | NN_W=%.2f | Thr=%.2f\n",
                EDGE_AI_MODEL_VERSION, EDGE_AI_NN_WEIGHT, getAdaptiveFallThreshold());
  return true;
}

const char* EdgeAIEngine::getModelVersion() const {
  return EDGE_AI_MODEL_VERSION;
}

float EdgeAIEngine::getAdaptiveFallThreshold() const {
  float thr = EDGE_AI_FALL_CONF_THRESH + thresholdOffset;
  if (thr < 0.56f) thr = 0.56f;
  if (thr > 0.72f) thr = 0.72f;
  return thr;
}

void EdgeAIEngine::recordUserFeedback(bool isFalseAlarm) {
  // Báo động giả: tăng nhẹ ngưỡng (+0.02, tối đa +0.10) để giảm báo giả lặp lại
  // Xác nhận ngã thật: giảm nhẹ ngưỡng (-0.015, tối thiểu -0.06) để giữ độ nhạy cao
  thresholdOffset += isFalseAlarm ? 0.02f : -0.015f;
  if (thresholdOffset < -0.06f) thresholdOffset = -0.06f;
  if (thresholdOffset > 0.10f) thresholdOffset = 0.10f;

  Preferences p;
  if (p.begin("ai_cfg", false)) {
    p.putFloat("thr_off", thresholdOffset);
    p.end();
  }
  Serial.printf("[EDGE AI] Cap nhat nguong thich nghi (%s) -> FallThr=%.3f\n",
                isFalseAlarm ? "FALSE_ALARM" : "TRUE_FALL", getAdaptiveFallThreshold());
}

void EdgeAIEngine::resetAdaptation() {
  thresholdOffset = 0.0f;
  Preferences p;
  if (p.begin("ai_cfg", false)) {
    p.putFloat("thr_off", 0.0f);
    p.end();
  }
  Serial.println("[EDGE AI] Da dat lai nguong thich nghi ve mac dinh.");
}

void EdgeAIEngine::normalizeFeatures(const float* raw, float* normalized) {
  for (int i = 0; i < EDGE_AI_INPUT_DIM; i++) {
    float stdVal = (EDGE_AI_STDS[i] > 0.001f) ? EDGE_AI_STDS[i] : 1.0f;
    normalized[i] = (raw[i] - EDGE_AI_MEANS[i]) / stdVal;
  }
}

float EdgeAIEngine::forwardNeuralNetwork(const float* normalized, float* probabilities) {
  // Layer 1: [24] = ReLU(normalized * W1 + B1)
  float h1[EDGE_AI_HIDDEN1_DIM];
  for (int j = 0; j < EDGE_AI_HIDDEN1_DIM; j++) {
    float sum = EDGE_AI_B1[j];
    for (int i = 0; i < EDGE_AI_INPUT_DIM; i++) {
      sum += normalized[i] * EDGE_AI_W1[i][j];
    }
    h1[j] = (sum > 0.0f) ? sum : 0.0f;
  }

  // Layer 2: [12] = ReLU(h1 * W2 + B2)
  float h2[EDGE_AI_HIDDEN2_DIM];
  for (int j = 0; j < EDGE_AI_HIDDEN2_DIM; j++) {
    float sum = EDGE_AI_B2[j];
    for (int i = 0; i < EDGE_AI_HIDDEN1_DIM; i++) {
      sum += h1[i] * EDGE_AI_W2[i][j];
    }
    h2[j] = (sum > 0.0f) ? sum : 0.0f;
  }

  // Output Layer: [4] = Softmax(h2 * WOUT + BOUT)
  float logits[EDGE_AI_OUTPUT_DIM];
  float maxLogit = -1e9f;
  for (int c = 0; c < EDGE_AI_OUTPUT_DIM; c++) {
    float sum = EDGE_AI_BOUT[c];
    for (int i = 0; i < EDGE_AI_HIDDEN2_DIM; i++) {
      sum += h2[i] * EDGE_AI_WOUT[i][c];
    }
    logits[c] = sum;
    if (logits[c] > maxLogit) maxLogit = logits[c];
  }

  float expSum = 0.0f;
  for (int c = 0; c < EDGE_AI_OUTPUT_DIM; c++) {
    probabilities[c] = expf(logits[c] - maxLogit);
    expSum += probabilities[c];
  }
  if (expSum > 0.0001f) {
    for (int c = 0; c < EDGE_AI_OUTPUT_DIM; c++) {
      probabilities[c] /= expSum;
    }
  }

  return probabilities[CLASS_FALL];
}

float EdgeAIEngine::evaluateKinematics(const float* raw) {
  // raw[0]: maxMotion, raw[5]: avgDropRate, raw[7]: maxBurstDropRate, raw[8]: postMotionMean
  float motionScore = 0.0f;
  if (raw[0] >= FALL_RADAR_MOTION_THRESH) {
    motionScore = (raw[0] - FALL_RADAR_MOTION_THRESH) /
                  (100.0f - FALL_RADAR_MOTION_THRESH);
    if (motionScore > 1.0f) motionScore = 1.0f;
  }

  float effectiveDrop = (raw[7] > raw[5]) ? (raw[5] * 0.55f + raw[7] * 0.45f) : raw[5];
  float velocityScore = 0.0f;
  if (effectiveDrop >= FALL_VELOCITY_THRESH_MM_S) {
    velocityScore = (effectiveDrop - FALL_VELOCITY_THRESH_MM_S) /
                    (FALL_STRONG_VELOCITY_MM_S - FALL_VELOCITY_THRESH_MM_S);
    if (velocityScore > 1.0f) velocityScore = 1.0f;
  }

  // Giảm điểm nếu sau va chạm vẫn di chuyển mạnh liên tục (đi bộ / ngồi dậy ngay)
  float postPenalty = (raw[8] > 42.0f) ? 0.72f : 1.0f;
  return (velocityScore * 0.55f + motionScore * 0.45f) * postPenalty;
}

float EdgeAIEngine::evaluateSpatialPosture(const float* raw) {
  // raw[2]: ToF High, raw[3]: ToF Mid, raw[4]: ToF Low, raw[9]: postStaticMean, raw[10]: activeGates
  float tofMid  = raw[3];
  float tofLow  = raw[4];

  float floorScore = 0.0f;
  if (tofLow > 50.0f && tofLow <= POSTURE_FLOOR_MAX_MM) {
    floorScore = 1.0f - (tofLow / (float)POSTURE_FLOOR_MAX_MM) * 0.4f;
  } else if (tofLow > POSTURE_FLOOR_MAX_MM && tofLow < SIT_HEIGHT_MIN_MM) {
    floorScore = 0.5f;
  }

  // Loại trừ ngồi ghế: Mid ở tầm 480-900mm và Low không sát sàn
  if (tofMid >= SIT_HEIGHT_MIN_MM && tofMid <= STAND_HEIGHT_MIN_MM && tofLow > POSTURE_FLOOR_MAX_MM) {
    return 0.1f;
  }

  // Loại trừ rơi đồ vật nhỏ: ít cổng radar hoạt động và hầu như không có năng lượng tĩnh nhịp thở
  if (raw[10] <= 2.0f && raw[9] < 12.0f) {
    floorScore *= 0.45f;
  }

  return floorScore;
}

AIClass EdgeAIEngine::predictWithDiagnostics(float* inputFeatures, float* confidenceScore, FallDiagnostic* diag) {
  float norm[EDGE_AI_INPUT_DIM];
  normalizeFeatures(inputFeatures, norm);

  float probs[4] = {0};
  float aiFallProb = forwardNeuralNetwork(norm, probs);

  float kinScore = evaluateKinematics(inputFeatures);
  float spatScore = evaluateSpatialPosture(inputFeatures);

  float effectiveDrop = (inputFeatures[7] > inputFeatures[5])
                            ? (inputFeatures[5] * 0.55f + inputFeatures[7] * 0.45f)
                            : inputFeatures[5];
  bool velTrig = (effectiveDrop >= FALL_VELOCITY_THRESH_MM_S);
  bool impTrig = (inputFeatures[0] >= FALL_RADAR_MOTION_THRESH);
  bool floorTrig = (inputFeatures[4] > 50.0f && inputFeatures[4] <= POSTURE_FLOOR_MAX_MM);

  // Kết hợp đa tiêu chí với trọng số NN được nâng dần khi có thêm dữ liệu thật
  const float nnW = EDGE_AI_NN_WEIGHT;
  const float remW = 1.0f - nnW;
  float finalFallConf = (aiFallProb * nnW) + (kinScore * remW * 0.60f) + (spatScore * remW * 0.40f);
  float adaptiveThr = getAdaptiveFallThreshold();

  if (diag) {
    diag->neuralScore = aiFallProb;
    diag->kinematicScore = kinScore;
    diag->spatialScore = spatScore;
    diag->finalConfidence = finalFallConf;
    for (int c = 0; c < 4; c++) diag->classProbs[c] = probs[c];
    diag->adaptiveThreshold = adaptiveThr;
    diag->velocityTrigger = velTrig;
    diag->impactTrigger = impTrig;
    diag->floorProximityTrigger = floorTrig;
  }

  const bool strongVelocity = effectiveDrop >= FALL_STRONG_VELOCITY_MM_S;
  const bool strongImpact = inputFeatures[0] >= FALL_STRONG_MOTION_THRESH;
  const bool fallEvidence = (velTrig && impTrig) ||
                            (strongVelocity && floorTrig) ||
                            (strongImpact && floorTrig) ||
                            (aiFallProb >= 0.85f && (impTrig || floorTrig));

  if (finalFallConf >= adaptiveThr && fallEvidence) {
    *confidenceScore = finalFallConf;
    return CLASS_FALL;
  }

  // Nếu không phải FALL, chọn lớp có xác suất cao nhất từ mạng nơ-ron (STAND / SIT / LIE)
  float maxP = -1.0f;
  int bestClass = CLASS_STAND;
  for (int c = 0; c < 3; c++) {
    if (probs[c] > maxP) {
      maxP = probs[c];
      bestClass = c;
    }
  }

  // Bảo vệ chống nhiễu khi ToF hoàn toàn trống (phòng không người)
  float tofDist = (inputFeatures[3] > 40.0f) ? inputFeatures[3]
                : ((inputFeatures[2] > 40.0f) ? inputFeatures[2] : inputFeatures[4]);
  if (tofDist <= 40.0f && inputFeatures[0] < 10.0f && inputFeatures[1] < 10.0f) {
    bestClass = CLASS_STAND;
    maxP = 0.95f;
  }

  *confidenceScore = maxP;
  return (AIClass)bestClass;
}

AIClass EdgeAIEngine::predict(float* inputFeatures, float* confidenceScore) {
  return predictWithDiagnostics(inputFeatures, confidenceScore, nullptr);
}
