*** Settings ***
Documentation    This test suite uses NoPriviligeUser's request headers to test BlogPostAPI.
...              For a NoPriviligeUser, BlogPostAPI provides GET, POST methods
...              as well as OPTIONS method. Note that  PUT and DELETE methods are not supported.
...              Therefore, we can make Create but we cannot Delete as NoPriviligeUser.
...              Since we do Create in this test suite, and we want to ensure that sytem remains
...              intact, we use AdminUser's rights to Delete in Test Teardown.
...              The URL of the API is:
...              https://glacial-earth-31542.herokuapp.com/api/postings/
Metadata         Version    1.0
Metadata         OS         Linux
Resource         ../Libraries/Src/CommonLibraryImport.robot
Library          NoPriviligeUser
Library          AdminUser
Resource         CommonResource.robot
Suite Setup      Suite Setup
Suite Teardown   Suite Teardown
Test Teardown    Test Teardown
Test Setup       Test Setup

# To Run
# python -m robot  --pythonpath Libraries/Src -d Results/ Tests/BlogPostApiTestsAsNoPriviligeUser.robot

*** Keywords ***
Suite Setup
    ${posting_spec} =   Set Variable    ${ADMIN}[EXPECTED_API_SPEC][actions][POST]
    Set Suite Variable      ${POSTING_SPEC}     ${posting_spec}

Suite Teardown
    Delete All Sessions

Test Setup
    "Target Postings" Are Deleted  # from previous suite run, we might have INCOMPLETE_TARGET_POSTINGS in the system
    "Pre-Set Postings" Are Cached
    Set Suite Variable  ${RANDOM_TARGET_POSTING}      ${None}

Test Teardown
    "Target Postings" Are Deleted
    "Registered Postings" Are Read
    Only "Pre-Set Postings" Are Left In The System
    Set Suite Variable  ${RANDOM_TARGET_POSTING}      ${None}

Create Posting
    [Arguments]       ${posting}
    ${POST_RESPONSE} =  NoPriviligeUser.Make Post Request  posting=${posting}
    Set Test Variable   ${POST_RESPONSE}

Verify Post Response Success Code
    Should Be Equal As Integers 	${POST_RESPONSE.status_code} 	201  # Created

"Target Postings" Are Created
    FOR     ${p}    IN  @{INCOMPLETE_TARGET_POSTINGS}
        Create Posting     posting=${p}
        Verify Post Response Success Code
    END

"Registered Postings" Are Read
    ${GET_RESPONSE} =  NoPriviligeUser.Make Get Request
    Should Be Equal As Integers 	${GET_RESPONSE.status_code} 	200
    @{registered_postings} =    Set Variable  ${GET_RESPONSE.json()}
    Set Suite Variable   @{REGISTERED_POSTINGS}     @{registered_postings}
    
BlogPostAPI Specification Is Correct
    NoPriviligeUser.Verify Options Response     options_response=${OPTIONS_RESPONSE}

BlogPostAPI Specification Is Queried
    ${OPTIONS_RESPONSE} =       NoPriviligeUser.Make Options Request
    Set Test Variable   ${OPTIONS_RESPONSE}

"Target Postings" Are Deleted
    "Registered Postings" Are Read
    FOR     ${iptd}    IN  @{INCOMPLETE_TARGET_POSTINGS}  # iptd: incomplete_posting_to_delete
        Delete Matching Posting    ${iptd}
    END

Only "Pre-Set Postings" Are Left In The System
    Should Be True  $REGISTERED_POSTINGS == $PRE_SET_POSTINGS

"Target Postings" Must Not Be Registered In The System
    "Registered Postings" Are Read
    ${none_of_target_postings_found} =  Is None Found  subset=${INCOMPLETE_TARGET_POSTINGS}  superset=${REGISTERED_POSTINGS}
    Should Be True      ${none_of_target_postings_found}

"Pre-Set Postings" Are Cached
    "Registered Postings" Are Read
    Set Suite Variable      @{PRE_SET_POSTINGS}     @{REGISTERED_POSTINGS}

*** Test Cases ***
#########################  POSITIVE TESTS ################################################
Checking BlogPostAPI specification
    [Tags]              smoke-as-NoPriviligeUser
    When BlogPostAPI Specification Is Queried
    Then BlogPostAPI Specification Is Correct

Querying & Verifying Pre-Set Postings
    [Tags]              smoke-as-NoPriviligeUser
    When "Registered Postings" Are Read
    Then "Registered Postings" Must Comply With "Posting Spec"

Creating "Target Postings"
    [Tags]              CRUD-operations-as-NoPriviligeUser    CRUD-success-as-NoPriviligeUser
    Given "Target Postings" Must Not Be Registered In The System
    When "Target Postings" Are Created
    Then "Registered Postings" Are Read
    Then "Registered Postings" Must Comply With "Posting Spec"
    Then "Target Postings" Are Read
    Then "Target Postings" Must Be Registered In The System







