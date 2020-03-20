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

"Registered Postings" Must Comply With "Posting Spec"
    Verify All Postings     postings_to_verify=${REGISTERED_POSTINGS}   posting_spec=${POSTING_SPEC}

Create Posting
    [Arguments]       ${posting}
    ${POST_RESPONSE} =  Make Post Request  posting=${posting}
    Set Test Variable   ${POST_RESPONSE}

Verify Post Response Success Code
    Should Be Equal As Integers 	${POST_RESPONSE.status_code} 	201  # Created

"Target Postings" Are Created
    FOR     ${p}    IN  @{INCOMPLETE_TARGET_POSTINGS}
        Create Posting     posting=${p}
        Verify Post Response Success Code
    END

"Target Postings" Are Attempted To Be Re-Created
    ${ALL_CREATE_ATTEMPTS_FAILED_WITH_400} =    Set Variable    ${True}
    FOR     ${p}    IN  @{INCOMPLETE_TARGET_POSTINGS}
        Create Posting     posting=${p}
        ${ALL_CREATE_ATTEMPTS_FAILED_WITH_400} =    Evaluate    $ALL_CREATE_ATTEMPTS_FAILED_WITH_400 and $POST_RESPONSE.status_code==400
    END
    Set Test Variable    ${ALL_CREATE_ATTEMPTS_FAILED_WITH_400}

All Create Responses Have Status Code "400-Bad Request"
    Should Be True      ${ALL_CREATE_ATTEMPTS_FAILED_WITH_400}

"Target Postings" List Is Not Empty
    ${is_empty} =  Evaluate     len($TARGET_POSTINGS) == 0
    Should Not Be True  ${is_empty}

"Target Postings" Are Registered In The System
    "Target Postings" List Is Not Empty
    ${is_subset} =  Is Subset   subset=${TARGET_POSTINGS}   superset=${INCOMPLETE_TARGET_POSTINGS}
    Should Be True  ${is_subset}

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

"Target Postings" Are Read
    "Registered Postings" Are Read
    @{target_postings} =    Get Subset  subset=${INCOMPLETE_TARGET_POSTINGS}   superset=${REGISTERED_POSTINGS}
    Set Suite Variable      @{TARGET_POSTINGS}     @{target_postings}

BlogPostAPI Specification Is Correct
    Verify Options Response     options_response=${OPTIONS_RESPONSE}

Set "Posting Spec"
    Set Suite Variable  ${POSTING_SPEC}      ${OPTIONS_RESPONSE.json()}[actions][POST]

BlogPostAPI Specification Is Queried
    ${OPTIONS_RESPONSE} =       Make Options Request
    Set Test Variable   ${OPTIONS_RESPONSE}

"Target Postings" Must Have Been Updated In The System
    ${is_subset} =  Is Subset   subset=${INCOMPLETE_TARGET_POSTINGS}    superset=${REGISTERED_POSTINGS}
    Should Be True   ${is_subset}

Verify Delete Response Success Code
    Should Be Equal As Integers 	${DELETE_RESPONSE.status_code} 	200  # OK

"Target Postings" Are Deleted
    FOR     ${ptd}    IN  @{TARGET_POSTINGS}  # ptd: posting_to_delete
        Delete Posting    posting=${ptd}
        Verify Delete Response Success Code
    END

"Target Postings" Are Attempted To Be Deleted
    ${ALL_DELETE_ATTEMPTS_FAILED_WITH_404} =     Set Variable  ${True}
    FOR     ${ptd}    IN  @{TARGET_POSTINGS}  # ptd: posting_to_delete
        Delete Posting    posting=${ptd}
        ${ALL_DELETE_ATTEMPTS_FAILED_WITH_404} =     Evaluate    $ALL_DELETE_ATTEMPTS_FAILED_WITH_404 and $DELETE_RESPONSE.status_code==404
    END
    Set Test Variable   ${ALL_DELETE_ATTEMPTS_FAILED_WITH_404}

All Delete Responses Have Status Code "404-Not Found"
    Should Be True   ${ALL_DELETE_ATTEMPTS_FAILED_WITH_404}

Only "Pre-Set Postings" Are Left In The System
    Should Be True  $REGISTERED_POSTINGS == $PRE_SET_POSTINGS

"Target Postings" Are Not Registered
    "Registered Postings" Are Read
    Only "Pre-Set Postings" Are Left In The System

*** Test Cases ***
Check BlogPostAPI specification
    [Tags]              smoke-as-admin
    When BlogPostAPI Specification Is Queried
    Then BlogPostAPI Specification Is Correct
    Set "Posting Spec"  # for later use in upcoming test cases

Query & Verify Pre-Set Postings
    [Tags]              smoke-as-admin
    When "Registered Postings" Are Read
    Then "Registered Postings" Must Comply With "Posting Spec"
    # to be used later
    Set Suite Variable      @{PRE_SET_POSTINGS}     @{REGISTERED_POSTINGS}

Creating "Target Postings"
    [Tags]              CRUD-operations-as-admin    CRUD-success-as-admin
    When "Target Postings" Are Created
    Then "Registered Postings" Are Read
    Then "Registered Postings" Must Comply With "Posting Spec"
    Then "Target Postings" Are Read
    Then "Target Postings" Are Registered In The System

Updating "Target Postings"
    [Tags]                  CRUD-operations-as-admin    CRUD-success-as-admin
    Given "Target Postings" Are Read
    Given "Target Postings" Are Registered In The System
    When Target Postings Are Updated
    Then "Registered Postings" Are Read
    Then "Registered Postings" Must Comply With "Posting Spec"
    Then "Target Postings" Must Have Been Updated In The System

Deleting "Target Postings"
    [Tags]                  CRUD-operations-as-admin     CRUD-success-as-admin
    Given "Target Postings" Are Read
    Given "Target Postings" Are Registered In The System
    When "Target Postings" Are Deleted    # test
    Then "Registered Postings" Are Read
    Then "Registered Postings" Must Comply With "Posting Spec"
    Then Only "Pre-Set Postings" Are Left In The System

Attempting To Delete Non-Existing "Target Postings" Fails
    [Tags]                  CRUD-operations-as-admin     CRUD-failure-as-admin
    Given "Target Postings" Are Not Registered
    When "Target Postings" Are Attempted To Be Deleted
    Then All Delete Responses Have Status Code "404-Not Found"

Attempting To Re-Create Already Registered "Target Postings" Fails
    [Tags]                  CRUD-operations-as-admin     CRUD-failure-as-admin
    Given "Target Postings" Are Created
    Given "Registered Postings" Are Read
    Given "Target Postings" Are Read
    Given "Target Postings" Are Registered In The System

    When "Target Postings" Are Attempted To Be Re-Created
    Then All Create Responses Have Status Code "400-Bad Request"    # test verification
    # test teardown & its verification
    Then "Target Postings" Are Deleted  # test-teardown
    Then "Registered Postings" Are Read   # ${REGISTERED_POSTINGS} gets set
    Then Only "Pre-Set Postings" Are Left In The System  # test-teardown verification











