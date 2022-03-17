// Copyright © 2021 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <cmath>

#import "DSPHeaders/DSP.hpp"
#import "DSPHeaders/EventProcessor.hpp"

using namespace DSPHeaders;

struct MockEffect : public EventProcessor<MockEffect>
{
  MockEffect() : EventProcessor<MockEffect>("Foo") {}
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

- (void)testProcessAndRender {
  auto effect = MockEffect();
  AVAudioFormat* format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100.0 channels:2];
  AUAudioFrameCount maxFrames = 512;
  effect.setRenderingFormat(1, format, maxFrames);

  AVAudioPCMBuffer* buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:format frameCapacity:maxFrames];
  AudioTimeStamp timestamp = AudioTimeStamp();
  AudioUnitRenderActionFlags flags = 0;

  AUAudioFrameCount frames = 4;
  NSInteger bus = 0;
  // auto status = effect.processAndRender(&timestamp, frames, bus, [buffer mutableAudioBufferList], nil, pullInputBlock);
}

@end
