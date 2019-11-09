//
//  SGPhotoBrowserViewController.m
//  SGSecurityAlbum
//
//  Created by soulghost on 9/7/2016.
//  Copyright © 2016 soulghost. All rights reserved.
//

#import "SGPhotoBrowserViewController.h"
#import "QBImagePickerController.h"
#import <Photos/Photos.h>
#import "DNImagePickerController.h"
#import "DNImagePicker.h"


@interface SGPhotoBrowserViewController () <QBImagePickerControllerDelegate,DNImagePickerControllerDelegate>

@property (nonatomic, strong) NSArray<SGPhotoModel *> *photoModels;

@end

@implementation SGPhotoBrowserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self commonInit];
    [self loadFiles];
}

- (void)commonInit {
    self.numberOfPhotosPerRow = 4;
    self.title = [SGFileUtil getFileNameFromPath:self.rootPath];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addClick)];
    WS();
    [self setNumberOfPhotosHandlerBlock:^NSInteger{
        return weakSelf.photoModels.count;
    }];
    [self setphotoAtIndexHandlerBlock:^SGPhotoModel *(NSInteger index) {
        return weakSelf.photoModels[index];
    }];
    [self setReloadHandlerBlock:^{
        [weakSelf loadFiles];
    }];
}

- (void)loadFiles {
    NSFileManager *mgr = [NSFileManager defaultManager];
    NSString *photoPath = [SGFileUtil photoPathForRootPath:self.rootPath];
    NSString *thumbPath = [SGFileUtil thumbPathForRootPath:self.rootPath];
    NSMutableArray *photoModels = @[].mutableCopy;
    NSArray *fileNames = [mgr contentsOfDirectoryAtPath:photoPath error:nil];
    for (NSUInteger i = 0; i < fileNames.count; i++) {
        NSString *fileName = fileNames[i];
        NSURL *photoURL = [NSURL fileURLWithPath:[photoPath stringByAppendingPathComponent:fileName]];
        NSURL *thumbURL = [NSURL fileURLWithPath:[thumbPath stringByAppendingPathComponent:fileName]];
        SGPhotoModel *model = [SGPhotoModel new];
        model.photoURL = photoURL;
        model.thumbURL = thumbURL;
        [photoModels addObject:model];
    }
    self.photoModels = photoModels;
    [self reloadData];
}

#pragma mark - UIBarButtonItem Action
- (void)addClick {
//    QBImagePickerController *picker = [QBImagePickerController new];
//    picker.delegate = self;
//    picker.allowsMultipleSelection = YES;
////    picker.showsNumberOfSelectedAssets = YES;
//    [self presentViewController:picker animated:YES completion:nil];
//
    
    DNImagePickerController *imagePicker = [[DNImagePickerController alloc] init];
    imagePicker.imagePickerDelegate = self;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

#pragma mark - QBImagePickerController Delegate
- (void)imagePickerController:(QBImagePickerController *)imagePickerController didFinishPickingMediaWithInfo:(id)info{
    NSArray *assets = (NSArray *)info;
    PHImageRequestOptions *op = [[PHImageRequestOptions alloc] init];
    op.synchronous = YES;
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:imagePickerController.view];
    [imagePickerController.view addSubview:hud];
    hud.mode = MBProgressHUDModeAnnularDeterminate;
    [hud showAnimated:YES];
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSString *dateStr = [formatter stringFromDate:[NSDate date]];
    __block  NSInteger progressCount = 0;
    NSMutableArray *importAssets = @[].mutableCopy;
    NSInteger progressSum = assets.count * 2;
    void (^hudProgressBlock)(NSInteger currentProgressCount) = ^(NSInteger progressCount) {
        dispatch_async(dispatch_get_main_queue(), ^{
            hud.progress = (double)progressCount / progressSum;
            if (progressCount == progressSum) {
                [imagePickerController dismissViewControllerAnimated:YES completion:nil];
                [hud hideAnimated:YES];
                [self loadFiles];
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    [PHAssetChangeRequest deleteAssets:importAssets];
                } completionHandler:nil];
            }
        });
    };
    for (int i = 0; i < assets.count; i++) {
        PHAsset *asset = assets[i];
        [importAssets addObject:asset];
        PHCachingImageManager *imageManager = [[PHCachingImageManager alloc] init];
        NSString *fileName = [[NSString stringWithFormat:@"%@%@",dateStr,@(i)] MD5];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [imageManager requestImageForAsset:asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFill options:op resultHandler:^(UIImage *result, NSDictionary *info) {
                
                [SGFileUtil savePhoto:result toRootPath:self.rootPath withName:fileName];
                hudProgressBlock(++progressCount);
            }];
            [imageManager requestImageForAsset:asset targetSize:CGSizeMake(120, 120) contentMode:PHImageContentModeAspectFill options:op resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                [SGFileUtil saveThumb:result toRootPath:self.rootPath withName:fileName];
                hudProgressBlock(++progressCount);
            }];
        });
    }
}
- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didFinishPickingAssets:(NSArray *)assets {
//    PHImageRequestOptions *op = [[PHImageRequestOptions alloc] init];
//    op.synchronous = YES;
//    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:imagePickerController.view];
//    [imagePickerController.view addSubview:hud];
//    hud.mode = MBProgressHUDModeAnnularDeterminate;
//    [hud showAnimated:YES];
//    NSDateFormatter *formatter = [NSDateFormatter new];
//    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
//    NSString *dateStr = [formatter stringFromDate:[NSDate date]];
//    __block  NSInteger progressCount = 0;
//    NSMutableArray *importAssets = @[].mutableCopy;
//    NSInteger progressSum = assets.count * 2;
//    void (^hudProgressBlock)(NSInteger currentProgressCount) = ^(NSInteger progressCount) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            hud.progress = (double)progressCount / progressSum;
//            if (progressCount == progressSum) {
//                [imagePickerController dismissViewControllerAnimated:YES completion:nil];
//                [hud hideAnimated:YES];
//                [self loadFiles];
//                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
//                    [PHAssetChangeRequest deleteAssets:importAssets];
//                } completionHandler:nil];
//            }
//        });
//    };
//    for (int i = 0; i < assets.count; i++) {
//        PHAsset *asset = assets[i];
//        [importAssets addObject:asset];
//        PHCachingImageManager *imageManager = [[PHCachingImageManager alloc] init];
//        NSString *fileName = [[NSString stringWithFormat:@"%@%@",dateStr,@(i)] MD5];
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            [imageManager requestImageForAsset:asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFill options:op resultHandler:^(UIImage *result, NSDictionary *info) {
//
//                [SGFileUtil savePhoto:result toRootPath:self.rootPath withName:fileName];
//                hudProgressBlock(++progressCount);
//            }];
//            [imageManager requestImageForAsset:asset targetSize:CGSizeMake(120, 120) contentMode:PHImageContentModeAspectFill options:op resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
//                [SGFileUtil saveThumb:result toRootPath:self.rootPath withName:fileName];
//                hudProgressBlock(++progressCount);
//            }];
//        });
//    }
}

- (void)imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController {
    [imagePickerController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - DNImagePickerControllerDelegate

- (void)dnImagePickerController:(DNImagePickerController *)imagePickerController
                     sendImages:(NSArray *)imageAssets
                    isFullImage:(BOOL)fullImage {
    NSArray *assets = imageAssets;
    PHImageRequestOptions *op = [[PHImageRequestOptions alloc] init];
    op.synchronous = YES;
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:imagePickerController.view];
    [imagePickerController.view addSubview:hud];
    hud.mode = MBProgressHUDModeAnnularDeterminate;
    [hud showAnimated:YES];
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSString *dateStr = [formatter stringFromDate:[NSDate date]];
    __block  NSInteger progressCount = 0;
    NSMutableArray *importAssets = @[].mutableCopy;
    NSInteger progressSum = assets.count;
    void (^hudProgressBlock)(NSInteger currentProgressCount) = ^(NSInteger progressCount) {
        dispatch_async(dispatch_get_main_queue(), ^{
            hud.progress = (double)progressCount / progressSum;
            if (progressCount == progressSum) {
                [imagePickerController dismissViewControllerAnimated:YES completion:nil];
                [hud hideAnimated:YES];
                [self loadFiles];
//                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
//                    [PHAssetChangeRequest deleteAssets:importAssets];
//                } completionHandler:nil];
            }
        });
    };
    for (int i = 0; i < assets.count; i++) {
        PHAsset *asset = assets[i];
        [importAssets addObject:asset];
        DNAsset *dnasset = assets[i];
        [DNImagePickerHelper fetchImageWithAsset:dnasset targetSize:CGSizeMake(self.view.frame.size.width, self.view.frame.size.height) needHighQuality:YES imageResutHandler:^(UIImage * _Nonnull image) {
            NSString *fileName = [[NSString stringWithFormat:@"%@%@",dateStr,@(i)] MD5];
            [SGFileUtil savePhoto:image toRootPath:self.rootPath withName:fileName];
            hudProgressBlock(++progressCount);
        }];
        [DNImagePickerHelper fetchImageWithAsset:dnasset targetSize:CGSizeMake(120, 120) imageResutHandler:^(UIImage * _Nonnull image) {
            NSString *fileName = [[NSString stringWithFormat:@"%@%@",dateStr,@(i)] MD5];
            [SGFileUtil saveThumb:image toRootPath:self.rootPath withName:fileName];
//            hudProgressBlock(++progressCount);
        }];
        
        
//        PHAsset *asset = assets[i];
//        [importAssets addObject:asset];
//        PHCachingImageManager *imageManager = [[PHCachingImageManager alloc] init];
//        NSString *fileName = [[NSString stringWithFormat:@"%@%@",dateStr,@(i)] MD5];
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            [imageManager requestImageForAsset:asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFill options:op resultHandler:^(UIImage *result, NSDictionary *info) {
//
//                [SGFileUtil savePhoto:result toRootPath:self.rootPath withName:fileName];
//                hudProgressBlock(++progressCount);
//            }];
//            [imageManager requestImageForAsset:asset targetSize:CGSizeMake(120, 120) contentMode:PHImageContentModeAspectFill options:op resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
//                [SGFileUtil saveThumb:result toRootPath:self.rootPath withName:fileName];
//                hudProgressBlock(++progressCount);
//            }];
//        });
    }
}

- (void)dnImagePickerControllerDidCancel:(DNImagePickerController *)imagePicker {
    [imagePicker dismissViewControllerAnimated:YES completion:nil];
}


@end
