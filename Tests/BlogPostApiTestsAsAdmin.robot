*** Settings ***
Documentation    This test suite uses Admin request headers to test BlogPostAPI.
...              For an admin, BlogPostAPI provides GET, POST, PUT, DELETE methods
...              as well as OPTIONS method. The URL of the API is:
...              https://glacial-earth-31542.herokuapp.com/api/postings/
Metadata         Version    1.0
Metadata         OS         Linux
Resource         ../Libraries/Src/CommonLibraryImport.robot
Suite Teardown   Suite Teardown

*** Variables ***
${REGISTERED_POSTINGS}      A list, set dynamically
${POST_RESPONSE}            A response object to POST request, set dynamically
${OPTIONS_RESPONSE}         A response object to OPTIONS request, set dynamically
${POSTING_SPEC}             A dictionary object, where items are posting fields. Set dynamically
${DELETE_RESPONSE}          A response object to DELETE request, set dynamically
${PRE_SET_POSTINGS}         A list of pre-existing postings in the system before tests with the tag 'CRUD-operations-as-admin' run

# To Run
# python -m robot  --pythonpath Libraries/Src --noncritical failure-expected -d Results/ Tests/BlogPostApiTestsAsAdmin.robot

*** Keywords ***
Suite Teardown
    Delete All Sessions

"Registered Postings" Comply With "Posting Spec"
    Verify All Postings     postings_to_verify=${REGISTERED_POSTINGS}   posting_spec=${POSTING_SPEC}

Create Posting
    [Arguments]       ${posting}
    ${POST_RESPONSE} =  Make Post Request  posting=${posting}
    Set Test Variable   ${POST_RESPONSE}

Verify Post Response Success Code
    Should Be Equal As Integers 	${POST_RESPONSE.status_code} 	201  # Created

"Target Postings" Are Created
    FOR     ${p}    IN  @{TARGET_POSTINGS}
        Create Posting     posting=${p}
        Verify Post Response Success Code
    END

"Target Postings" Are Registered In The System
    Is Subset   subset=${TARGET_POSTINGS}   superset=${REGISTERED_POSTINGS}

Update Posting
    [Arguments]        ${posting}
    ${PUT_RESPONSE} =   Make Put Request  posting=${posting}
    Set Test Variable   ${PUT_RESPONSE}


Delete Posting
    [Arguments]     ${posting}
    ${DELETE_RESPONSE} =     Make Delete Request    posting=${posting}
    Set Test Variable       ${DELETE_RESPONSE}

"Registered Postings" Are Read
    ${GET_RESPONSE} =   Make Get Request
    Should Be Equal As Integers 	${GET_RESPONSE.status_code} 	200
    @{registered_postings} =    Set Variable  ${GET_RESPONSE.json()}
    Set Suite Variable   @{REGISTERED_POSTINGS}     @{registered_postings}

BlogPostAPI Specification Is Correct
    Verify Options Response     options_response=${OPTIONS_RESPONSE}

Set "Posting Spec"
    Set Suite Variable  ${POSTING_SPEC}      ${OPTIONS_RESPONSE.json()}[actions][POST]

BlogPostAPI Specification Is Queried
    ${OPTIONS_RESPONSE} =       Make Options Request
    Set Test Variable   ${OPTIONS_RESPONSE}

"Target Postings" Are Updated In The System
    Is Subset   subset=${EXPECTED_MODIFIED_POSTINGS}    superset=${REGISTERED_POSTINGS}

Verify Delete Response Success Code
    Should Be Equal As Integers 	${DELETE_RESPONSE.status_code} 	200  # OK

"Target Postings" Are Deleted
    FOR     ${ptd}    IN  @{POSTINGS_TO_DELETE}  # ptd: posting_to_delete
        Delete Posting    posting=${ptd}
        Verify Delete Response Success Code
    END

Only "Pre-Set Postings" Are Left In The System
    Should Be True  $REGISTERED_POSTINGS == $PRE_SET_POSTINGS

*** Test Cases ***
Check BlogPostAPI specification
    [Tags]              smoke-as-admin
    When BlogPostAPI Specification Is Queried
    Then BlogPostAPI Specification Is Correct
    Set "Posting Spec"  # for later use in upcoming test cases

Query & Verify Pre-Set Postings
    [Tags]              smoke-as-admin
    When "Registered Postings" Are Read
    Then "Registered Postings" Comply With "Posting Spec"
    # to be used later
    Set Suite Variable      @{PRE_SET_POSTINGS}     @{REGISTERED_POSTINGS}

Creating "Target Postings"
    [Tags]              CRUD-operations-as-admin
    When "Target Postings" Are Created
    Then "Registered Postings" Are Read
    Then "Registered Postings" Comply With "Posting Spec"
    Then "Target Postings" Are Registered In The System

Updating "Target Postings"
    [Tags]                  CRUD-operations-as-admin
    When Target Postings Are Updated
    Then "Registered Postings" Are Read
    Then "Registered Postings" Comply With "Posting Spec"
    Then "Target Postings" Are Updated In The System

    # to be used by the next test case
    Set Suite Variable      @{POSTINGS_TO_DELETE}       @{EXPECTED_MODIFIED_POSTINGS}  # to be semantically correct in the next test

Deleting "Target Postings"
    [Tags]                  CRUD-operations-as-admin
    When "Target Postings" Are Deleted    # test
    Then "Registered Postings" Are Read
    Then "Registered Postings" Comply With "Posting Spec"
    Then Only "Pre-Set Postings" Are Left In The System










