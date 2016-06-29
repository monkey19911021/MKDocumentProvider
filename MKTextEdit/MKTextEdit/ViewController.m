//
//  ViewController.m
//  MKDocumentProvider
//
//  Created by DONLINKS on 16/6/28.
//  Copyright © 2016年 Donlinks. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<UIDocumentPickerDelegate>

@end

@implementation ViewController
{
    __weak IBOutlet UILabel *titleLabel;
    __weak IBOutlet UITextView *contTextView;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (IBAction)open:(id)sender {
    UIDocumentPickerViewController *docCtrl = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.text", @"public.content"] inMode: UIDocumentPickerModeOpen];
    docCtrl.delegate = self;
    [self presentViewController:docCtrl animated:YES completion:nil];
}

- (IBAction)import:(id)sender {
    UIDocumentPickerViewController *docCtrl = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.text", @"public.content"] inMode: UIDocumentPickerModeImport];
    docCtrl.delegate = self;
    [self presentViewController:docCtrl animated:YES completion:nil];
}

- (IBAction)move:(id)sender {
    
}

- (IBAction)export:(id)sender {
    
}

- (IBAction)modify:(id)sender {
    
}

#pragma mark - UIDocumentPickerDelegate
-(void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url
{
    titleLabel.text = [url lastPathComponent];
    NSString *contStr = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    contTextView.text = contStr;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
