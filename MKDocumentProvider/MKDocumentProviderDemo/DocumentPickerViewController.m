//
//  DocumentPickerViewController.m
//  MKDocumentProviderDemo
//
//  Created by DONLINKS on 16/6/28.
//  Copyright © 2016年 Donlinks. All rights reserved.
//

#import "DocumentPickerViewController.h"

#define APP_GROUP_ID @"group.com.donlinks.MKDocumentProvider"
#define APP_FILE_NAME @"MKFile"

#define CellIdentifier @"cellIde"

@interface DocumentPickerViewController ()<UITableViewDelegate, UITableViewDataSource>

@end

@implementation DocumentPickerViewController
{
    NSArray<NSString *> *fileNamesArray;
    NSString *storagePath;
    
    __weak IBOutlet UITableView *itemsTableView;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    [itemsTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
    itemsTableView.backgroundColor = [UIColor whiteColor];
}

- (void)loadData{
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    storagePath = [[self.documentStorageURL path] stringByAppendingPathComponent:APP_FILE_NAME];
    fileNamesArray = [fileMgr contentsOfDirectoryAtPath:storagePath error:nil];
    [itemsTableView reloadData];
}

-(void)prepareForPresentationInMode:(UIDocumentPickerMode)mode {
    // TODO: present a view controller appropriate for picker mode here
    
    switch (mode) {
        case UIDocumentPickerModeImport:
        {
            self.navigationItem.title = @"请选择导入文件";
        }
            break;
        case UIDocumentPickerModeOpen:
        {
            self.navigationItem.title = @"请选择打开文件";
        }
            break;
            
        default:
            break;
    }
    
    [self loadData];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *filePath = [storagePath stringByAppendingPathComponent: fileNamesArray[indexPath.row]];
    NSURL *fileURL = [NSURL fileURLWithPath: filePath];
    [self dismissGrantingAccessToURL: fileURL];
}

@end
