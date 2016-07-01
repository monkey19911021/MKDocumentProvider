//
//  ViewController.m
//  MKDocumentProvider
//
//  Created by DONLINKS on 16/6/28.
//  Copyright © 2016年 Donlinks. All rights reserved.
//

#import "ViewController.h"

//缓存文件路径
#define CachesFilePath ([NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0])

@interface ViewController ()<UIDocumentPickerDelegate, UIDocumentMenuDelegate>

@end

@implementation ViewController
{
    __weak IBOutlet UITextField *titleTextField;
    __weak IBOutlet UITextView *contTextView;
    __weak IBOutlet UIActivityIndicatorView *activityView;
    
    __weak IBOutlet UIBarButtonItem *moveBtnItem;
    __weak IBOutlet UIBarButtonItem *exportBtnItem;
    __weak IBOutlet UIBarButtonItem *saveBtnItem;
    
    NSString *currentFileName;
    UIDocumentPickerMode documentPickerMode;
    
    NSURL *lastURL;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view bringSubviewToFront: activityView];
}

#pragma mark - 新建文件
- (IBAction)newFile:(id)sender{
    titleTextField.enabled = YES;
    currentFileName = @"新建文件.txt";
    titleTextField.text = currentFileName;
    [titleTextField becomeFirstResponder];
    [self refreshBtnStatue];
}

#pragma mark - 打开文件
- (IBAction)open:(id)sender {
    titleTextField.enabled = NO;
    documentPickerMode = UIDocumentPickerModeOpen;
    [self displayDocumentPickerWithURIs:@[@"public.text", @"public.content"]];
}

#pragma mark - 导入文件
- (IBAction)import:(id)sender {
    //导入情况下，导入的文件会放在应用的临时文件目录里
    titleTextField.enabled = NO;
    documentPickerMode = UIDocumentPickerModeImport;
    [self displayDocumentPickerWithURIs:@[@"public.text", @"public.content"]];
}

#pragma mark - 移动文件
- (IBAction)move:(id)sender {
    [self modify:nil];
    documentPickerMode = UIDocumentPickerModeMoveToService;
    NSURL *fileURL = [NSURL fileURLWithPath: [CachesFilePath stringByAppendingPathComponent: currentFileName]];
    [self displayDocumentPickerWithURL:fileURL];
}

#pragma mark - 导出文件
- (IBAction)export:(id)sender {
    [self modify:nil];
    documentPickerMode = UIDocumentPickerModeExportToService;
    NSURL *fileURL = [NSURL fileURLWithPath: [CachesFilePath stringByAppendingPathComponent: currentFileName]];
    [self displayDocumentPickerWithURL:fileURL];
}

#pragma mark - 修改文件
- (IBAction)modify:(id)sender {
    
    if(currentFileName.length > 0){
        if(![currentFileName isEqualToString: titleTextField.text]){
            //删除缓存中旧文件
            [self deleteLocalCachesData:currentFileName];
            currentFileName = titleTextField.text;
        }
        NSString *content = contTextView.text;
        
        if([self saveLocalCachesCont:content fileName: currentFileName]){
            NSLog(@"保存成功");
        }
        
        if(documentPickerMode == UIDocumentPickerModeOpen){
            //打开模式下，保存在文件打开的地址
            NSFileCoordinator *fileCoorDinator = [NSFileCoordinator new];
            NSError *error = nil;
            [fileCoorDinator coordinateWritingItemAtURL:lastURL options:NSFileCoordinatorWritingForReplacing error:&error byAccessor:^(NSURL * _Nonnull newURL) {
                BOOL access = [newURL startAccessingSecurityScopedResource];
                if(access && [content writeToURL:newURL atomically:YES encoding:NSUTF8StringEncoding error:nil]){
                    NSLog(@"保存原文件成功");
                }
                [newURL stopAccessingSecurityScopedResource];
            }];
        }
        
    }
    
}

- (void)displayDocumentPickerWithURL:(NSURL *)url {
    UIDocumentMenuViewController *importMenu = [[UIDocumentMenuViewController alloc] initWithURL:url inMode:documentPickerMode];
    importMenu.delegate = self;
    [self presentViewController:importMenu animated:YES completion:nil];
}

- (void)displayDocumentPickerWithURIs:(NSArray *)UTIs {
    UIDocumentMenuViewController *importMenu = [[UIDocumentMenuViewController alloc] initWithDocumentTypes:UTIs inMode:documentPickerMode];
    importMenu.delegate = self;
    [self presentViewController:importMenu animated:YES completion:nil];
}

#pragma mark - UIDocumentMenuDelegate
-(void)documentMenu:(UIDocumentMenuViewController *)documentMenu didPickDocumentPicker:(UIDocumentPickerViewController *)documentPicker
{
    documentPicker.delegate = self;
    [self presentViewController:documentPicker animated:YES completion:nil];
}

#pragma mark - UIDocumentPickerDelegate
-(void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url
{
    lastURL = url;
    [controller dismissViewControllerAnimated:YES completion:nil];
    switch (controller.documentPickerMode) {
        case UIDocumentPickerModeImport:
        {
            [self refreshBtnStatue];
            [self importFile: url];
        }
            break;
        case UIDocumentPickerModeOpen:
        {
            [self refreshBtnStatue];
            [self openFile: url];
        }
            break;
        case UIDocumentPickerModeExportToService:
        {
            NSLog(@"保存到此位置：%@", url);
        }
            break;
        case UIDocumentPickerModeMoveToService:
        {
            NSLog(@"移动到此位置：%@", url);
        }
            break;
            
        default:
            break;
    }
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)importFile:(NSURL *)url
{
    [activityView startAnimating];
    //通过文件协调工具来得到新的文件地址，以此得到文件保护功能
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [fileCoordinator coordinateReadingItemAtURL:url options:NSFileCoordinatorReadingWithoutChanges error:nil byAccessor:^(NSURL * _Nonnull newURL) {
        [activityView stopAnimating];
        
        NSString *fileName = [newURL lastPathComponent];
        NSString *contStr = [NSString stringWithContentsOfURL:newURL encoding:NSUTF8StringEncoding error:nil];
        
        //把数据保存在本地缓存
        [self saveLocalCachesCont:contStr fileName:fileName];
        
        currentFileName = fileName;
        titleTextField.text = fileName;
        contTextView.text = contStr;
        
    }];
}

- (void)openFile:(NSURL *)url
{
    BOOL accessing = [url startAccessingSecurityScopedResource];//1.获取文件授权
    
    if(accessing){
        [activityView startAnimating];
        NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
        [fileCoordinator coordinateReadingItemAtURL:url
                                            options:NSFileCoordinatorReadingWithoutChanges
                                              error:nil
                                         byAccessor:^(NSURL * _Nonnull newURL) {
                                             
                                             [activityView stopAnimating];
                                             
                                             NSString *fileName = [newURL lastPathComponent];
                                             NSString *contStr = [NSString stringWithContentsOfURL:newURL encoding:NSUTF8StringEncoding error:nil];
                                             
                                             //把数据保存在本地缓存
                                             [self saveLocalCachesCont:contStr fileName:fileName];
                                             
                                             currentFileName = fileName;
                                             titleTextField.text = fileName;
                                             contTextView.text = contStr;
                                         }];
        
    }
    
    [url stopAccessingSecurityScopedResource];//2.停止授权
}

//把文件保存在本地缓存
- (BOOL)saveLocalCachesCont:(NSString *)cont fileName:(NSString *)fileName
{
    NSString *filePath = [CachesFilePath stringByAppendingPathComponent: fileName];
    return [cont writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (void)deleteLocalCachesData:(NSString *)fileName
{
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSString *filePath = [CachesFilePath stringByAppendingPathComponent: fileName];
    if([fileMgr fileExistsAtPath:filePath]){
        [fileMgr removeItemAtPath:filePath error:nil];
    }
}

- (void)refreshBtnStatue{
    moveBtnItem.enabled = YES;
    exportBtnItem.enabled = YES;
    saveBtnItem.enabled = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
