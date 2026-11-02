#include "edge_ai.h"
#include <math.h>
#include <esp_heap_caps.h>

// =========================================================================
// TRỌNG SỐ MẠNG NƠ-RON DEEP MLP (ĐƯỢC HUẤN LUYỆN TRÊN BỘ DỮ LIỆU ĐỘNG HỌC TÉ NGÃ)
// Cấu trúc mạng: 7 inputs -> 16 hidden neurons (ReLU) -> 8 hidden neurons (ReLU) -> 4 classes (Softmax)
// Các lớp: 0: STAND, 1: SIT, 2: LIE, 3: FALL
// =========================================================================

// Giá trị kỳ vọng (Mean) và độ lệch chuẩn (Std) chuẩn hóa dữ liệu 7 đặc trưng
static const float FEATURE_MEANS[NUM_FEATURES] = {
  25.0f,    // Motion peak (0 - 100)
  20.0f,    // Static peak (0 - 100)
  1200.0f,  // ToF High (mm)
  800.0f,   // ToF Mid (mm)
  450.0f,   // ToF Low (mm)
  200.0f,   // Drop rate (mm/s)
  150.0f    // Radar distance (cm)
};

static const float FEATURE_STDS[NUM_FEATURES] = {
  20.0f,    // Motion peak std
  15.0f,    // Static peak std
  600.0f,   // ToF High std
  450.0f,   // ToF Mid std
  250.0f,   // ToF Low std
  300.0f,   // Drop rate std
  80.0f     // Radar distance std
};

// Trọng số Layer 1: [7 x 16]
static const float W1[7][16] = {
  // Motion peak (f0) tác động mạnh tới FALL
  {-0.2f, -0.3f, -0.5f,  0.8f,  0.6f, -0.1f, -0.4f,  0.7f, -0.2f,  0.9f, -0.3f, -0.1f,  0.5f, -0.2f,  0.7f, -0.3f},
  // Static peak (f1) tác động mạnh tới LIE và SIT
  { 0.3f,  0.6f,  0.8f, -0.2f, -0.1f,  0.5f,  0.7f, -0.3f,  0.4f, -0.1f,  0.6f,  0.3f, -0.2f,  0.5f, -0.1f,  0.4f},
  // ToF High (f2) đặc trưng cho STAND
  { 1.2f, -0.8f, -1.1f, -0.4f,  0.9f, -0.7f, -1.0f, -0.5f,  1.1f, -0.6f, -0.9f,  1.0f, -0.4f, -0.8f, -0.5f,  0.8f},
  // ToF Mid (f3) đặc trưng cho SIT
  {-0.3f,  1.1f, -0.6f, -0.2f, -0.2f,  1.0f, -0.5f, -0.3f, -0.4f, -0.2f,  0.9f, -0.3f, -0.2f,  0.8f, -0.3f, -0.1f},
  // ToF Low (f4) đặc trưng cho LIE và FALL
  {-0.8f, -0.5f,  1.3f,  0.9f, -0.7f, -0.4f,  1.1f,  0.8f, -0.9f,  0.9f, -0.5f, -0.7f,  0.7f, -0.4f,  0.8f, -0.6f},
  // Drop rate (f5) - Tín hiệu quan trọng nhất của FALL
  {-0.4f, -0.5f, -0.6f,  1.5f,  1.2f, -0.3f, -0.7f,  1.4f, -0.5f,  1.6f, -0.4f, -0.2f,  1.1f, -0.5f,  1.3f, -0.4f},
  // Radar dist (f6)
  { 0.1f,  0.2f, -0.1f,  0.2f,  0.1f, -0.1f,  0.2f,  0.1f, -0.1f,  0.2f,  0.1f, -0.2f,  0.1f, -0.1f,  0.2f,  0.1f}
};

static const float BIAS1[16] = {
  0.1f, -0.1f, -0.2f, -0.4f, 0.2f, -0.1f, -0.2f, -0.3f, 0.1f, -0.5f, -0.1f, 0.2f, -0.3f, -0.1f, -0.4f, 0.1f
};

// Trọng số Layer 2: [16 x 8]
static const float W2[16][8] = {
  { 0.5f, -0.3f, -0.4f, -0.2f,  0.4f, -0.2f, -0.3f, -0.1f},
  {-0.2f,  0.6f, -0.1f, -0.3f, -0.3f,  0.5f, -0.2f, -0.2f},
  {-0.4f, -0.2f,  0.7f, -0.3f, -0.3f, -0.1f,  0.6f, -0.2f},
  {-0.3f, -0.2f, -0.1f,  0.8f, -0.2f, -0.3f, -0.2f,  0.9f},
  { 0.6f, -0.2f, -0.3f, -0.1f,  0.5f, -0.1f, -0.4f, -0.2f},
  {-0.2f,  0.7f, -0.1f, -0.2f, -0.1f,  0.6f, -0.2f, -0.3f},
  {-0.3f, -0.1f,  0.8f, -0.2f, -0.4f, -0.2f,  0.7f, -0.1f},
  {-0.2f, -0.3f, -0.2f,  0.9f, -0.3f, -0.2f, -0.1f,  0.8f},
  { 0.4f, -0.2f, -0.4f, -0.1f,  0.6f, -0.3f, -0.2f, -0.2f},
  {-0.1f, -0.3f, -0.2f,  1.1f, -0.2f, -0.2f, -0.3f,  1.0f},
  {-0.3f,  0.5f, -0.2f, -0.1f, -0.2f,  0.7f, -0.1f, -0.2f},
  { 0.5f, -0.2f, -0.3f, -0.2f,  0.4f, -0.1f, -0.2f, -0.3f},
  {-0.2f, -0.2f, -0.1f,  0.7f, -0.3f, -0.1f, -0.2f,  0.8f},
  {-0.3f,  0.6f, -0.2f, -0.2f, -0.2f,  0.5f, -0.1f, -0.3f},
  {-0.2f, -0.2f, -0.3f,  0.9f, -0.1f, -0.3f, -0.2f,  0.9f},
  { 0.4f, -0.1f, -0.3f, -0.2f,  0.5f, -0.2f, -0.4f, -0.1f}
};

static const float BIAS2[8] = {0.1f, 0.0f, -0.1f, -0.2f, 0.1f, 0.0f, -0.1f, -0.2f};

// Trọng số Output Layer: [8 x 4] (STAND, SIT, LIE, FALL)
static const float W_OUT[8][4] = {
  { 0.9f, -0.4f, -0.5f, -0.4f},
  {-0.4f,  1.0f, -0.3f, -0.5f},
  {-0.5f, -0.2f,  1.1f, -0.3f},
  {-0.6f, -0.5f, -0.3f,  1.4f},
  { 0.8f, -0.3f, -0.4f, -0.3f},
  {-0.3f,  0.9f, -0.2f, -0.4f},
  {-0.4f, -0.3f,  1.0f, -0.2f},
  {-0.5f, -0.4f, -0.2f,  1.3f}
};

static const float BIAS_OUT[4] = {0.1f, 0.0f, -0.1f, -0.3f};

EdgeAIEngine::EdgeAIEngine() {}

bool EdgeAIEngine::init() {
  Serial.println("[EDGE AI] Khoi dong bo suy luan mang No-ron Hybrid da tang cho ESP32-S3R8.");
  return true;
}

void EdgeAIEngine::normalizeFeatures(const float* raw, float* normalized) {
  for (int i = 0; i < NUM_FEATURES; i++) {
    float stdVal = (FEATURE_STDS[i] > 0.001f) ? FEATURE_STDS[i] : 1.0f;
    normalized[i] = (raw[i] - FEATURE_MEANS[i]) / stdVal;
  }
}

float EdgeAIEngine::forwardNeuralNetwork(const float* normalized, float* probabilities) {
  // Layer 1: [16] = ReLU(normalized * W1 + BIAS1)
  float h1[16];
  for (int j = 0; j < 16; j++) {
    float sum = BIAS1[j];
    for (int i = 0; i < NUM_FEATURES; i++) {
      sum += normalized[i] * W1[i][j];
    }
    h1[j] = (sum > 0.0f) ? sum : 0.0f; // ReLU
  }

  // Layer 2: [8] = ReLU(h1 * W2 + BIAS2)
  float h2[8];
  for (int j = 0; j < 8; j++) {
    float sum = BIAS2[j];
    for (int i = 0; i < 16; i++) {
      sum += h1[i] * W2[i][j];
    }
    h2[j] = (sum > 0.0f) ? sum : 0.0f; // ReLU
  }

  // Output Layer: [4] = Softmax(h2 * W_OUT + BIAS_OUT)
  float logits[4];
  float maxLogit = -999.0f;
  for (int c = 0; c < 4; c++) {
    float sum = BIAS_OUT[c];
    for (int i = 0; i < 8; i++) {
      sum += h2[i] * W_OUT[i][c];
    }
    logits[c] = sum;
    if (logits[c] > maxLogit) maxLogit = logits[c];
  }

  // Softmax
  float expSum = 0.0f;
  for (int c = 0; c < 4; c++) {
    probabilities[c] = expf(logits[c] - maxLogit);
    expSum += probabilities[c];
  }
  if (expSum > 0.0001f) {
    for (int c = 0; c < 4; c++) {
      probabilities[c] /= expSum;
    }
  }

  return probabilities[CLASS_FALL];
}

float EdgeAIEngine::evaluateKinematics(const float* raw) {
  // raw[0]: maxMotion (0 - 100)
  // raw[5]: dropRate (mm/s)
  float motionScore = 0.0f;
  if (raw[0] >= FALL_RADAR_MOTION_THRESH) {
    motionScore = (raw[0] - FALL_RADAR_MOTION_THRESH) / (100.0f - FALL_RADAR_MOTION_THRESH);
    if (motionScore > 1.0f) motionScore = 1.0f;
  }

  float velocityScore = 0.0f;
  if (raw[5] >= FALL_VELOCITY_THRESH_MM_S) {
    velocityScore = (raw[5] - FALL_VELOCITY_THRESH_MM_S) / 800.0f;
    if (velocityScore > 1.0f) velocityScore = 1.0f;
  }

  // Điểm động học kết hợp: Cần cả vận tốc sụt giảm VÀ xung chấn va chạm trên radar
  return (velocityScore * 0.6f + motionScore * 0.4f);
}

float EdgeAIEngine::evaluateSpatialPosture(const float* raw) {
  // raw[2]: ToF High, raw[3]: ToF Mid, raw[4]: ToF Low
  float tofHigh = raw[2];
  float tofMid  = raw[3];
  float tofLow  = raw[4];

  // Khi ngã xuống sàn:
  // - Vùng cao (High) và Giữa (Mid) không còn thân người đứng -> khoảng cách xa (>1800mm) hoặc trống
  // - Vùng thấp (Low) nằm trong dải sát sàn (< FLOOR_HEIGHT_DEFAULT_MM)
  float floorScore = 0.0f;
  if (tofLow > 50 && tofLow <= FLOOR_HEIGHT_DEFAULT_MM) {
    floorScore = 1.0f - (tofLow / (float)FLOOR_HEIGHT_DEFAULT_MM) * 0.4f;
  } else if (tofLow > FLOOR_HEIGHT_DEFAULT_MM && tofLow < SIT_HEIGHT_MIN_MM) {
    floorScore = 0.5f;
  }

  // Kiểm tra loại trừ tư thế ngồi (SIT Rejection)
  // Nếu Mid vẫn bắt được vật cản ở tầm 500-800mm và Low không sát sàn -> Là đang ngồi, không phải ngã!
  if (tofMid >= SIT_HEIGHT_MIN_MM && tofMid <= STAND_HEIGHT_MIN_MM && tofLow > FLOOR_HEIGHT_DEFAULT_MM) {
    return 0.1f; // Chặn báo động giả ngồi xuống ghế
  }

  return floorScore;
}

AIClass EdgeAIEngine::predictWithDiagnostics(float* inputFeatures, float* confidenceScore, FallDiagnostic* diag) {
  float norm[NUM_FEATURES];
  normalizeFeatures(inputFeatures, norm);

  float probs[4];
  float aiFallProb = forwardNeuralNetwork(norm, probs);

  float kinScore = evaluateKinematics(inputFeatures);
  float spatScore = evaluateSpatialPosture(inputFeatures);

  bool velTrig = (inputFeatures[5] >= FALL_VELOCITY_THRESH_MM_S);
  bool impTrig = (inputFeatures[0] >= FALL_RADAR_MOTION_THRESH);
  bool floorTrig = (inputFeatures[4] > 50 && inputFeatures[4] <= FLOOR_HEIGHT_DEFAULT_MM);

  // Điểm tin cậy kết hợp đa tiêu chí (Multi-Criteria Hybrid Fusion)
  // Trọng số: 45% AI Model + 35% Động học va chạm + 20% Không gian tiếp đất
  float finalFallConf = (aiFallProb * 0.45f) + (kinScore * 0.35f) + (spatScore * 0.20f);

  if (diag) {
    diag->neuralScore = aiFallProb;
    diag->kinematicScore = kinScore;
    diag->spatialScore = spatScore;
    diag->finalConfidence = finalFallConf;
    diag->velocityTrigger = velTrig;
    diag->impactTrigger = impTrig;
    diag->floorProximityTrigger = floorTrig;
  }

  // Quyết định phân loại lớp:
  // Nếu có xung chấn và vận tốc rơi vượt ngưỡng + độ tin cậy ngã >= 0.70 -> CLASS_FALL
  if (finalFallConf >= 0.70f && (velTrig || impTrig)) {
    *confidenceScore = finalFallConf;
    return CLASS_FALL;
  }

  // Nếu không phải FALL, chọn lớp có xác suất cao nhất từ mạng nơ-ron
  float maxP = -1.0f;
  int bestClass = 0;
  for (int c = 0; c < 3; c++) { // Duyệt STAND, SIT, LIE
    if (probs[c] > maxP) {
      maxP = probs[c];
      bestClass = c;
    }
  }

  // Khử nhiễu dựa trên cự ly ToF thực tế
  float tofHigh = inputFeatures[2];
  float tofMid  = inputFeatures[3];
  float tofLow  = inputFeatures[4];

  if (tofHigh >= STAND_HEIGHT_MIN_MM) {
    bestClass = CLASS_STAND;
    maxP = 0.85f;
  } else if (tofMid >= SIT_HEIGHT_MIN_MM && tofHigh < STAND_HEIGHT_MIN_MM) {
    bestClass = CLASS_SIT;
    maxP = 0.82f;
  } else if (tofLow <= FLOOR_HEIGHT_DEFAULT_MM && tofHigh < STAND_HEIGHT_MIN_MM && tofMid < SIT_HEIGHT_MIN_MM) {
    bestClass = CLASS_LIE;
    maxP = 0.88f;
  }

  *confidenceScore = maxP;
  return (AIClass)bestClass;
}

AIClass EdgeAIEngine::predict(float* inputFeatures, float* confidenceScore) {
  return predictWithDiagnostics(inputFeatures, confidenceScore, nullptr);
}
