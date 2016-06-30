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

@interface ViewController ()<UIDocumentPickerDelegate>

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
    [self refreshBtnStatue];
    [self presentDocumentPickerViewControllerWithDocumentTypes:@[@"public.text", @"public.content"]];
}

#pragma mark - 导入文件
- (IBAction)import:(id)sender {
    //导入情况下，导入的文件会放在应用的临时文件目录里
    titleTextField.enabled = NO;
    documentPickerMode = UIDocumentPickerModeImport;
    [self refreshBtnStatue];
    [self presentDocumentPickerViewControllerWithDocumentTypes:@[@"public.text", @"public.content"]];
}

- (void)presentDocumentPickerViewControllerWithDocumentTypes:(NSArray <NSString *>*)allowedUTIs{
    UIDocumentPickerViewController *docCtrl = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:allowedUTIs
                                                                                                     inMode: documentPickerMode];
    docCtrl.delegate = self;
    [self presentViewController:docCtrl animated:YES completion:nil];
}

#pragma mark - 移动文件
- (IBAction)move:(id)sender {
    NSURL *fileURL = [NSURL fileURLWithPath: [CachesFilePath stringByAppendingPathComponent: currentFileName]];
    UIDocumentPickerViewController *docCtrl = [[UIDocumentPickerViewController alloc] initWithURL:fileURL inMode:UIDocumentPickerModeMoveToService];
    docCtrl.delegate = self;
    [self presentViewController:docCtrl animated:YES completion:nil];
}

#pragma mark - 导出文件
- (IBAction)export:(id)sender {
    [self modify:nil];
    NSURL *fileURL = [NSURL fileURLWithPath: [CachesFilePath stringByAppendingPathComponent: currentFileName]];
    UIDocumentPickerViewController *docCtrl = [[UIDocumentPickerViewController alloc] initWithURL:fileURL inMode:UIDocumentPickerModeExportToService];
    docCtrl.delegate = self;
    [self presentViewController:docCtrl animated:YES completion:nil];
}

#pragma mark - 修改文件
- (IBAction)modify:(id)sender {
    
    if(currentFileName.length > 0){
        if(![currentFileName isEqualToString: titleTextField.text]){
            //删除缓存中旧文件
            [self deleteLocalCachesData:currentFileName];
            currentFileName = titleTextField.text;
        }
        NSData *fileData = nil;
        NSString *content = contTextView.text;
        if(content.length > 0){
            fileData = [content dataUsingEncoding:NSUTF8StringEncoding];
        }else{
            fileData = [NSData data];
        }
        if([self saveLocalCachesData: fileData fileName: currentFileName]){
            NSLog(@"保存成功");
        }
    }
    
}

#pragma mark - UIDocumentPickerDelegate
-(void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url
{
    [controller dismissViewControllerAnimated:YES completion:nil];
    switch (controller.documentPickerMode) {
        case UIDocumentPickerModeImport:
            [self importFile: url];
            break;
        case UIDocumentPickerModeOpen:
            [self openFile: url];
            break;
        case UIDocumentPickerModeExportToService:
        {
            NSLog(@"保存到此位置：%@", url);
        }
            break;
        case UIDocumentPickerModeMoveToService:
            
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
        NSData *data = [NSData dataWithContentsOfURL:newURL];
        [self saveLocalCachesData:data fileName: fileName];
        
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
                                             NSData *data = [NSData dataWithContentsOfURL:newURL];
                                             [self saveLocalCachesData:data fileName: fileName];
                                             
                                             currentFileName = fileName;
                                             titleTextField.text = fileName;
                                             contTextView.text = contStr;
                                         }];
        
    }
    
    [url stopAccessingSecurityScopedResource];//2.停止授权
}

//把文件保存在本地缓存
- (BOOL)saveLocalCachesData:(NSData *)data fileName:(NSString *)fileName
{
    NSString *filePath = [CachesFilePath stringByAppendingPathComponent: fileName];
    return [data writeToFile:filePath atomically:YES];
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
