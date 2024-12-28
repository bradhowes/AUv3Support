// Copyright © 2021-2024 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <vector>

#import "DSPHeaders/EventProcessor.hpp"

using namespace DSPHeaders;

@interface BusBufferTests : XCTestCase

@end

static AVAudioFormat* monoFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100.0 channels:1];
static AVAudioFormat* stereoFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100.0 channels:2];
static AUAudioFrameCount maxFrames = 100;

@implementation BusBufferTests

- (void)setUp {
  // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testMono {
  BusSampleBuffer buffer;
  buffer.allocate(monoFormat, maxFrames);
  BusBufferFacet facet;
  facet.setChannelCount(1);
  facet.assignBufferList(buffer.mutableAudioBufferList());
  XCTAssertEqual(1, facet.channelCount());
  BusBuffers bb{facet.busBuffers()};
  XCTAssertTrue(bb.isMono());
}

- (void)testStereo {
  BusSampleBuffer buffer;
  buffer.allocate(stereoFormat, maxFrames);
  BusBufferFacet facet;
  facet.setChannelCount(2);
  facet.assignBufferList(buffer.mutableAudioBufferList());
  XCTAssertEqual(2, facet.channelCount());
  BusBuffers bb{facet.busBuffers()};
  XCTAssertTrue(bb.isStereo());
}

- (void)testChannelCount {
  BusSampleBuffer monoBuffer;
  monoBuffer.allocate(monoFormat, maxFrames);
  BusSampleBuffer stereoBuffer;
  stereoBuffer.allocate(stereoFormat, maxFrames);

  BusBufferFacet facet;
  facet.setChannelCount(1);
  XCTAssertNoThrow(facet.assignBufferList(monoBuffer.mutableAudioBufferList()));

  facet.setChannelCount(2);
  XCTAssertNoThrow(facet.assignBufferList(stereoBuffer.mutableAudioBufferList()));

  facet.setChannelCount(1);
  XCTAssertThrows(facet.assignBufferList(stereoBuffer.mutableAudioBufferList()));
}

- (void)testFrameCount {
  BusSampleBuffer monoBuffer;
  monoBuffer.allocate(monoFormat, maxFrames);
  BusSampleBuffer stereoBuffer;
  stereoBuffer.allocate(stereoFormat, maxFrames);

  BusBufferFacet facet;
  facet.setChannelCount(1);
  facet.assignBufferList(monoBuffer.mutableAudioBufferList());
  facet.setFrameCount(10);
  XCTAssertEqual(10 * sizeof(float), monoBuffer.mutableAudioBufferList()->mBuffers[0].mDataByteSize);

  facet.setChannelCount(2);
  facet.assignBufferList(stereoBuffer.mutableAudioBufferList());
  facet.setFrameCount(13);
  XCTAssertEqual(13 * sizeof(float), stereoBuffer.mutableAudioBufferList()->mBuffers[0].mDataByteSize);
  XCTAssertEqual(13 * sizeof(float), stereoBuffer.mutableAudioBufferList()->mBuffers[1].mDataByteSize);
}

- (void)testOffset {
  BusSampleBuffer stereoBuffer;
  stereoBuffer.allocate(stereoFormat, maxFrames);

  BusBufferFacet facet;
  facet.setChannelCount(2);
  facet.assignBufferList(stereoBuffer.mutableAudioBufferList());
  BusBuffers bb1{facet.busBuffers()};
  XCTAssertTrue(bb1.isValid());
  XCTAssertTrue(bb1.isStereo());

  bb1.addAll(0, 1.0);
  bb1.addAll(1, 2.0);
  bb1.addAll(2, 3.0);
  bb1.addAll(3, 4.0);

  facet.setOffset(1);
  BusBuffers bb2{facet.busBuffers()};
  bb2.addAll(0, 4.0);
  bb2.addAll(1, 5.0);

  float* left = (float*)(stereoBuffer.mutableAudioBufferList()->mBuffers[0].mData);
  float* right = (float*)(stereoBuffer.mutableAudioBufferList()->mBuffers[1].mData);
  XCTAssertEqual(1.0, left[0]);
  XCTAssertEqual(1.0, right[0]);
  XCTAssertEqual(6.0, left[1]);
  XCTAssertEqual(6.0, right[1]);
  XCTAssertEqual(8.0, left[2]);
  XCTAssertEqual(8.0, right[2]);
  XCTAssertEqual(4.0, left[3]);
  XCTAssertEqual(4.0, right[3]);
}

- (void)testUnlinked {
  BusBufferFacet facet;
  XCTAssertThrows(facet.unlink());
}

@end
