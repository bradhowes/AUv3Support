// Copyright © 2021 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <cmath>

#import "DSPHeaders/DSP.hpp"
#import "DSPHeaders/EventProcessor.hpp"

using namespace DSPHeaders;

struct MockEffect : public EventProcessor<MockEffect>
{
  MockEffect() : EventProcessor<MockEffect>() {}

  void doParameterEvent(const AUParameterEvent&) {}

  void doMIDIEvent(const AUMIDIEvent&) {}

  void doRendering(NSInteger outputBusNumber, BusBuffers, BusBuffers, AUAudioFrameCount frameCount) {
    frameCounts_.push_back(frameCount);
  }

  void doRenderingStateChanged(bool rendering) {}

  std::vector<AUAudioFrameCount> frameCounts_{};
};

// To validate the API of the MockEffect
ValidatedKernel<MockEffect> _;

@interface EventProcessorTests : XCTestCase
@property MockEffect* effect;
@end

@implementation EventProcessorTests

- (void)setUp {
  self.effect = new MockEffect();
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
  self.effect->setRendering(false);
  XCTAssertFalse(self.effect->isRendering());
  self.effect->setRendering(true);
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

- (void)testRampingDuration {
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
  
  auto status = self.effect->processAndRender(&timestamp, frames, 0, outputData, eventList, mockPullInput);
  XCTAssertEqual(status, 0);
  XCTAssertEqual(self.effect->frameCounts_.size(), 5);
  XCTAssertEqual(self.effect->frameCounts_[0], 1);
  XCTAssertEqual(self.effect->frameCounts_[1], 1);
  XCTAssertEqual(self.effect->frameCounts_[2], 1);
  XCTAssertEqual(self.effect->frameCounts_[3], 1);
  XCTAssertEqual(self.effect->frameCounts_[4], 508);
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

  // Do 2 frames. Should be split into 1 frame render calls
  auto status = self.effect->processAndRender(&timestamp, 2, 0, outputData, eventList, mockPullInput);
  XCTAssertEqual(status, 0);
  XCTAssertEqual(self.effect->frameCounts_.size(), 2);
  XCTAssertEqual(self.effect->frameCounts_[0], 1);
  XCTAssertEqual(self.effect->frameCounts_[1], 1);

  self.effect->setRendering(false);
  self.effect->setRendering(true);

  // Do 10 frames. Should be done as 1 10-frame render call.
  status = self.effect->processAndRender(&timestamp, 10, 0, outputData, nullptr, mockPullInput);
  XCTAssertEqual(status, 0);
  XCTAssertEqual(self.effect->frameCounts_.size(), 3);
  XCTAssertEqual(self.effect->frameCounts_[0], 1);
  XCTAssertEqual(self.effect->frameCounts_[1], 1);
  XCTAssertEqual(self.effect->frameCounts_[2], 10);
}

@end
