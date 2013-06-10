//
//  SHRequest.m
//  SHAccountManagerExample
//
//  Created by Seivan Heidari on 3/23/13.
//  Copyright (c) 2013 Seivan Heidari. All rights reserved.
//

#import "SHRequest.h"
#import "OAuthCore.h"
#import "SHOmniAuth.h"
#import "SHOmniAuthProviderPrivates.h"


@interface SHRequest ()
@property(NS_NONATOMIC_IOSONLY,strong)    NSMutableURLRequest * currentRequest;
@property(NS_NONATOMIC_IOSONLY,strong)    NSString            * serviceType;
@property(NS_NONATOMIC_IOSONLY,strong)    NSDictionary        * parameters;
@property(NS_NONATOMIC_IOSONLY,strong)    NSData              * bodyData;
@property(NS_NONATOMIC_IOSONLY,assign)    SHRequestMethod       requestMethod;
@property(NS_NONATOMIC_IOSONLY,strong)    NSURL               * URL;
@end

@interface SHRequest (Private)
@property(NS_NONATOMIC_IOSONLY,readonly)  NSString            * requestMethodString;
@property(NS_NONATOMIC_IOSONLY,readonly)  NSString            * parameterString;
-(NSString *)toStringForRequestMethod:(SHRequestMethod)theRequestMethod;
@end



@implementation SHRequest
+(SHRequest *)requestForServiceType:(NSString *)serviceType requestMethod:(SHRequestMethod)requestMethod URL:(NSURL *)url parameters:(NSDictionary *)parameters; {
  
  
  NSAssert(serviceType, @"Must pass a serviceType");
  SHRequest * request = [[SHRequest alloc] init];
  request.serviceType = serviceType;
  request.currentRequest = [NSMutableURLRequest requestWithURL:url];
  [request.currentRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
//  [request.currentRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
//  [request.currentRequest setValue:@"json" forHTTPHeaderField:@"x-li-format"];
  request.requestMethod = requestMethod;
  [request.currentRequest setHTTPMethod:request.requestMethodString];
  request.parameters = parameters;
  request.URL = url;
  
  request.isJSONParameters = NO;
  request.bodyData = [request.parameterString dataUsingEncoding:NSUTF8StringEncoding];
  [request.currentRequest setHTTPBody:request.bodyData];

  
  return request;
}

-(NSURLRequest *)preparedURLRequest; {
  return self.currentRequest.copy;
}

-(void)setAccount:(id<accountPrivate>)account; {
//  NSAssert(account, @"Must pass an account");
//  NSAssert(account.credential, @"account must have credential");
//  NSAssert(account.credential.token, @"credential must have token");
//  NSAssert(account.credential.secret, @"credential must have secret");
  _account = account;


}



-(void)performRequestWithHandler:(SHRequestHandler)handler; {
  NSAssert(self.account, @"Must have an account");
  id<accountPrivate> account = (id<accountPrivate>)self.account;
  if (self.isJSONParameters && self.parameters) {
    self.bodyData = [NSJSONSerialization dataWithJSONObject:self.parameters
                                                    options:NSJSONWritingPrettyPrinted
                                                      error:nil];
    [self.currentRequest setHTTPBody:self.bodyData];

  }
  NSString *authorizationHeader = OAuthorizationHeader(self.currentRequest.URL,
                                                       self.requestMethodString,
                                                       self.currentRequest.HTTPBody,
                                                       [SHOmniAuth providerValue:SHOmniAuthProviderValueKey
                                                                     forProvider:account.accountType.identifier],
                                                       [SHOmniAuth providerValue:SHOmniAuthProviderValueSecret
                                                                     forProvider:account.accountType.identifier],
                                                       account.credential.token,
                                                       account.credential.secret);

  [self.currentRequest setValue:authorizationHeader forHTTPHeaderField:@"Authorization"];

  
  [NSURLConnection sendAsynchronousRequest:self.currentRequest queue:[NSOperationQueue mainQueue]
                         completionHandler:^(NSURLResponse * response, NSData * data, NSError * error) {
                           handler(data, (NSHTTPURLResponse*)response, error.copy);
  }];
}
-(NSDictionary *)parameters; {
  return _parameters;
}

#pragma mark -
#pragma mark Privates
-(NSString *)parameterString; {
  NSMutableString * paramsAsString = [[NSMutableString alloc] init];
  [self.parameters enumerateKeysAndObjectsUsingBlock:
   ^(id key, id obj, BOOL *stop) {
     [paramsAsString appendFormat:@"%@=%@&", key, obj];
   }];
  return paramsAsString;
}

-(NSString *)requestMethodString; {
  return [self toStringForRequestMethod:self.requestMethod];
}


-(NSString *)toStringForRequestMethod:(SHRequestMethod)theRequestMethod; {
  NSAssert(theRequestMethod >= 0 && theRequestMethod <= 3, @"Must the request method");
  NSString * toStringForRequestMethod = nil;
  switch (theRequestMethod) {
    case SHRequestMethodGET:
      toStringForRequestMethod = @"GET";
      break;
    case SHRequestMethodPOST:
      toStringForRequestMethod = @"POST";
      break;
    case SHRequestMethodDELETE:
      toStringForRequestMethod = @"DELETE";
      break;
    case SHRequestMethodUPDATE:
      toStringForRequestMethod = @"UPDATE";
      break;
    default:
      break;
  }
  return toStringForRequestMethod;
}

@end

