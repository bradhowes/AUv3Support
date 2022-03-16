// Copyright © 2021 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <vector>

#import "DSPHeaders/EventProcessor.hpp"
#import "DSPHeaders/SampleBuffer.hpp"

using namespace DSPHeaders;

@interface SampleBufferTests : XCTestCase

@end

static AVAudioFormat* format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100.0 channels:2];
static AUAudioFrameCount maxFrames = 100;

@implementation SampleBufferTests

- (void)setUp {
  // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testInit {
  SampleBuffer buffer;
  XCTAssertEqual(buffer.capacity(), 0);
  XCTAssertEqual(buffer.channelCount(), 0);
  XCTAssertEqual(buffer.mutableAudioBufferList(), nullptr);

  buffer.allocate(format, maxFrames);
  XCTAssertEqual(buffer.capacity(), maxFrames);
  XCTAssertEqual(buffer.channelCount(), 2);
  XCTAssertNotEqual(buffer.mutableAudioBufferList(), nullptr);

  buffer.release();
  XCTAssertEqual(buffer.capacity(), maxFrames);
  XCTAssertEqual(buffer.channelCount(), 0);
  XCTAssertEqual(buffer.mutableAudioBufferList(), nullptr);
}

- (void)testPullInput {

  SampleBuffer buffer;
  buffer.allocate(format, maxFrames);
  XCTAssertEqual(buffer.capacity(), maxFrames);
  XCTAssertEqual(buffer.bufferFacet().channelCount(), 2);
  XCTAssertNotEqual(buffer.mutableAudioBufferList(), nullptr);

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

  int frameCount = 10;
  XCTAssertEqual(buffer.pullInput(nullptr, nullptr, frameCount, 0, mockPullInput), 0);
  auto& facet{buffer.bufferFacet()};
  XCTAssertEqual(facet.channelCount(), 2);
}

@end