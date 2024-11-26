// Copyright © 2021-2024 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>

#import "Pirkle/fxobjects.h"
#import "DSPHeaders/Biquad.hpp"

using namespace DSPHeaders;

#define SamplesEqual(A, B) XCTAssertEqualWithAccuracy(A, B, _epsilon)

@interface BiquadTests : XCTestCase
@property float epsilon;
@end

@implementation BiquadTests

- (void)setUp {
  _epsilon = 0.0001;
}

- (void)testDefaultCoefficients {
  Biquad::Coefficients zeros;
  SamplesEqual(0.0, zeros.a0);
  SamplesEqual(0.0, zeros.a1);
  SamplesEqual(0.0, zeros.a2);
  SamplesEqual(0.0, zeros.b1);
  SamplesEqual(0.0, zeros.b2);
}

- (void)testCoefficients {
  auto coefficients = Biquad::Coefficients()
  .A0(1.0)
  .A1(2.0)
  .A2(3.0)
  .B1(4.0)
  .B2(5.0);
  SamplesEqual(1.0, coefficients.a0);
  SamplesEqual(2.0, coefficients.a1);
  SamplesEqual(3.0, coefficients.a2);
  SamplesEqual(4.0, coefficients.b1);
  SamplesEqual(5.0, coefficients.b2);
}

- (void)testNOP {
  Biquad::Coefficients zeros;
  Biquad::Direct<> foo(zeros);
  SamplesEqual(0.0, foo.transform(0.0));
  SamplesEqual(0.0, foo.transform(10.0));
  SamplesEqual(0.0, foo.transform(20.0));
  SamplesEqual(0.0, foo.transform(30.0));
}

- (void)testLPF2Coefficients {
  // Test values taken from https://www.earlevel.com/main/2013/10/13/biquad-calculator-v2/
  double sampleRate = 44100.0;
  Biquad::Coefficients coefficients = Biquad::Coefficients<>::LPF2(sampleRate, 3000.0, 0.707);
  SamplesEqual(0.03478485, coefficients.a0);
  SamplesEqual(0.06956969, coefficients.a1);
  SamplesEqual(0.03478485, coefficients.a2);
  SamplesEqual(-1.40745716, coefficients.b1);
  SamplesEqual(0.54659654, coefficients.b2);
}

- (void)testHPF2Coefficients {
  // Test values taken from https://www.earlevel.com/main/2013/10/13/biquad-calculator-v2/
  double sampleRate = 44100.0;
  Biquad::Coefficients coefficients = Biquad::Coefficients<>::HPF2(sampleRate, 3000.0, 0.707);
  SamplesEqual(0.73851343, coefficients.a0);
  SamplesEqual(-1.47702685, coefficients.a1);
  SamplesEqual(0.73851343, coefficients.a2);
  SamplesEqual(-1.40745716, coefficients.b1);
  SamplesEqual(0.54659654, coefficients.b2);
}

- (void)testReset {
  double sampleRate = 44100.0;
  Biquad::Coefficients coefficients = Biquad::Coefficients<>::LPF1(sampleRate, 8000.0);
  Biquad::Direct<> filter(coefficients);
  SamplesEqual(0.00000, filter.transform(0.0));
  SamplesEqual(0.39056, filter.transform(1.0));
  filter.reset();
  SamplesEqual(0.00000, filter.transform(0.0));
}

// The following tests all compare our Biquad implementation with that found in Pirkle's code to make sure that our
// implementation seems sound.

- (void)testLPF {
  double sampleRate = 44100.0;
  double frequency = 8000.0;
  
  Biquad::Coefficients coefficients = Biquad::Coefficients<>::LPF1(sampleRate, frequency);
  Biquad::Direct<> filter(coefficients);
  Pirkle::AudioFilterParameters params;
  params.algorithm = Pirkle::filterAlgorithm::kLPF1;
  params.fc = frequency;
  Pirkle::AudioFilter pirkle;
  pirkle.setParameters(params);
  
  for (int counter = 0; counter < 7200; ++counter) {
    double input = std::sin(counter/10.0 * Pirkle::kPi / 180.0 );
    double output1 = filter.transform(input);
    double output2 = pirkle.processAudioSample(input);
    SamplesEqual(output1, output2);
  }
}

// Compare the output from Will Pirkle's implementation and our own to make sure we have not messed anything up.

- (void)testLPF2 {
  double sampleRate = 44100.0;
  double frequency = 4000.0;
  
  Biquad::Coefficients coefficients = Biquad::Coefficients<>::LPF2(sampleRate, frequency, 0.707);
  Biquad::Direct<> filter(coefficients);
  Pirkle::AudioFilterParameters params;
  params.algorithm = Pirkle::filterAlgorithm::kLPF2;
  params.fc = frequency;
  Pirkle::AudioFilter pirkle;
  pirkle.setParameters(params);

  // Run over 2 cycles of a sin wave with 0.1 degree step.
  for (int counter = 0; counter < 7200; ++counter) {
    double input = std::sin(counter/10.0 * Pirkle::kPi / 180.0 );
    double output1 = filter.transform(input);
    double output2 = pirkle.processAudioSample(input);
    SamplesEqual(output1, output2);
  }
}

// Compare the output from Will Pirkle's implementation and our own to make sure we have not messed anything up.

- (void)testHPF2 {
  double sampleRate = 44100.0;
  double frequency = 8000.0;
  
  Biquad::Coefficients coefficients = Biquad::Coefficients<>::HPF2(sampleRate, frequency, 0.707);
  Biquad::Direct<> filter(coefficients);
  Pirkle::AudioFilterParameters params;
  params.algorithm = Pirkle::filterAlgorithm::kHPF2 ;
  params.fc = frequency;
  Pirkle::AudioFilter pirkle;
  pirkle.setParameters(params);
  
  for (int counter = 0; counter < 7200; ++counter) {
    double input = std::sin(counter/10.0 * Pirkle::kPi / 180.0 );
    double output1 = filter.transform(input);
    double output2 = pirkle.processAudioSample(input);
    SamplesEqual(output1, output2);
  }
}

- (void)testHPF {
  double sampleRate = 44100.0;
  double frequency = 8000.0;
  
  Biquad::Coefficients coefficients = Biquad::Coefficients<>::HPF1(sampleRate, frequency);
  Biquad::Direct<> filter(coefficients);
  Pirkle::AudioFilterParameters params;
  params.algorithm = Pirkle::filterAlgorithm::kHPF1;
  params.fc = frequency;
  Pirkle::AudioFilter pirkle;
  pirkle.setParameters(params);
  
  for (int counter = 0; counter < 7200; ++counter) {
    double input = std::sin(counter/10.0 * Pirkle::kPi / 180.0 );
    double output1 = filter.transform(input);
    double output2 = pirkle.processAudioSample(input);
    SamplesEqual(output1, output2);
  }
}

- (void)testAPF1 {
  double sampleRate = 44100.0;
  double frequency = 4000.0;
  
  Biquad::Coefficients coefficients = Biquad::Coefficients<>::APF1(sampleRate, frequency);
  Biquad::Direct<> filter(coefficients);
  Pirkle::AudioFilterParameters params;
  params.algorithm = Pirkle::filterAlgorithm::kAPF1;
  params.fc = frequency;
  Pirkle::AudioFilter pirkle;
  pirkle.setParameters(params);
  
  for (int counter = 0; counter < 7200; ++counter) {
    double input = std::sin(counter/10.0 * M_PI / 180.0 );
    double output1 = filter.transform(input);
    double output2 = pirkle.processAudioSample(input);
    SamplesEqual(output1, output2);
  }
}

- (void)testAPF2 {
  double sampleRate = 44100.0;
  double frequency = 4000.0;
  
  Biquad::Coefficients coefficients = Biquad::Coefficients<>::APF2(sampleRate, frequency, 0.707);
  Biquad::Direct<> filter(coefficients);
  Pirkle::AudioFilterParameters params;
  params.algorithm = Pirkle::filterAlgorithm::kAPF2;
  params.fc = frequency;
  Pirkle::AudioFilter pirkle;
  pirkle.setParameters(params);
  
  for (int counter = 0; counter < 7200; ++counter) {
    double input = std::sin(counter/10.0 * M_PI / 180.0 );
    double output1 = filter.transform(input);
    double output2 = pirkle.processAudioSample(input);
    SamplesEqual(output1, output2);
  }
}

- (void)testRamping {
  double sampleRate = 44100.0;
  double frequency = 4000.0;
  size_t rampCount = 8;

  Biquad::Coefficients coefficients{Biquad::Coefficients<>::LPF2(sampleRate, frequency, 0.707)};
  Biquad::Direct<> filter{coefficients};

  Pirkle::AudioFilterParameters params;
  params.algorithm = Pirkle::filterAlgorithm::kLPF2;
  params.fc = frequency;
  Pirkle::AudioFilter pirkle;
  pirkle.setParameters(params);

  // Run over 2 cycles of a sin wave with 0.1 degree step.
  int counter;
  auto inputGenerator = [](int counter) -> double { return std::sin(counter/10.0 * Pirkle::kPi / 180.0 ); };

  for (counter = 0; counter < 7200; ++counter) {
    double input = inputGenerator(counter);
    double output1 = filter.transform(input);
    double output2 = pirkle.processAudioSample(input);
    // double output3 = ramping.transform(input);
    SamplesEqual(output1, output2);
  }

  // Ramp to a new value
  coefficients = Biquad::Coefficients<>::LPF2(sampleRate, 2000.0, 0.707);
  filter.setCoefficients(coefficients);
  Biquad::Direct<> ramping{coefficients};
  ramping.setCoefficients(coefficients, rampCount);

  // We expect that for rampCount samples the ramped and un-ramped filters would not match. However, even after the
  // ramping is complete, the ramped filter still has memory that must get cycled out before it begins to emit values
  // like the un-ramped version.
  for (counter = 0; counter < (rampCount + 1) * 2; ++counter) {
    double input = inputGenerator(counter);
    XCTAssertNotEqualWithAccuracy(filter.transform(input), ramping.transform(input), _epsilon);
  }

  // From this point on, they filters should match.
  for (; counter < 7200; ++counter) {
    double input = inputGenerator(counter);
    XCTAssertEqualWithAccuracy(filter.transform(input), ramping.transform(input), _epsilon);
  }
}

@end
