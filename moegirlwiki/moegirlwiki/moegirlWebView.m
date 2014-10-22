//
//  moegirlWebView.m
//  moegirlwiki
//
//  Created by master on 14-10-22.
//  Copyright (c) 2014年 masterchan.me. All rights reserved.
//

#import "moegirlWebView.h"

@implementation moegirlWebView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (NSString *)urlEncode:(NSString*)unencodeString
{
    NSString * encodedString = (NSString*) CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)unencodeString, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]",kCFStringEncodingUTF8));
    return encodedString;
}

- (NSString *)prepareContent:(NSData *)data
{
    NSString * content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    /*处理接受的数据*/
    NSString * documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString * htmlDocumentPath = [[documentPath stringByAppendingPathComponent:@"data"] stringByAppendingPathComponent:@"setting"];
    
    NSString * regexstr;
    NSRange range;    
    
    
        //R18修正
        regexstr = @"<script language=\"javascript\"[\\s\\S]*?<div id=x18[\\s\\S]*?</div>[\\s\\S]*?</script>[\\s\\S]*<span style=\"position:fixed;top: 0px;[\\s\\S]*width=\"227\" height=\"83\" /></a></span>[\\s\\S]*?</p>";
        range = [content rangeOfString:regexstr options:NSRegularExpressionSearch];
        if (range.location != NSNotFound) {
            content = [content stringByReplacingCharactersInRange:range withString:@""];
            NSLog(@"此词条为 R18 限制");
        }
        
        //banner修正
        content = [content stringByReplacingOccurrencesOfString:@"<table class=\"common-box\" style=\"margin: 0px 10%; width:80%;" withString:@"<table class=\"common-box\" style=\""];
        content = [content stringByReplacingOccurrencesOfString:@"<table class=\"common-box\" style=\"margin: 0px 10%; width:350px;" withString:@"<table class=\"common-box\" style=\""];
        
        //Template:Vocaloid Songbox
        regexstr = @"align=\"center\" width=\"450px\" style=\"border:0px; text-align:center; line-height:1.3em;\" class=\"infotemplate\"";
        range = [content rangeOfString:regexstr];
        while (range.location != NSNotFound) {
            content = [content stringByReplacingCharactersInRange:range withString:@"align=\"center\" style=\"border:0px; text-align:center; line-height:1.3em;width:100%;margin-left:-5px;\" class=\"infotemplate\""];
            range = [content rangeOfString:regexstr options:NSRegularExpressionSearch];
        }
        
        //flashmp3 插件修正，针对音频
        regexstr = @"<script language=\"JavaScript\" src=\"/extensions/FlashMP3/audio-player\\.js\".*soundFile=";
        range = [content rangeOfString:regexstr options:NSRegularExpressionSearch];
        while (range.location != NSNotFound) {
            content = [content stringByReplacingCharactersInRange:range withString:@"<audio src=\""];
            range = [content rangeOfString:regexstr options:NSRegularExpressionSearch];
        }
        regexstr = @"\"><param name=\"quality\" value=\"high\"><param name=\"menu\" value=\"false\"><param name=\"wmode\" value=\"transparent\"></object>";
        range = [content rangeOfString:regexstr options:NSRegularExpressionSearch];
        while (range.location != NSNotFound) {
            content = [content stringByReplacingCharactersInRange:range withString:@"\" controls=\"controls\"></audio>"];
            range = [content rangeOfString:regexstr options:NSRegularExpressionSearch];
        }
    
    
    
    NSString * header = [NSString stringWithContentsOfFile:[htmlDocumentPath stringByAppendingPathComponent:@"pageheader"] encoding:NSUTF8StringEncoding error:nil];
    NSString * footer = [NSString stringWithContentsOfFile:[htmlDocumentPath stringByAppendingPathComponent:@"pagefooter"] encoding:NSUTF8StringEncoding error:nil];
    
    content = [NSString stringWithFormat:@"%@%@%@",header,content,footer];
    /*============*/
    
    return content;
}

- (void)loadContentWithDecodedKeyWord:(NSString *)keywordAfterDecode useCache:(BOOL)useCache
{
    _keyword = keywordAfterDecode;
    _contentRequest = [mcCachedRequest new];
    [_contentRequest setHook:self];
    [_contentRequest launchRequest:[NSString stringWithFormat:@"%@/%@?action=render",_targetURL,_keyword] ignoreCache:useCache];
}

- (void)loadContentWithKeyWord:(NSString *)keyword useCache:(BOOL)useCache
{
    [self loadContentWithDecodedKeyWord:[self urlEncode:keyword] useCache:useCache];
}

-(void)mcCachedRequestFinishLoading:(bool)success LoadFromCache:(bool)cache error:(NSString *)error data:(NSMutableData *)data
{
    if (success) {
        [self loadHTMLString:[self prepareContent:data]
                     baseURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/moegirl-app-2.0/%@",_targetURL,_keyword]]];
    } else {
        NSLog(@"Error: %@",error);
    }
}

@end
