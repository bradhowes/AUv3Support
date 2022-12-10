// Copyright © 2021 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <cmath>

#import "DSPHeaders/DSP.hpp"
#import "DSPHeaders/EventProcessor.hpp"

using namespace DSPHeaders;

struct MockEffect : public EventProcessor<MockEffect>
{
  MockEffect() : EventProcessor<MockEffect>() {}
  void setParameterFromEvent(const AUParameterEvent&) {}
  void doMIDIEvent(AUMIDIEvent) {}
  void doRendering(NSInteger outputBusNumber, BusBuffers, BusBuffers, AUAudioFrameCount) {}
  void doRenderingStateChanged(bool rendering) {}
};

@interface EventProcessorTests : XCTestCase
@end

@implementation EventProcessorTests

- (void)setUp {
  // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testInit {
  auto effect = MockEffect();
  AVAudioFormat* format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100.0 channels:2];
  effect.setRenderingFormat(1, format, 512);
  XCTAssertTrue(effect.isRendering());
}

- (void)testBypass {
  auto effect = MockEffect();
  AVAudioFormat* format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100.0 channels:2];
  effect.setRenderingFormat(1, format, 512);

  XCTAssertFalse(effect.isBypassed());
  effect.setBypass(true);
  XCTAssertTrue(effect.isBypassed());
  effect.setBypass(false);
  XCTAssertFalse(effect.isBypassed());
}

- (void)testRenderingState {
  auto effect = MockEffect();
  AVAudioFormat* format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100.0 channels:2];
  effect.setRenderingFormat(1, format, 512);
  XCTAssertTrue(effect.isRendering());
  effect.setRendering(false);
  XCTAssertFalse(effect.isRendering());
  effect.setRendering(true);
  XCTAssertTrue(effect.isRendering());
  effect.deallocateRenderingResources();
  XCTAssertFalse(effect.isRendering());
}

- (void)testProcessAndRender {
  auto effect = MockEffect();
  AVAudioFormat* format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100.0 channels:2];
  AUAudioFrameCount maxFrames = 512;
  effect.setRenderingFormat(2, format, maxFrames);

  AVAudioPCMBuffer* buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:format frameCapacity:maxFrames];
  AudioTimeStamp timestamp = AudioTimeStamp();
  AudioUnitRenderActionFlags flags = 0;

  AUAudioUnitStatus (^mockPullInput)(AudioUnitRenderActionFlags *actionFlags, const AudioTimeStamp *timestamp,
                                     AUAudioFrameCount frameCount, NSInteger inputBusNumber,
                                     AudioBufferList *inputData);
  mockPullInput = ^(AudioUnitRenderActionFlags *actionFlags, const AudioTimeStamp *timestamp,
                    AUAudioFrameCount frameCount, NSInteger inputBusNumber, AudioBufferList *inputData) {
    auto bufferCount = inputData->mNumberBuffers;
    for (int index = 0; index < bufferCount; ++index) {
      auto& buffer = inputData->mBuffers[index];
      auto numberOfChannels = buffer.mNumberChannels;
      auto bufferSize = buffer.mDataByteSize;
      assert(sizeof(AUValue) * frameCount == bufferSize);
      auto ptr = reinterpret_cast<AUValue*>(buffer.mData);
      for (int pos = 0; pos < bufferSize; ++pos) {
        ptr[pos] = pos;
      }
    }

    return 0;
  };

  AUAudioFrameCount frames = 4;
  NSInteger bus = 0;
  auto status = effect.processAndRender(&timestamp, frames, bus, [buffer mutableAudioBufferList], nil, mockPullInput);
  XCTAssertEqual(status, 0);
}

@end
