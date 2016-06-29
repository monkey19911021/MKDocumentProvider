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
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    //第一次启动先写入一些文件到共享容器
    [self writeFirstFileToShare];
    
    [self loadData];
}

- (NSString *)storagePath {
    NSURL *groupURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:APP_GROUP_ID];
    NSString *groupPath = [groupURL path];
    NSString *storagePath = [groupPath stringByAppendingPathComponent:APP_FILE_NAME];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:storagePath]) {
        [fileManager createDirectoryAtPath:storagePath withIntermediateDirectories:NO attributes:nil error:nil];
    }
    return storagePath;
}

- (void)writeFirstFileToShare{
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL isOpened = [[defaults objectForKey:@"isOpened"] boolValue];
    if(!isOpened){
        [defaults setObject:@(YES) forKey:@"isOpened"];
        
        NSString *file1Cont = @"Hello every one. I'm M0nk1y. My site: http://mkapple.cn";
        NSString *file2Cont = @"new File2:";
        
        [file1Cont writeToFile:[[self storagePath] stringByAppendingPathComponent:@"File1.text"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
        [file2Cont writeToFile:[[self storagePath] stringByAppendingPathComponent:@"File2.text"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}

- (void)loadData
{
    fileNamesArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self storagePath] error:nil];
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
    
    NSString *docFilePath = [[self storagePath] stringByAppendingPathComponent: fileNamesArray[indexPath.row]];
    
    UIViewController *viewCtrl = [UIViewController new];
    
    UIWebView *webView = [[UIWebView alloc] initWithFrame:viewCtrl.view.bounds];
    [viewCtrl.view addSubview:webView];
    [webView loadRequest:[NSURLRequest requestWithURL: [NSURL fileURLWithPath:docFilePath]]];
    [webView sizeToFit];
    webView.scalesPageToFit = YES;
    [viewCtrl.view addSubview:webView];
    
    [self.navigationController pushViewController:viewCtrl animated:YES];
    
}

@end
