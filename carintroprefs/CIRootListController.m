#import <Preferences/PSListController.h>
#import <PhotosUI/PhotosUI.h>
#import <notify.h>

#define VIDEO_DIR  @"/var/mobile/Library/CarIntro"
#define VIDEO_PATH @"/var/mobile/Library/CarIntro/intro.mov"

@interface CIRootListController : PSListController <PHPickerViewControllerDelegate>
@end

@implementation CIRootListController

- (NSArray *)specifiers {
    if (!_specifiers) _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    return _specifiers;
}

- (void)alert:(NSString *)msg {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *a = [UIAlertController alertControllerWithTitle:@"CarPlay Intro"
            message:msg preferredStyle:UIAlertControllerStyleAlert];
        [a addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:a animated:YES completion:nil];
    });
}

- (void)chooseVideo {
    PHPickerConfiguration *c = [[PHPickerConfiguration alloc] init];
    c.filter = [PHPickerFilter videosFilter];
    c.selectionLimit = 1;
    PHPickerViewController *p = [[PHPickerViewController alloc] initWithConfiguration:c];
    p.delegate = self;
    [self presentViewController:p animated:YES completion:nil];
}

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (results.count == 0) return;
    [results.firstObject.itemProvider loadFileRepresentationForTypeIdentifier:@"public.movie"
        completionHandler:^(NSURL *url, NSError *err) {
            if (!url) { [self alert:@"Khong doc duoc video."]; return; }
            NSFileManager *fm = [NSFileManager defaultManager];
            [fm createDirectoryAtPath:VIDEO_DIR withIntermediateDirectories:YES attributes:nil error:nil];
            [fm removeItemAtPath:VIDEO_PATH error:nil];
            NSError *e = nil;
            if ([fm copyItemAtURL:url toURL:[NSURL fileURLWithPath:VIDEO_PATH] error:&e])
                [self alert:@"Da dat video intro moi."];
            else
                [self alert:[NSString stringWithFormat:@"Loi copy: %@", e.localizedDescription]];
        }];
}

- (void)removeVideo {
    [[NSFileManager defaultManager] removeItemAtPath:VIDEO_PATH error:nil];
    [self alert:@"Da xoa video."];
}

- (void)testPlay {
    notify_post("com.vn.carplayintro/test");
}

@end
