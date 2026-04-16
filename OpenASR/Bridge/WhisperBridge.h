#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// A single transcribed segment returned by whisper.cpp
@interface WhisperSegment : NSObject
@property (nonatomic, copy) NSString *text;
@property (nonatomic) int64_t startMs;
@property (nonatomic) int64_t endMs;
@property (nonatomic) float confidence;
@end

/// Thin Objective-C++ wrapper around the whisper.cpp C API.
/// All inference calls are synchronous; callers must serialize access
/// (e.g., via a Swift actor) since whisper_context is not thread-safe.
@interface WhisperBridge : NSObject

/// Returns nil if the model file cannot be loaded.
- (nullable instancetype)initWithModelPath:(NSString *)path;

/// Transcribe raw 16 kHz mono Float32 PCM samples.
/// @param samples  Pointer to float array
/// @param count    Number of samples
/// @param language ISO 639-1 language code, or "auto" for auto-detection
/// @param translate If YES, output is translated to English
/// @return Array of WhisperSegment, or nil on error
- (nullable NSArray<WhisperSegment *> *)transcribePCMSamples:(const float *)samples
                                                       count:(NSInteger)count
                                                    language:(NSString *)language
                                                   translate:(BOOL)translate;

@property (nonatomic, readonly) BOOL isLoaded;

@end

NS_ASSUME_NONNULL_END
