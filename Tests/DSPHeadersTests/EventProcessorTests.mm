// Copyright © 2021-2024 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <cmath>

#import "DSPHeaders/DSP.hpp"
#import "DSPHeaders/EventProcessor.hpp"
#import "DSPHeaders/Parameters/Float.hpp"

using namespace DSPHeaders;

struct MockEffect : public EventProcessor<MockEffect>
{
  using super = EventProcessor<MockEffect>;

  MockEffect() : super() {
    registerParameter(param_);
  }

  bool doSetImmediateParameterValue(AUParameterAddress address, AUValue value, AUAudioFrameCount duration) {
    if (address == 1) param_.setImmediate(value, duration);
    return address == 1;
  }

  bool doSetPendingParameterValue(AUParameterAddress address, AUValue value) {
    if (address == 1) param_.setPending(value);
    return address == 1;
  }

  AUValue doGetImmediateParameterValue(AUParameterAddress address) const {
    return address == 1 ? param_.getImmediate() : 0.0;
  }

  AUValue doGetPendingParameterValue(AUParameterAddress address) const {
    return address == 1 ? param_.getPending() : 0.0;
  }

  void doRendering(NSInteger outputBusNumber, BusBuffers, BusBuffers, AUAudioFrameCount frameCount) {
    paramValues_.push_back(param_.frameValue());
    frameCounts_.push_back(frameCount);
  }

  void checkForTreeBasedParameterChanges() { super::checkForTreeBasedParameterChanges(); }

  Parameters::Float param_{1, 0.0};
  std::vector<AUAudioFrameCount> paramValues_{};
  std::vector<AUAudioFrameCount> frameCounts_{};
};

// To validate the API of the MockEffect
ValidatedKernel<MockEffect> _mockEffect_minMockEffect;

@interface EventProcessorTests : XCTestCase
@property MockEffect* effect;
@end

@implementation EventProcessorTests {
  AUValue epsilon;
}

- (void)setUp {
  epsilon = 1.0E-6;
  self.effect = new MockEffect();
  [self setRenderingFormat];
}

- (void)setRenderingFormat {
  AVAudioFormat* format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100.0 channels:2];
  AUAudioFrameCount maxFrames = 512;
  self.effect->setRenderingFormat(1, format, maxFrames);
}

- (void)tearDown {
  delete self.effect;
}

- (void)testInit {
  XCTAssertTrue(self.effect->isRendering());
}

- (void)testBypass {
  XCTAssertFalse(self.effect->isBypassed());
  self.effect->setBypass(true);
  XCTAssertTrue(self.effect->isBypassed());
  self.effect->setBypass(false);
  XCTAssertFalse(self.effect->isBypassed());
}

- (void)testRenderingState {
  XCTAssertTrue(self.effect->isRendering());
  self.effect->deallocateRenderResources();
  XCTAssertFalse(self.effect->isRendering());
}

AURenderPullInputBlock mockPullInput = ^(AudioUnitRenderActionFlags* actionFlags, const AudioTimeStamp *timestamp,
                                         AUAudioFrameCount frameCount, NSInteger inputBusNumber,
                                         AudioBufferList* inputData) {
  auto bufferCount = inputData->mNumberBuffers;
  XCTAssertEqual(bufferCount, 2);
  for (int bufferIndex = 0; bufferIndex < bufferCount; ++bufferIndex) {
    auto& buffer = inputData->mBuffers[bufferIndex];
    auto numberOfChannels = buffer.mNumberChannels;
    XCTAssertEqual(numberOfChannels, 1);
    auto bufferSize = buffer.mDataByteSize;
    XCTAssertEqual(sizeof(AUValue) * frameCount, bufferSize);
    auto ptr = static_cast<AUValue*>(buffer.mData);
    for (int frameIndex = 0; frameIndex < frameCount; ++frameIndex) {
      ptr[frameIndex] = frameIndex;
    }
  }

  return 0;
};

- (void)testProcessAndRenderNoPullInput {
  self.effect->setBypass(true);
  AVAudioFormat* format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100.0 channels:2];
  AUAudioFrameCount maxFrames = 512;

  AudioTimeStamp timestamp = AudioTimeStamp();

  // Test without a pullInput routine
  AUAudioFrameCount frames = maxFrames;
  AVAudioPCMBuffer* buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:format frameCapacity:maxFrames];
  AudioBufferList *outputData = [buffer mutableAudioBufferList];
  auto status = self.effect->processAndRender(&timestamp, frames, 0, outputData, nullptr, nullptr);
  XCTAssertEqual(status, 0);
  XCTAssertTrue(self.effect->frameCounts_.empty());

  AudioBuffer& left = outputData->mBuffers[0];
  XCTAssertEqual(left.mNumberChannels, 1);
  XCTAssertEqual(left.mDataByteSize, maxFrames * sizeof(AUValue));

  AudioBuffer& right = outputData->mBuffers[1];
  XCTAssertEqual(right.mNumberChannels, 1);
  XCTAssertEqual(right.mDataByteSize, maxFrames * sizeof(AUValue));
}

- (void)testProcessAndRenderWithPullInput {
  self.effect->setBypass(true);
  AVAudioFormat* format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100.0 channels:2];
  AUAudioFrameCount maxFrames = 512;

  AudioTimeStamp timestamp = AudioTimeStamp();

  // Test without a pullInput routine
  AUAudioFrameCount frames = maxFrames;
  AVAudioPCMBuffer* buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:format frameCapacity:maxFrames];
  AudioBufferList *outputData = [buffer mutableAudioBufferList];
  auto status = self.effect->processAndRender(&timestamp, frames, 0, outputData, nullptr, mockPullInput);
  XCTAssertEqual(status, 0);
  XCTAssertTrue(self.effect->frameCounts_.empty());

  AudioBuffer& left = outputData->mBuffers[0];
  XCTAssertEqual(left.mNumberChannels, 1);
  XCTAssertEqual(left.mDataByteSize, maxFrames * sizeof(AUValue));
  auto ptr = static_cast<AUValue*>(left.mData);
  XCTAssertEqual(ptr[maxFrames - 1], 511.0);

  AudioBuffer& right = outputData->mBuffers[1];
  XCTAssertEqual(right.mNumberChannels, 1);
  XCTAssertEqual(right.mDataByteSize, maxFrames * sizeof(AUValue));
  ptr = static_cast<AUValue*>(right.mData);
  XCTAssertEqual(ptr[maxFrames - 1], 511.0);
}

- (void)testProcessAndRenderingInPlace {
  self.effect->setBypass(true);
  AVAudioFormat* format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100.0 channels:2];
  AUAudioFrameCount maxFrames = 512;

  AudioTimeStamp timestamp = AudioTimeStamp();

  // Test without a pullInput routine
  AUAudioFrameCount frames = maxFrames;
  AVAudioPCMBuffer* buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:format frameCapacity:maxFrames];
  AudioBufferList *outputData = [buffer mutableAudioBufferList];

  outputData->mBuffers[0].mData = nil;
  outputData->mBuffers[1].mData = nil;

  auto status = self.effect->processAndRender(&timestamp, frames, 0, outputData, nullptr, mockPullInput);
  XCTAssertEqual(status, 0);
  XCTAssertTrue(self.effect->frameCounts_.empty());

  AudioBuffer& left = outputData->mBuffers[0];
  XCTAssertEqual(left.mNumberChannels, 1);
  XCTAssertEqual(left.mDataByteSize, maxFrames * sizeof(AUValue));
  auto ptr = static_cast<AUValue*>(left.mData);
  XCTAssertEqual(ptr[maxFrames - 1], 511.0);

  AudioBuffer& right = outputData->mBuffers[1];
  XCTAssertEqual(right.mNumberChannels, 1);
  XCTAssertEqual(right.mDataByteSize, maxFrames * sizeof(AUValue));
  ptr = static_cast<AUValue*>(right.mData);
  XCTAssertEqual(ptr[maxFrames - 1], 511.0);
}

- (void)testEventRampingDuration {
  AVAudioFormat* format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100.0 channels:2];
  AUAudioFrameCount maxFrames = 512;
  AudioTimeStamp timestamp = AudioTimeStamp();
  AUAudioFrameCount frames = maxFrames;
  AVAudioPCMBuffer* buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:format frameCapacity:maxFrames];
  AudioBufferList *outputData = [buffer mutableAudioBufferList];
  outputData->mBuffers[0].mData = nil;
  outputData->mBuffers[1].mData = nil;

  // Set a parameter that ramps for 4 samples
  AUParameterEvent* rampingEvent = new AUParameterEvent();
  rampingEvent->next = nullptr;
  rampingEvent->eventSampleTime = -1;
  rampingEvent->parameterAddress = 1;
  rampingEvent->rampDurationSampleFrames = 4;
  rampingEvent->value = 10;

  AURenderEvent* eventList = reinterpret_cast<AURenderEvent*>(rampingEvent);
  eventList->head.eventType = AURenderEventParameterRamp;

  // Do rendering for 512 samples. Expectation is 4 1-sample render calls and then 1 508 sample render.
  auto status = self.effect->processAndRender(&timestamp, frames, 0, outputData, eventList, mockPullInput);
  XCTAssertEqual(status, 0);
  XCTAssertEqual(self.effect->param_.getImmediate(), 10.0);
  XCTAssertEqual(self.effect->param_.getPending(), 10.0);
  XCTAssertEqual(self.effect->frameCounts_.size(), 5);
  XCTAssertEqual(self.effect->frameCounts_[0], 1);
  XCTAssertEqual(self.effect->frameCounts_[1], 1);
  XCTAssertEqual(self.effect->frameCounts_[2], 1);
  XCTAssertEqual(self.effect->frameCounts_[3], 1);
  XCTAssertEqual(self.effect->frameCounts_[4], 508);
}

- (void)testUIRampingDuration {
  AVAudioFormat* format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100.0 channels:2];
  AUAudioFrameCount maxFrames = 512;
  AudioTimeStamp timestamp = AudioTimeStamp();
  AUAudioFrameCount frames = maxFrames;
  AVAudioPCMBuffer* buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:format frameCapacity:maxFrames];
  AudioBufferList *outputData = [buffer mutableAudioBufferList];
  outputData->mBuffers[0].mData = nil;
  outputData->mBuffers[1].mData = nil;

  // Set a parameter that ramps for 4 samples
  self.effect->param_.setPending(882.0);
  XCTAssertEqual(self.effect->param_.getPending(), 882.0);
  XCTAssertEqual(self.effect->param_.getImmediate(), 0.0);
  XCTAssertTrue(self.effect->param_.canRamp());

  XCTAssertEqual(self.effect->rampRemaining(), 0);
  XCTAssertEqual(self.effect->treeBasedRampDuration(), 882);

  // Do rendering for 512 samples. Expectation is all are 1-sample render calls since we ramp for 882.
  auto status = self.effect->processAndRender(&timestamp, frames, 0, outputData, nullptr, mockPullInput);
  XCTAssertEqual(status, 0);
  XCTAssertTrue(self.effect->isRamping());
  XCTAssertEqual(self.effect->frameCounts_.size(), 512);
  XCTAssertEqual(self.effect->frameCounts_[0], 1);
  XCTAssertEqual(self.effect->rampRemaining(), 882 - 512);
  XCTAssertEqualWithAccuracy(self.effect->param_.frameValue(false), 512.0, 1.0e-6);
  self.effect->frameCounts_.clear();

  // Do rendering for 512 samples. Expectation is 370 are 1-sample render calls (882 - 512) and 1 is 142.
  status = self.effect->processAndRender(&timestamp, frames, 0, outputData, nullptr, mockPullInput);
  XCTAssertEqual(status, 0);
  XCTAssertFalse(self.effect->isRamping());
  XCTAssertEqual(self.effect->frameCounts_.size(), 371);
  XCTAssertEqual(self.effect->frameCounts_[0], 1);
  XCTAssertEqual(self.effect->frameCounts_[369], 1);
  XCTAssertEqual(self.effect->frameCounts_[370], 142);
  XCTAssertFalse(self.effect->isRamping());
  XCTAssertEqualWithAccuracy(self.effect->param_.frameValue(false), 882.0, 1.0e-6);
}

- (void)testRampingDurationClearedOnRenderStateChange {
  AVAudioFormat* format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100.0 channels:2];
  AUAudioFrameCount maxFrames = 512;
  AudioTimeStamp timestamp = AudioTimeStamp();
  AUAudioFrameCount frames = maxFrames;
  AVAudioPCMBuffer* buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:format frameCapacity:maxFrames];
  AudioBufferList *outputData = [buffer mutableAudioBufferList];
  outputData->mBuffers[0].mData = nil;
  outputData->mBuffers[1].mData = nil;

  AUParameterEvent* rampingEvent = new AUParameterEvent();
  rampingEvent->next = nullptr;
  rampingEvent->eventSampleTime = -1;
  rampingEvent->parameterAddress = 1;
  rampingEvent->rampDurationSampleFrames = 4;
  rampingEvent->value = 10;

  AURenderEvent* eventList = reinterpret_cast<AURenderEvent*>(rampingEvent);
  eventList->head.eventType = AURenderEventParameterRamp;

  // Do 2 frames. Should be split into 2 1-frame render calls.
  auto status = self.effect->processAndRender(&timestamp, 2, 0, outputData, eventList, mockPullInput);
  XCTAssertEqual(status, 0);
  XCTAssertEqual(self.effect->frameCounts_.size(), 2);
  XCTAssertEqual(self.effect->frameCounts_[0], 1);
  XCTAssertEqual(self.effect->frameCounts_[1], 1);

  // Stop / start rendering
  self.effect->deallocateRenderResources();
  [self setRenderingFormat];

  // Do 10 frames. Should be done as 1 10-frame render call.
  status = self.effect->processAndRender(&timestamp, 10, 0, outputData, nullptr, mockPullInput);
  XCTAssertEqual(status, 0);
  XCTAssertEqual(self.effect->frameCounts_.size(), 3);
  XCTAssertEqual(self.effect->frameCounts_[0], 1);
  XCTAssertEqual(self.effect->frameCounts_[1], 1);
  XCTAssertEqual(self.effect->frameCounts_[2], 10);
}

- (void)testDetectParameterChange {
  self.effect->param_.setPending(123.5);
  XCTAssertEqualWithAccuracy(self.effect->param_.getPending(), 123.5, epsilon);
  XCTAssertEqual(self.effect->param_.getImmediate(), 0.0);
  XCTAssertFalse(self.effect->isRamping());
  self.effect->checkForTreeBasedParameterChanges();
  XCTAssertTrue(self.effect->isRamping());
}

- (void)testRenderDisableClearsRamping {
  self.effect->param_.setPending(123.5);
  self.effect->checkForTreeBasedParameterChanges();
  XCTAssertTrue(self.effect->isRamping());
  self.effect->deallocateRenderResources();
  XCTAssertFalse(self.effect->isRamping());
}

struct MockEffectWithRenderingStateChanged : public EventProcessor<MockEffectWithRenderingStateChanged>
{
  using super = EventProcessor<MockEffectWithRenderingStateChanged>;

  MockEffectWithRenderingStateChanged() : super() { registerParameters({param1_, param2_}); }

  void doRendering(NSInteger outputBusNumber, BusBuffers, BusBuffers, AUAudioFrameCount frameCount) {}
  void doRenderingStateChanged(bool rendering) { ++renderingStateChanges_; }
  void checkForTreeBasedParameterChanges() { super::checkForTreeBasedParameterChanges(); }

  Parameters::Float param1_{0, 0.0};
  Parameters::Float param2_{1, 0.0};
  int renderingStateChanges_{0};
};

ValidatedKernel<MockEffectWithRenderingStateChanged> _mockEffectWithRenderingStateChanged;

- (void)testRenderingStateChanged {
  auto effect = new MockEffectWithRenderingStateChanged();
  XCTAssertEqual(effect->renderingStateChanges_, 0);
  AVAudioFormat* format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100.0 channels:2];
  AUAudioFrameCount maxFrames = 512;
  effect->setRenderingFormat(1, format, maxFrames);
  XCTAssertEqual(effect->renderingStateChanges_, 1);
  effect->deallocateRenderResources();
  XCTAssertEqual(effect->renderingStateChanges_, 2);
}

- (void)testRenderingStateChangeClearsRamping {
  auto effect = new MockEffectWithRenderingStateChanged();
  AVAudioFormat* format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100.0 channels:2];
  AUAudioFrameCount maxFrames = 512;
  effect->setRenderingFormat(1, format, maxFrames);

  effect->setParameterValue(0, 123.45);
  effect->setParameterValue(1, 987);
  effect->checkForTreeBasedParameterChanges();
  XCTAssertTrue(effect->isRamping());
  XCTAssertEqualWithAccuracy(effect->param1_.frameValue(), 0.139967, 0.00001);
  XCTAssertEqualWithAccuracy(effect->param1_.frameValue(), 0.279933, 0.00001);
  XCTAssertEqualWithAccuracy(effect->param2_.frameValue(), 1.119028, 0.00001);
  XCTAssertEqualWithAccuracy(effect->param2_.frameValue(), 2.238075, 0.00001);
  effect->deallocateRenderResources();
  XCTAssertFalse(effect->isRamping());
  XCTAssertEqualWithAccuracy(effect->param1_.frameValue(), 123.45, 0.00001);
  XCTAssertEqualWithAccuracy(effect->param1_.frameValue(), 123.45, 0.00001);
  XCTAssertEqualWithAccuracy(effect->param2_.frameValue(), 987.0, 0.00001);
}

struct MockEffectWithMIDI : public EventProcessor<MockEffectWithMIDI>
{
  using super = EventProcessor<MockEffectWithMIDI>;

  MockEffectWithMIDI() : super() { registerParameter(param_); }

  void doMIDIEvent(const AUMIDIEvent&) { midiEvents_ += 1; }

  void doRendering(NSInteger outputBusNumber, BusBuffers, BusBuffers, AUAudioFrameCount frameCount) {}

  Parameters::Float param_{0};
  int midiEvents_{0};
};

- (void)testMIDIEventProcessing {
  auto effect = new MockEffectWithMIDI();
  XCTAssertEqual(effect->midiEvents_, 0);
  AVAudioFormat* format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100.0 channels:2];
  AUAudioFrameCount maxFrames = 512;
  effect->setRenderingFormat(1, format, maxFrames);

  AudioTimeStamp timestamp = AudioTimeStamp();
  AUAudioFrameCount frames = maxFrames;
  AVAudioPCMBuffer* buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:format frameCapacity:maxFrames];
  AudioBufferList *outputData = [buffer mutableAudioBufferList];
  outputData->mBuffers[0].mData = nil;
  outputData->mBuffers[1].mData = nil;

  AUMIDIEvent* midiEvent = new AUMIDIEvent();
  midiEvent->next = nullptr;
  midiEvent->eventSampleTime = -1;

  AURenderEvent* eventList = reinterpret_cast<AURenderEvent*>(midiEvent);
  eventList->head.eventType = AURenderEventMIDI;

  auto status = effect->processAndRender(&timestamp, maxFrames, 0, outputData, eventList, mockPullInput);
  XCTAssertEqual(status, 0);
  XCTAssertEqual(effect->midiEvents_, 1);
}

@end
