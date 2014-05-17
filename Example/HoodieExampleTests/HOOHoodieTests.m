#import <XCTest/XCTest.h>
#define EXP_SHORTHAND
#import <Expecta/Expecta.h>
#import <HOOHoodie/HOOHoodie.h>

@interface HOOHoodieTests : XCTestCase

@end

@implementation HOOHoodieTests

- (void)testInitializer
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"HoodieID"];

    NSURL *baseURL = [NSURL URLWithString:@"https://myapi.com/_api"];
    HOOHoodie *subjectUnderTest = [[HOOHoodie alloc] initWithBaseURL:baseURL];

    expect(subjectUnderTest).toNot.beNil();

    expect(subjectUnderTest.hoodieID).toNot.beNil();

    expect(subjectUnderTest.store).toNot.beNil();
    expect(subjectUnderTest.store).to.beKindOf(HOOStore.class);

    expect(subjectUnderTest.account).toNot.beNil();
    expect(subjectUnderTest.account).to.beKindOf(HOOAccount.class);
}

- (void)testUsesSavedHoodieID
{
    [[NSUserDefaults standardUserDefaults] setObject:@"1234abc" forKey:@"HoodieID"];

    NSURL *baseURL = [NSURL URLWithString:@"https://myapi.com/_api"];
    HOOHoodie *subjectUnderTest = [[HOOHoodie alloc] initWithBaseURL:baseURL];

    expect(subjectUnderTest.hoodieID).to.equal(@"1234abc");
}

@end
