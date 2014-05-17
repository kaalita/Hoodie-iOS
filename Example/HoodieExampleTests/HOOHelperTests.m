#import <XCTest/XCTest.h>
#import <HOOHoodie/HOOHelper.h>
#define EXP_SHORTHAND
#import <Expecta/Expecta.h>

@interface HOOHelperTests : XCTestCase

@end

@implementation HOOHelperTests

- (void)testHoodieIDIs7CharsLong
{
    NSString *idUnderTest = [HOOHelper generateHoodieID];
    expect(idUnderTest.length).to.equal(7);
}

- (void)testHoodieIDIsFulfillingRegex
{
    NSString *idUnderTest = [HOOHelper generateHoodieID];
    NSError *error;
    NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:@"^[a-z0-9]*$"
                                                                                       options:0
                                                                                         error:&error];
    NSRange range = NSMakeRange(0, idUnderTest.length);
    NSString *replacedText = [regularExpression stringByReplacingMatchesInString:idUnderTest
                                                                         options:0
                                                                           range:range
                                                                    withTemplate:@""];

    expect(error).to.beNil();
    expect(replacedText.length).to.equal(0);
}

@end
