//
//  FileProvider.m
//  MKDocumentProviderDemoFileProvider
//
//  Created by DONLINKS on 16/6/28.
//  Copyright © 2016年 Donlinks. All rights reserved.
//

#import "FileProvider.h"
#import <UIKit/UIKit.h>

@interface FileProvider ()

@end

@implementation FileProvider

- (NSFileCoordinator *)fileCoordinator {
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
    [fileCoordinator setPurposeIdentifier:[self providerIdentifier]];
    return fileCoordinator;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self.fileCoordinator coordinateWritingItemAtURL:[self documentStorageURL] options:0 error:nil byAccessor:^(NSURL *newURL) {
            // ensure the documentStorageURL actually exists
            NSError *error = nil;
            [[NSFileManager defaultManager] createDirectoryAtURL:newURL withIntermediateDirectories:YES attributes:nil error:&error];
        }];
    }
    return self;
}

- (void)providePlaceholderAtURL:(NSURL *)url completionHandler:(void (^)(NSError *error))completionHandler {
    // Should call + writePlaceholderAtURL:withMetadata:error: with the placeholder URL, then call the completion handler with the error if applicable.
    NSString *fileName = [url lastPathComponent];
    
    NSURL *placeholderURL = [NSFileProviderExtension placeholderURLForURL:[self.documentStorageURL URLByAppendingPathComponent:fileName]];
    
    // TODO: get file size for file at <url> from model
    NSUInteger fileSize = 0;
    NSDictionary* metadata = @{ NSURLFileSizeKey : @(fileSize)};
    [NSFileProviderExtension writePlaceholderAtURL:placeholderURL withMetadata:metadata error:NULL];
    
    if (completionHandler) {
        completionHandler(nil);
    }
}

//文件保护，文件不存在则创建新文件
- (void)startProvidingItemAtURL:(NSURL *)url completionHandler:(void (^)(NSError *))completionHandler {
    NSError* error = nil;
    __block NSError* fileError = nil;
    
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSString *filePath = [url path];
    if([fileMgr fileExistsAtPath:filePath]){ //1
        //文件已存在，返回
        completionHandler(error);
        return;
    }
    
    //文件不存在，创建新文件，并写入url
    NSData *fileData = [@"新建文件：" dataUsingEncoding:NSUTF8StringEncoding]; //2
    
    [self.fileCoordinator coordinateWritingItemAtURL:url options:NSFileCoordinatorWritingForReplacing error:&error byAccessor:^(NSURL *newURL) {
        [fileData writeToURL:newURL options:0 error:&fileError]; //3
    }];

    if (error!=nil) {
        completionHandler(error);
    } else {
        completionHandler(fileError);
    }
}


- (void)itemChangedAtURL:(NSURL *)url {
    // Called at some point after the file has changed; the provider may then trigger an upload
    
    // TODO: mark file at <url> as needing an update in the model; kick off update process
    NSLog(@"Item changed at URL %@", url);
}

- (void)stopProvidingItemAtURL:(NSURL *)url {
    // Called after the last claim to the file has been released. At this point, it is safe for the file provider to remove the content file.
    // Care should be taken that the corresponding placeholder file stays behind after the content file has been deleted.
    
    [self.fileCoordinator coordinateWritingItemAtURL:url options:NSFileCoordinatorWritingForDeleting error:NULL byAccessor:^(NSURL *newURL) {
        [[NSFileManager defaultManager] removeItemAtURL:newURL error:NULL];
    }];
    
    [self providePlaceholderAtURL:url completionHandler:^(NSError * __nullable error) {
        // TODO: handle any error, do any necessary cleanup
    }];
}

@end
