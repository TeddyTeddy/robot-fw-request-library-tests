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
Suite Setup      Suite Setup
Suite Teardown   Suite Teardown
Test Teardown    Test Teardown
Test Setup       Test Setup

*** Variables ***
${REGISTERED_POSTINGS}      A list of postings read from the API, set dynamically
${POST_RESPONSE}            A response object to POST request, set dynamically
${OPTIONS_RESPONSE}         A response object to OPTIONS request, set dynamically
${POSTING_SPEC}             A dictionary object, where items are posting fields. Set dynamically
${DELETE_RESPONSE}          A response object to DELETE request, set dynamically
${PRE_SET_POSTINGS}         A list of pre-existing postings in the system before tests with the tag 'CRUD-operations-as-NoPriviligeUser' run
${RANDOM_TARGET_POSTING}    A dynamically picked target posting during test run. Set to None at the beginning & end of every test

# To Run
# python -m robot  --pythonpath Libraries/Src -d Results/ Tests/BlogPostApiTestsAsNoPriviligeUser.robot

*** Keywords ***
Suite Setup
    ${posting_spec} =   Set Variable    ${ADMIN}[EXPECTED_API_SPEC][actions][POST]
    Set Suite Variable      ${POSTING_SPEC}     ${posting_spec}

Suite Teardown
    Delete All Sessions

Test Setup
    Delete Every Posting Except "Pre-Set Postings"  # from previous suite run, we have INCOMPLETE_TARGET_POSTINGS in the system
    "Pre-Set Postings" Are Cached
    Set Suite Variable  ${RANDOM_TARGET_POSTING}      ${None}

Test Teardown
    Delete Every Posting Except "Pre-Set Postings"
    "Registered Postings" Are Read
    Only "Pre-Set Postings" Are Left In The System
    Set Suite Variable  ${RANDOM_TARGET_POSTING}      ${None}

Delete Every Posting Except "Pre-Set Postings"
    "Registered Postings" Are Read
    "Target Postings" Are Deleted

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
    FOR     ${iptd}    IN  @{INCOMPLETE_TARGET_POSTINGS}  # iptd: incomplete_posting_to_delete
        Delete Matching Posting    ${iptd}
    END

Only "Pre-Set Postings" Are Left In The System
    Should Be True  $REGISTERED_POSTINGS == $PRE_SET_POSTINGS

"Pre-Set Postings" Are Cached
    "Registered Postings" Are Read
    Set Suite Variable      @{PRE_SET_POSTINGS}     @{REGISTERED_POSTINGS}

*** Test Cases ***
#########################  POSITIVE TESTS ################################################
Checking BlogPostAPI specification
    [Tags]              smoke-as-NoPriviligeUser
    When BlogPostAPI Specification Is Queried
    Then BlogPostAPI Specification Is Correct








