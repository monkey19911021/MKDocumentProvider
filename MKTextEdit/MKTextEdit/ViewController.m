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
}

#pragma mark - 新建文件
- (IBAction)newFile:(id)sender{
    titleTextField.enabled = YES;
    
    documentPickerMode = 0;
    lastURL = nil;
    
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
    //1. 保存缓存文件
    [self modify:nil];
    documentPickerMode = UIDocumentPickerModeExportToService;
    NSURL *fileURL = [NSURL fileURLWithPath: [CachesFilePath stringByAppendingPathComponent: currentFileName]];
    
    //2.打开文件选择器
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
            //1.通过文件协调器写入文件
            NSFileCoordinator *fileCoorDinator = [NSFileCoordinator new];
            NSError *error = nil;
            [fileCoorDinator coordinateWritingItemAtURL:lastURL
                                                options:NSFileCoordinatorWritingForReplacing
                                                  error:&error
                                             byAccessor:^(NSURL * _Nonnull newURL) {
                
                //2.获取安全访问权限
                BOOL access = [newURL startAccessingSecurityScopedResource];
                
                //3.写入数据
                if(access && [content writeToURL:newURL atomically:YES encoding:NSUTF8StringEncoding error:nil]){
                    NSLog(@"保存原文件成功");
                }
                
                //4.停止安全访问权限
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

- (void)displayDocumentPickerWithURIs:(NSArray<NSString *> *)UTIs {
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
            //可以删除本地对应的文件
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
    
    //1.通过文件协调工具来得到新的文件地址，以此得到文件保护功能
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [fileCoordinator coordinateReadingItemAtURL:url options:NSFileCoordinatorReadingWithoutChanges error:nil byAccessor:^(NSURL * _Nonnull newURL) {
        [activityView stopAnimating];
        
        //2.直接读取文件
        NSString *fileName = [newURL lastPathComponent];
        NSString *contStr = [NSString stringWithContentsOfURL:newURL encoding:NSUTF8StringEncoding error:nil];
        
        //3.把数据保存在本地缓存
        [self saveLocalCachesCont:contStr fileName:fileName];
        
        //4.显示数据
        currentFileName = fileName;
        titleTextField.text = fileName;
        contTextView.text = contStr;
        
    }];
}

- (void)openFile:(NSURL *)url
{
    //1.获取文件授权
    BOOL accessing = [url startAccessingSecurityScopedResource];
    
    if(accessing){
        [activityView startAnimating];
        
        //2.通过文件协调器读取文件地址
        NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
        [fileCoordinator coordinateReadingItemAtURL:url
                                            options:NSFileCoordinatorReadingWithoutChanges
                                              error:nil
                                         byAccessor:^(NSURL * _Nonnull newURL) {
                                             
                                             [activityView stopAnimating];
                                             
                                             //3.读取文件协调器提供的新地址里的数据
                                             NSString *fileName = [newURL lastPathComponent];
                                             NSString *contStr = [NSString stringWithContentsOfURL:newURL encoding:NSUTF8StringEncoding error:nil];
                                             
                                             //4.把数据保存在本地缓存
                                             [self saveLocalCachesCont:contStr fileName:fileName];
                                             
                                             //5.显示数据
                                             currentFileName = fileName;
                                             titleTextField.text = fileName;
                                             contTextView.text = contStr;
                                         }];
        
    }
    
    //6.停止授权
    [url stopAccessingSecurityScopedResource];
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
