//
//  ViewController.m
//  MessageForwrdingDemo
//
//  Created by syl on 2017/5/8.
//  Copyright © 2017年 personCompany. All rights reserved.
//

#import "ViewController.h"
//消息转发后的消息执行者
@interface TestObj : NSObject
//转发方法的声明
-(void)testMethod;
@end
@implementation TestObj
//转发方法的实现
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
/*
 * 当动态解析和快速转发都未能处理时，该方法就会被执行，如果该方法，也未能处理，Runtime系统就会调用doNotRecognizeSelector:进而崩溃。
 * 参数anInvocation 类型是NSInvocation,这个类里，封装了小执行的方法SEL,和消息原定的接受者，以及参数、返回值等信息；
 * 因此，我们可以修改其中的消息接受者也就是执行者，或者要执行方法，实现消息的完整转发，防止系统崩溃。
 * 这里的anInvocation对象是要经过-(NSMethodSignature *)methodSignatureForSelector:方法进行签名来生成的，
 * 因此，我们要实现消息的完整转发，是需要该方法与下面的方法协同实现。
 */
-(void)forwardInvocation:(NSInvocation *)anInvocation{
    SEL sel = anInvocation.selector;
    if ([self respondsToSelector:sel]){
        //已实现的直接消息转发
        [anInvocation invoke];
    }else if ([[[TestObj alloc]init] respondsToSelector:anInvocation.selector]){
        //未实现的用其他实现的Target转发
        [anInvocation invokeWithTarget:[[TestObj alloc]init]];
    }else{
        //都未实现，用预定义的方法方法转发，防止崩溃
        SEL unKnownSel = anInvocation.selector;
        anInvocation.selector = @selector(unKnownSelector:);
        [anInvocation setArgument:unKnownSel atIndex:0];
        anInvocation.target = self;
        [anInvocation invoke];
    }
}
/*
 * 传递过来的消息，需要经过该方法进行签名，讲参数、返回值和原消息一起打包到一个NSInvocation对象中，
 * 以供上面的消息转发方法进行入参。
 */
-(NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector{
    //这个方法返回的实例是协同上面的方法实现消息转发的
    NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];
    if (!signature){
        if ([[[TestObj alloc]init] respondsToSelector:aSelector]){
            signature = [[[TestObj alloc]init] methodSignatureForSelector:aSelector];
        }else{
            NSString *str = [NSString stringWithFormat:@"%@ hasn't implementation method %@",NSStringFromClass([self class]),NSStringFromSelector(aSelector)];
            NSAssert(!DEBUG,str);
            signature = [self methodSignatureForSelector:@selector(unKnownSelector:)];
        }
    }
    return signature;
}
-(void)unKnownSelector:(SEL)aSelector{
    NSLog(@"%@ hasn't implementation method %@",NSStringFromClass([self class]),NSStringFromSelector(aSelector));
}
-(void)selfTestMethod{
    NSLog(@"%s",__func__);
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
