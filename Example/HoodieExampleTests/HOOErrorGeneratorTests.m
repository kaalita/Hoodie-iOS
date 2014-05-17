#import <XCTest/XCTest.h>
#define EXP_SHORTHAND
#import <Expecta/Expecta.h>
#import <HOOHoodie/HOOErrorGenerator.h>

@interface HOOErrorGeneratorTests : XCTestCase

@end

@implementation HOOErrorGeneratorTests

- (void)testSignUpUsernameEmptyError
{
    NSError *errorUnderTest = [HOOErrorGenerator errorWithType:HOOAccountSignUpUsernameEmptyError];

    expect(errorUnderTest).toNot.beNil();
    expect(errorUnderTest).to.beKindOf(NSError.class);
    expect(errorUnderTest.code).to.equal(-101);
    expect(errorUnderTest.domain).to.equal(@"hoodie.account");
    expect(errorUnderTest.localizedDescription).to.equal(@"Sign up failed");
    expect(errorUnderTest.localizedFailureReason).to.equal(@"Username can not be empty.");
    expect(errorUnderTest.localizedRecoverySuggestion).to.equal(@"Please enter a username.");
}

- (void)testSignUpUsernameTakenError
{
    NSError *errorUnderTest = [HOOErrorGenerator errorWithType:HOOAccountSignUpUsernameTakenError];

    expect(errorUnderTest).toNot.beNil();
    expect(errorUnderTest).to.beKindOf(NSError.class);
    expect(errorUnderTest.code).to.equal(-102);
    expect(errorUnderTest.domain).to.equal(@"hoodie.account");
    expect(errorUnderTest.localizedDescription).to.equal(@"Sign up failed");
    expect(errorUnderTest.localizedFailureReason).to.equal(@"Username already taken.");
    expect(errorUnderTest.localizedRecoverySuggestion).to.equal(@"Please try another username.");
}

- (void)testAccountUnconfirmedError
{
    NSError *errorUnderTest = [HOOErrorGenerator errorWithType:HOOAccountUnconfirmedError];

    expect(errorUnderTest).toNot.beNil();
    expect(errorUnderTest).to.beKindOf(NSError.class);
    expect(errorUnderTest.code).to.equal(-103);
    expect(errorUnderTest.domain).to.equal(@"hoodie.account");
    expect(errorUnderTest.localizedDescription).to.equal(@"Account not confirmed");
    expect(errorUnderTest.localizedFailureReason).to.equal(@"The account as not been confirmed yet.");
    expect(errorUnderTest.localizedRecoverySuggestion).to.equal(@"Please try again later.");
}

- (void)testAccountSignInWrongCredentialsError
{
    NSError *errorUnderTest = [HOOErrorGenerator errorWithType:HOOStoreDocumentDoesNotExistError];

    expect(errorUnderTest).toNot.beNil();
    expect(errorUnderTest).to.beKindOf(NSError.class);
    expect(errorUnderTest.code).to.equal(-105);
    expect(errorUnderTest.domain).to.equal(@"hoodie.store");
    expect(errorUnderTest.localizedDescription).to.equal(@"Document does not exist");
    expect(errorUnderTest.localizedFailureReason).to.equal(@"A document with the given id and type does not exist.");
    expect(errorUnderTest.localizedRecoverySuggestion).to.equal(@"Please make sure the given id and type are correct.");
}

@end
