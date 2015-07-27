//
//  AvatarsManager.m
//  Antidote
//
//  Created by Dmytro Vorobiov on 26.06.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <BlocksKit/NSArray+BlocksKit.h>

#import "AvatarsManager.h"
#import "AppearanceManager.h"
#import "NSString+Utilities.h"

static const NSUInteger kNumberOfLettersInAvatar = 2;

@interface AvatarsManager ()

@property (strong, nonatomic) NSCache *cache;

@end

@implementation AvatarsManager

#pragma mark -  Lifecycle

- (instancetype)init
{
    self = [super init];

    if (! self) {
        return nil;
    }

    self.cache = [NSCache new];

    return self;
}

#pragma mark -  Public

- (UIImage *)avatarFromString:(NSString *)string diameter:(CGFloat)diameter
{
    return [self avatarFromString:string
                         diameter:diameter
                        textColor:[[AppContext sharedContext].appearance textMainColor]
                  backgroundColor:[[AppContext sharedContext].appearance bubbleOutgoingColor]];
}

- (UIImage *)avatarFromString:(NSString *)string
                     diameter:(CGFloat)diameter
                    textColor:(UIColor *)textColor
              backgroundColor:(UIColor *)backgroundColor
{
    NSString *key = [self keyFromString:string diameter:diameter textColor:textColor backgroundColor:backgroundColor];
    UIImage *avatar = [self.cache objectForKey:key];

    if (avatar) {
        return avatar;
    }

    avatar = [self createAvatarFromString:string diameter:diameter textColor:textColor backgroundColor:backgroundColor];
    [self.cache setObject:avatar forKey:key];

    return avatar;
}

#pragma mark -  Private

- (NSString *)keyFromString:(NSString *)string
                   diameter:(CGFloat)diameter
                  textColor:(UIColor *)textColor
            backgroundColor:(UIColor *)backgroundColor
{
    return [NSString stringWithFormat:@"%@-%f-%@-%@", string, diameter, textColor, backgroundColor];
}

- (UIImage *)createAvatarFromString:(NSString *)string
                           diameter:(CGFloat)diameter
                          textColor:(UIColor *)textColor
                    backgroundColor:(UIColor *)backgroundColor
{
    string = [self avatarsStringFromString:string];

    UILabel *label = [UILabel new];
    label.backgroundColor = backgroundColor;
    label.layer.borderColor = textColor.CGColor;
    label.layer.borderWidth = 1.0;
    label.layer.masksToBounds = YES;
    label.textColor = textColor;
    label.textAlignment = NSTextAlignmentCenter;
    label.text = string;

    CGFloat fontSize = diameter;
    CGSize size;

    do {
        fontSize--;

        // PL - placeholder in case if avatar text is nil
        NSString *str = string ?: @"PL";

        size = [str stringSizeWithFont:[[AppContext sharedContext].appearance fontHelveticaNeueLightWithSize:fontSize]];

    }
    while (MAX(size.width, size.height) > diameter);

    CGRect frame = CGRectZero;
    frame.size.width = frame.size.height = diameter;

    label.font = [[AppContext sharedContext].appearance fontHelveticaNeueLightWithSize:(int) (fontSize * 0.6)];
    label.layer.cornerRadius = frame.size.width / 2;
    label.frame = frame;

    return [self imageWithView:label];
}

- (NSString *)avatarsStringFromString:(NSString *)string
{
    if (! string.length) {
        return @"";
    }

    // Avatar can has alphanumeric symbols and "?" sign.
    NSMutableCharacterSet *badSymbols = [[[NSCharacterSet alphanumericCharacterSet] invertedSet] mutableCopy];
    [badSymbols removeCharactersInString:@"?"];

    NSArray *words = [string componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    words = [[words bk_map:^NSString * (NSString *w) {
        return [[w componentsSeparatedByCharactersInSet:badSymbols] componentsJoinedByString:@""];
    }] bk_reject:^BOOL (NSString *w) {
        return (w.length == 0);
    }];

    NSString *result = @"";

    if (words.count > 1) {
        result = [[words bk_map:^NSString *(NSString *word) {
            return (word.length <= 1) ? word : [word substringToIndex:1];
        }] componentsJoinedByString:@""];
    }
    else {
        result = [words firstObject];
    }

    result = (result.length <= kNumberOfLettersInAvatar) ? result : [result substringToIndex:kNumberOfLettersInAvatar];

    return [result uppercaseString];
}

- (UIImage *)imageWithView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return image;
}

@end
