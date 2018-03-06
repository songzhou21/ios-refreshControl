//
//  UIScrollView+SZRefresh.m
//  SZRefreshControl
//
//  Created by songzhou on 2018/3/6.
//  Copyright © 2018年 Song Zhou. All rights reserved.
//

#import "UIScrollView+SZRefresh.h"
#import <objc/runtime.h>

static const CGFloat REFRESH_HEADER_HEIGHT = 40;
static const void *SZRefreshHeaderKey = &SZRefreshHeaderKey;
static const void *SZRefreshHeaderBlockKey = &SZRefreshHeaderBlockKey;

@implementation UIScrollView (SZRefresh)

- (void)sz_refreshHeaderStartLoading {
    [self.sz_refreshHeader startLoading];
}

- (void)sz_refreshHeaderStopLoading {
    [self.sz_refreshHeader stopLoading];
    
    [self _setInitialConentInsetAnimated:YES];
}

#pragma mark -
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = CGRectGetWidth(self.bounds);
    
    self.sz_refreshHeader.frame = CGRectMake(0, 0, width, REFRESH_HEADER_HEIGHT);
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"contentOffset"];
}

#pragma mark - setter
- (void)setSz_refreshHeader:(SZRefreshHeader *)sz_refreshHeader {
    objc_setAssociatedObject(self, SZRefreshHeaderKey, sz_refreshHeader, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setSz_refreshHeaderBlock:(SZRefreshHeaderBlock)sz_refreshHeaderBlock {
    objc_setAssociatedObject(self, SZRefreshHeaderBlockKey, sz_refreshHeaderBlock, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [self __setup];
}

#pragma mark - getter
- (SZRefreshHeader *)sz_refreshHeader {
    SZRefreshHeader *header = objc_getAssociatedObject(self, SZRefreshHeaderKey);
    if (!header) {
        header = [[SZRefreshHeader alloc] init];
        objc_setAssociatedObject(self, SZRefreshHeaderKey, header, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return header;
}

- (SZRefreshHeaderBlock )sz_refreshHeaderBlock {
    return objc_getAssociatedObject(self, SZRefreshHeaderBlockKey);
}

#pragma mark -
- (void)__loadingStarted {
    if (self.sz_refreshHeaderBlock) {
        self.sz_refreshHeaderBlock();
    }
}

#pragma mark -
- (void)__setup {
    SZRefreshHeader *header = self.sz_refreshHeader;
    header.backgroundColor = [UIColor redColor];
    [self addSubview:header];

    self.contentInset = UIEdgeInsetsMake(-REFRESH_HEADER_HEIGHT, 0, 0, 0);
    
    [self addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)_setInitialConentInsetAnimated:(BOOL)animated {
    UIEdgeInsets newInset = UIEdgeInsetsMake(-REFRESH_HEADER_HEIGHT, 0, 0, 0);
    if (UIEdgeInsetsEqualToEdgeInsets(self.contentInset, newInset)) {
        return;
    }
    
    
    [self _setContentInset:newInset animated:animated];
}

- (void)_setLoadingContentInset {
    [self _setContentInsetAndResetOffset:UIEdgeInsetsMake(0, 0, 0, 0)];
}

- (void)_setContentInset:(UIEdgeInsets)inset animated:(BOOL)animated {
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            self.contentInset = inset;
        }];
    } else {
        self.contentInset = inset;
    }
}


/**
 work around for scroll view jumper stutter
 
 @refre https://stackoverflow.com/a/26320256/1911562
 @param inset contentInset value
 */
- (void)_setContentInsetAndResetOffset:(UIEdgeInsets)inset {
    CGPoint contentOffset = self.contentOffset;
    
    [UIView animateWithDuration:0.2 animations:^{
        self.contentInset = inset;
        self.contentOffset = contentOffset;
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (object == self) {
        if ([keyPath isEqualToString:@"contentOffset"]) {
            CGPoint offset = self.contentOffset;
            if (offset.y <= 0) { // fully revealed refresh header
                if (self.decelerating && self.sz_refreshHeader.state == SZRefreshHeaderStateInitail) {
                    [self sz_refreshHeaderStartLoading];
                    self.sz_refreshHeader.state = SZRefreshHeaderStateLoading;
                    [self _setLoadingContentInset];
                    [self __loadingStarted];
                }
            }
            
            return;
        }
    }
}

@end