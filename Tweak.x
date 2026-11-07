#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <dlfcn.h>
#import <notify.h>

#define PREF_ID    @"com.vn.carplayintro"
#define VIDEO_PATH @"/var/mobile/Library/CarIntro/intro.mov"
#define TEST_NOTIF "com.vn.carplayintro/test"

// ---- CarKit (private) ----
@interface CARSession : NSObject @end
@interface CARSessionStatus : NSObject
- (instancetype)initAndWaitUntilSessionUpdated;
- (CARSession *)currentSession;
- (void)addSessionObserver:(id)observer;
@end

static UIWindow *introWindow;
static AVPlayer *player;
static id endObserver;

static void stopIntro(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [player pause];
        player = nil;
        if (endObserver) {
            [[NSNotificationCenter defaultCenter] removeObserver:endObserver];
            endObserver = nil;
        }
        introWindow.hidden = YES;
        introWindow = nil;
    });
}

@interface CIHandler : NSObject
- (void)tapped;
@end
@implementation CIHandler
- (void)tapped { stopIntro(); }
@end
static CIHandler *handler;

static void playIntro(BOOL test) {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:PREF_ID];
        id en = [d objectForKey:@"enabled"];
        if (!test && en && ![en boolValue]) return;

        if (![[NSFileManager defaultManager] fileExistsAtPath:VIDEO_PATH]) {
            NSLog(@"[CarIntro] Khong tim thay video: %@", VIDEO_PATH);
            return;
        }
        stopIntro();

        // Tim man hinh CarPlay (man hinh phu). Khong thay -> dung man hinh chinh.
        UIScreen *target = nil;
        for (UIScreen *s in [UIScreen screens]) {
            if (s != [UIScreen mainScreen]) { target = s; break; }
        }
        NSLog(@"[CarIntro] screens=%@ target=%@", [UIScreen screens], target);
        if (!target || test) target = [UIScreen mainScreen];

        UIWindow *w = [[UIWindow alloc] initWithFrame:target.bounds];
        w.screen = target;
        w.windowLevel = UIWindowLevelAlert + 1000000;
        w.backgroundColor = [UIColor blackColor];

        player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:VIDEO_PATH]];
        player.muted = [[d objectForKey:@"muted"] boolValue];
        AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:player];
        layer.frame = w.bounds;
        id fill = [d objectForKey:@"fill"];
        layer.videoGravity = (!fill || [fill boolValue]) ? AVLayerVideoGravityResizeAspectFill : AVLayerVideoGravityResizeAspect;
        [w.layer addSublayer:layer];

        if (!handler) handler = [CIHandler new];
        [w addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:handler action:@selector(tapped)]];

        endObserver = [[NSNotificationCenter defaultCenter]
            addObserverForName:AVPlayerItemDidPlayToEndTimeNotification
                        object:player.currentItem queue:nil
                    usingBlock:^(NSNotification *n) { stopIntro(); }];

        w.hidden = NO;
        introWindow = w;
        [player play];
    });
}

// ---- Observer CarPlay ----
@interface CIObserver : NSObject
- (void)sessionDidConnect:(id)session;
- (void)sessionDidDisconnect:(id)session;
@end
@implementation CIObserver
- (void)sessionDidConnect:(id)session {
    NSLog(@"[CarIntro] CarPlay connected");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{ playIntro(NO); });
}
- (void)sessionDidDisconnect:(id)session {
    NSLog(@"[CarIntro] CarPlay disconnected");
    stopIntro();
}
@end

static CARSessionStatus *status;
static CIObserver *observer;
static int testToken;

%ctor {
    dlopen("/System/Library/PrivateFrameworks/CarKit.framework/CarKit", RTLD_NOW);
    Class cls = NSClassFromString(@"CARSessionStatus");
    if (cls) {
        status = [[cls alloc] initAndWaitUntilSessionUpdated];
        observer = [CIObserver new];
        [status addSessionObserver:observer];
        if ([status currentSession]) playIntro(NO); // da ket noi san luc respring
    } else {
        NSLog(@"[CarIntro] Khong load duoc CARSessionStatus");
    }
    // Nut "Phat thu" trong Cai dat
    notify_register_dispatch(TEST_NOTIF, &testToken, dispatch_get_main_queue(), ^(int t) {
        playIntro(YES);
    });
}
