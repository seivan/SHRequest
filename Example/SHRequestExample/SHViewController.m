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
@property(nonatomic,strong) id<account>  linkedInAccount;
-(void)runSampleGetRequestWithSemaphore:(dispatch_semaphore_t)theSemaphore;
-(void)runSamplePostRequestWithSemaphore:(dispatch_semaphore_t)theSemaphore;
@end

@implementation SHViewController

-(void)viewDidAppear:(BOOL)animated; {
  [super viewDidAppear:animated];
  //Could also be using SHAccount (which is actually what it is supposed to be) 

  
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
    if(isSuccess == NO) {
      NSLog(@"ERROR: %@", error);
    }
    else {
      self.linkedInAccount = account;
      dispatch_semaphore_signal(semaphore);
      
    }
  }];
  
  [self runSampleGetRequestWithSemaphore:semaphore];
  [self runSamplePostRequestWithSemaphore:semaphore];
  
  
}

-(void)runSampleGetRequestWithSemaphore:(dispatch_semaphore_t)theSemaphore; {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    dispatch_semaphore_wait(theSemaphore, DISPATCH_TIME_FOREVER);
    dispatch_async(dispatch_get_main_queue(), ^{
      SHRequest * request=  [SHRequest requestForServiceType:self.linkedInAccount.accountType.identifier
                                               requestMethod:SHRequestMethodGET
                                                         URL:[NSURL URLWithString:@"https://api.linkedin.com/v1/people/~?format=json"]
                                                  parameters:nil];
      
      request.account = self.linkedInAccount;
      [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        
        NSDictionary * response =  [NSJSONSerialization
                                    JSONObjectWithData:responseData options:0 error:nil];
        NSLog(@"GET: %@", response);
        dispatch_semaphore_signal(theSemaphore);
      }];
      
      
    });
  });

}

-(void)runSamplePostRequestWithSemaphore:(dispatch_semaphore_t)theSemaphore; {
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    dispatch_semaphore_wait(theSemaphore, DISPATCH_TIME_FOREVER);
    dispatch_async(dispatch_get_main_queue(), ^{
      NSDictionary * params = @{@"comment": @"I am tesing CakePHP" ,
                                @"visibility":@{@"code":@"anyone"}};
      
      
      SHRequest * requestPost = [SHRequest requestForServiceType:self.linkedInAccount.accountType.identifier requestMethod:SHRequestMethodPOST URL:[NSURL URLWithString:@"https://api.linkedin.com/v1/people/~/shares?format=json"] parameters:params];
      requestPost.account = self.linkedInAccount;
      [requestPost performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        NSDictionary * responseForPost =  [NSJSONSerialization
                                           JSONObjectWithData:responseData options:0 error:nil];
        NSLog(@"POST %@", responseForPost);
        
      }];
      
    });
  });
  
}


@end
