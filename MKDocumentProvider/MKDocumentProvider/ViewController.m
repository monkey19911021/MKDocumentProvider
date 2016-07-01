//
//  ViewController.m
//  MKDocumentProvider
//
//  Created by DONLINKS on 16/6/28.
//  Copyright © 2016年 Donlinks. All rights reserved.
//

#import "ViewController.h"

#define APP_GROUP_ID @"group.com.donlinks.MKDocumentProvider"
#define APP_FILE_NAME @"File Provider Storage/MKFile"

#define CellIdentifier @"cellIde"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>

@end

@implementation ViewController
{
    NSArray<NSString *> *fileNamesArray;

    __weak IBOutlet UITableView *fileTableView;
    
    NSString *storagePath;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    storagePath = [self storagePath];
    
    //第一次启动先写入一些文件到共享容器
    [self writeFirstFileToShare];
    
    [self loadData];
}

#pragma mark - 获取共享容器文件夹路径
- (NSString *)storagePath {
    NSURL *groupURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:APP_GROUP_ID];
    NSString *groupPath = [groupURL path];
    NSString *_storagePath = [groupPath stringByAppendingPathComponent:APP_FILE_NAME];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:_storagePath]) {
        [fileManager createDirectoryAtPath:_storagePath withIntermediateDirectories:NO attributes:nil error:nil];
    }
    return _storagePath;
}

- (void)writeFirstFileToShare{
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL isOpened = [[defaults objectForKey:@"isOpened"] boolValue];
    if(!isOpened){
        [defaults setObject:@(YES) forKey:@"isOpened"];
        
        NSString *file1Cont = @"Hello every one. I'm M0nk1y. My site: http://mkapple.cn";
        NSString *file2Cont = @"new File2:";
        
        [file1Cont writeToFile:[storagePath stringByAppendingPathComponent:@"File1.text"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
        [file2Cont writeToFile:[storagePath stringByAppendingPathComponent:@"File2.text"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}

- (void)loadData
{
    fileNamesArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:storagePath error:nil];
    [fileTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
    [fileTableView reloadData];
}

#pragma mark - UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return fileNamesArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.textLabel.text = fileNamesArray[indexPath.row];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *docFilePath = [storagePath stringByAppendingPathComponent: fileNamesArray[indexPath.row]];
    NSString *fileContent = [[NSString alloc] initWithContentsOfFile:docFilePath encoding:NSUTF8StringEncoding error:nil];
    
    UIViewController *viewCtrl = [UIViewController new];
    
    UITextView *textView = [[UITextView alloc] initWithFrame:viewCtrl.view.bounds];
    textView.text = fileContent;
    [viewCtrl.view addSubview:textView];
    
    [self.navigationController pushViewController:viewCtrl animated:YES];
    
}

@end
