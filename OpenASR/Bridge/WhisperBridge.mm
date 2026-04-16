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

    struct whisper_full_params params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);

    // Language
    std::string langStr = [language UTF8String];
    if (langStr == "auto") {
        params.language = nullptr;  // auto-detect
        params.detect_language = true;
    } else {
        params.language = langStr.c_str();
        params.detect_language = false;
    }

    params.translate = translate;
    params.print_realtime = false;
    params.print_progress = false;
    params.print_timestamps = true;
    params.print_special = false;
    params.no_context = true;
    params.single_segment = false;
    params.n_threads = (int)[[NSProcessInfo processInfo] processorCount];
    params.token_timestamps = false;

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
