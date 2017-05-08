//
//  ViewController.m
//  MessageForwrdingDemo
//
//  Created by syl on 2017/5/8.
//  Copyright © 2017年 personCompany. All rights reserved.
//

#import "ViewController.h"

@interface TestObj : NSObject
-(void)testMethod;
@end
@implementation TestObj
-(void) testMethod
{
    NSLog(@"%s",__func__);
}
@end
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //    [self selfTestMethod]; 结果：[ViewController selfTestMethod]
//    [self performSelector:@selector(testMethod)];结果：[TestObj testMethod]
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self performSelector:NSSelectorFromString(@"otherMethod")];
#pragma clang diagnostic pop
}
-(void)forwardInvocation:(NSInvocation *)anInvocation
{
    SEL sel = anInvocation.selector;
    if ([self respondsToSelector:sel])
    {
        [anInvocation invoke];
    }
    else if ([[[TestObj alloc]init] respondsToSelector:anInvocation.selector])
    {
        [anInvocation invokeWithTarget:[[TestObj alloc]init]];
    }
    else
    {
        SEL unKnownSel = anInvocation.selector;
        anInvocation.selector = @selector(unKnownSelector:);
        [anInvocation setArgument:unKnownSel atIndex:0];
        anInvocation.target = self;
        [anInvocation invoke];
    }

}
-(NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];
    if (!signature)
    {
        if ([[[TestObj alloc]init] respondsToSelector:aSelector])
        {
            signature = [[[TestObj alloc]init] methodSignatureForSelector:aSelector];
        }
        else
        {
            signature = [self methodSignatureForSelector:@selector(unKnownSelector:)];
        }
    }
    return signature;
}
-(void)unKnownSelector:(SEL)aSelector
{
    NSLog(@"%@ hasn't implementation method %@",NSStringFromClass([self class]),NSStringFromSelector(aSelector));
}
-(void)selfTestMethod
{
    NSLog(@"%s",__func__);
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
