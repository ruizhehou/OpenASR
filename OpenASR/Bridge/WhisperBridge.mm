#import "WhisperBridge.h"
#include "whisper.h"
#include <vector>
#include <string>

@implementation WhisperSegment
@end

@implementation WhisperBridge {
    struct whisper_context *_ctx;
}

- (nullable instancetype)initWithModelPath:(NSString *)path {
    self = [super init];
    if (!self) return nil;

    struct whisper_context_params params = whisper_context_default_params();
    params.use_gpu = true;  // Use Metal GPU if available

    _ctx = whisper_init_from_file_with_params([path UTF8String], params);
    if (!_ctx) {
        NSLog(@"[WhisperBridge] Failed to load model at: %@", path);
        return nil;
    }

    NSLog(@"[WhisperBridge] Model loaded successfully from: %@", path);
    return self;
}

- (BOOL)isLoaded {
    return _ctx != nullptr;
}

- (nullable NSArray<WhisperSegment *> *)transcribePCMSamples:(const float *)samples
                                                       count:(NSInteger)count
                                                    language:(NSString *)language
                                                   translate:(BOOL)translate {
    if (!_ctx || count <= 0) return nil;

    struct whisper_full_params params = whisper_full_default_params(WHISPER_SAMPLING_BEAM_SEARCH);

    // Language — langStr must outlive params since params.language points into it
    std::string langStr = [language UTF8String];
    const char *langCStr = nullptr;
    if (langStr == "auto") {
        params.language = nullptr;  // auto-detect
        params.detect_language = true;
    } else {
        langCStr = langStr.c_str();
        params.language = langCStr;
        params.detect_language = false;
    }

    params.translate        = translate;
    params.print_realtime   = false;
    params.print_progress   = false;
    params.print_timestamps = true;
    params.print_special    = false;
    params.no_context       = true;
    params.single_segment   = false;
    params.n_threads        = (int)[[NSProcessInfo processInfo] processorCount];
    params.token_timestamps = false;

    // Relax filtering thresholds so quiet/short speech still produces segments.
    // Default no_speech_thold=0.6 is very aggressive — lower it to reduce false silence detection.
    params.no_speech_thold = 0.3f;
    // Default logprob_thold=-1.0 filters low-probability segments — lower to keep more output.
    params.logprob_thold   = -2.0f;
    // Default entropy_thold=2.4 filters high-entropy (confused) output — raise to be more permissive.
    params.entropy_thold   = 3.0f;
    // Suppress blank-only segments but keep real speech.
    params.suppress_blank  = true;

    int result = whisper_full(_ctx, params, samples, (int)count);
    if (result != 0) {
        NSLog(@"[WhisperBridge] whisper_full failed with code: %d", result);
        return nil;
    }

    int segCount = whisper_full_n_segments(_ctx);
    NSMutableArray<WhisperSegment *> *segments = [NSMutableArray arrayWithCapacity:segCount];

    for (int i = 0; i < segCount; i++) {
        const char *text = whisper_full_get_segment_text(_ctx, i);
        int64_t t0 = whisper_full_get_segment_t0(_ctx, i);
        int64_t t1 = whisper_full_get_segment_t1(_ctx, i);

        WhisperSegment *seg = [[WhisperSegment alloc] init];
        seg.text = text ? [NSString stringWithUTF8String:text] : @"";
        seg.startMs = t0 * 10;  // whisper timestamps are in centiseconds
        seg.endMs   = t1 * 10;
        seg.confidence = 1.0f;  // greedy sampling has no per-segment probability

        [segments addObject:seg];
    }

    return [segments copy];
}

- (void)dealloc {
    if (_ctx) {
        whisper_free(_ctx);
        _ctx = nullptr;
    }
}

@end
