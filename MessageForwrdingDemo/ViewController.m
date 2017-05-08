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
        //已实现的直接消息转发
        [anInvocation invoke];
    }
    else if ([[[TestObj alloc]init] respondsToSelector:anInvocation.selector])
    {
        //未实现的用其他实现的Target转发
        [anInvocation invokeWithTarget:[[TestObj alloc]init]];
    }
    else
    {
        //都未实现，用预定义的方法方法转发，防止崩溃
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
            NSString *str = [NSString stringWithFormat:@"%@ hasn't implementation method %@",NSStringFromClass([self class]),NSStringFromSelector(aSelector)];
            NSAssert(!DEBUG,str);
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
