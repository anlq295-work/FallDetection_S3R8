#ifndef EDGE_AI_H
#define EDGE_AI_H

#include "config.h"

struct FallDiagnostic {
  float neuralScore;
  float kinematicScore;
  float spatialScore;
  float finalConfidence;
  float classProbs[4];
  float adaptiveThreshold;
  bool  velocityTrigger;
  bool  impactTrigger;
  bool  floorProximityTrigger;
};

class EdgeAIEngine {
public:
  EdgeAIEngine();
  bool init();
  AIClass predict(float* inputFeatures, float* confidenceScore);
  AIClass predictWithDiagnostics(float* inputFeatures, float* confidenceScore, FallDiagnostic* diag);

  // Tự thích nghi ngưỡng cá nhân hóa theo từng phòng (lưu vào NVS Flash, có giới hạn an toàn)
  void  recordUserFeedback(bool isFalseAlarm);
  void  resetAdaptation();
  float getAdaptiveFallThreshold() const;
  const char* getModelVersion() const;

private:
  float thresholdOffset; // Biên an toàn [-0.06, +0.10]
  float forwardNeuralNetwork(const float* normalized, float* probabilities);
  void  normalizeFeatures(const float* raw, float* normalized);
  float evaluateKinematics(const float* raw);
  float evaluateSpatialPosture(const float* raw);
};

#endif
