#ifndef EDGE_AI_H
#define EDGE_AI_H

#include "config.h"

struct FallDiagnostic {
  float neuralScore;
  float kinematicScore;
  float spatialScore;
  float finalConfidence;
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

private:
  float forwardNeuralNetwork(const float* normalized, float* probabilities);
  void  normalizeFeatures(const float* raw, float* normalized);
  float evaluateKinematics(const float* raw);
  float evaluateSpatialPosture(const float* raw);
};

#endif
