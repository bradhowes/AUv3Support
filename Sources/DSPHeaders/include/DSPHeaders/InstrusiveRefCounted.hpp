#pragma once

#import <atomic>

/**
 Manager of a reference counter for an instance of a class T. Used when importing C++ classes as Swift reference
 types.
 */
template<class T>
class IntrusiveRefCounted {
public:

  /// Construct instance with initial reference count
  IntrusiveRefCounted() : referenceCount_(1) {}

  IntrusiveRefCounted(const IntrusiveRefCounted &) = delete;

  /// Increment the reference count for the instance.
  void retain() { ++referenceCount_; }

  /// Decrement the reference count for the instance. If it was 1 (or less) then delete the instance.
  void release() {
    if (referenceCount_ < 2) {
      delete this;
    } else {
      --referenceCount_;
    }
  }

private:
  std::atomic<int> referenceCount_;
};
