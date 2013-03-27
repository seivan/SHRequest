//
//  SHViewController.m
//  SHRequestExample
//
//  Created by Seivan Heidari on 3/27/13.
//  Copyright (c) 2013 Seivan Heidari. All rights reserved.
//

#import "SHViewController.h"
#import "SHOmniAuthLinkedIn.h"
#import "SHRequest.h"

#import "UIActionSheet+BlocksKit.h"
#import "NSArray+BlocksKit.h"
#import "UIAlertView+BlocksKit.h"

@interface SHViewController ()

@end

@implementation SHViewController

-(void)viewDidAppear:(BOOL)animated; {
  [super viewDidAppear:animated];
  //Could also be using SHAccount (which is actually what it is supposed to be) 
  __block id<account>  linkedInAccount = nil;
  
  dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
  [SHOmniAuthLinkedIn performLoginWithListOfAccounts:^(NSArray *accounts, SHOmniAuthAccountPickerHandler pickAccountBlock) { UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:@"Pick twitter account"];
    [accounts each:^(id<account> account) {
      [actionSheet addButtonWithTitle:account.username handler:^{
        pickAccountBlock(account);
      }];
    }];
    
    NSString * buttonTitle = nil;
    if(accounts.count > 0)
      buttonTitle = @"Add account";
    else
      buttonTitle = @"Connect with LinkedIn";
    
    [actionSheet addButtonWithTitle:buttonTitle handler:^{
      pickAccountBlock(nil);
    }];
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
    
    
  } onComplete:^(id<account> account, id response, NSError *error, BOOL isSuccess) {
    linkedInAccount = account;
    dispatch_semaphore_signal(semaphore);
  }];
  
  //Sample starts here :)
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    dispatch_async(dispatch_get_main_queue(), ^{
      SHRequest * request=  [SHRequest requestForServiceType:linkedInAccount.accountType.identifier
                                               requestMethod:SHRequestMethodGET
                                                         URL:[NSURL URLWithString:@"https://api.linkedin.com/v1/people/~?format=json"]
                                                  parameters:nil];
      
      request.account = (id<account>)linkedInAccount;
      [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        
        NSDictionary * response =  [NSJSONSerialization
                                    JSONObjectWithData:responseData options:0 error:nil];
        NSLog(@"%@", response);
        
      }];

      
      
      
    });
  });
  
}

@end
