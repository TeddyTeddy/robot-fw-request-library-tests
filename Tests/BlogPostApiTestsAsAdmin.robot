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

Verify "Registered Postings" Against Posting Spec
    Verify All Postings     postings_to_verify=${REGISTERED_POSTINGS}   posting_spec=${POSTING_SPEC}

Create Posting
    [Arguments]       ${posting}
    ${POST_RESPONSE} =  Make Post Request  posting=${posting}
    Set Test Variable   ${POST_RESPONSE}

Verify Post Response Success Code
    Should Be Equal As Integers 	${POST_RESPONSE.status_code} 	201  # Created

Create "Target Postings"
    FOR     ${p}    IN  @{TARGET_POSTINGS}
        Create Posting     posting=${p}
        Verify Post Response Success Code
    END

Verify "Target Postings" Created
    Is Subset   subset=${TARGET_POSTINGS}   superset=${REGISTERED_POSTINGS}

Update Posting
    [Arguments]        ${posting}
    ${PUT_RESPONSE} =   Make Put Request  posting=${posting}
    Set Test Variable   ${PUT_RESPONSE}


Delete Posting
    [Arguments]     ${posting}
    ${DELETE_RESPONSE} =     Make Delete Request    posting=${posting}
    Set Test Variable       ${DELETE_RESPONSE}

Read "Registered Postings"
    ${GET_RESPONSE} =   Make Get Request
    Should Be Equal As Integers 	${GET_RESPONSE.status_code} 	200
    @{registered_postings} =    Set Variable  ${GET_RESPONSE.json()}
    Set Suite Variable   @{REGISTERED_POSTINGS}     @{registered_postings}

Verify BlogPostAPI Specification
    Verify Options Response     options_response=${OPTIONS_RESPONSE}

Set "Posting Spec"
    Set Suite Variable  ${POSTING_SPEC}      ${OPTIONS_RESPONSE.json()}[actions][POST]

Query BlogPostAPI Specification
    ${OPTIONS_RESPONSE} =       Make Options Request
    Set Test Variable   ${OPTIONS_RESPONSE}

Verify "Target Postings" Modified
    Is Subset   subset=${EXPECTED_MODIFIED_POSTINGS}    superset=${REGISTERED_POSTINGS}

Verify Delete Response Success Code
    Should Be Equal As Integers 	${DELETE_RESPONSE.status_code} 	200  # OK

Delete "Target Postings"
    FOR     ${ptd}    IN  @{POSTINGS_TO_DELETE}  # ptd: posting_to_delete
        Delete Posting    posting=${ptd}
        Verify Delete Response Success Code
    END

Verify Only "Pre-Set Postings" Left
    Should Be True  $REGISTERED_POSTINGS == $PRE_SET_POSTINGS

*** Test Cases ***
Check BlogPostAPI specification
    [Tags]              smoke-as-admin
    Query BlogPostAPI Specification
    Verify BlogPostAPI Specification
    Set "Posting Spec"  # for later use in upcoming test cases

Query & Verify Pre-Set Postings
    [Tags]              smoke-as-admin
    Read "Registered Postings"
    Verify "Registered Postings" Against Posting Spec
    # to be used later
    Set Suite Variable      @{PRE_SET_POSTINGS}     @{REGISTERED_POSTINGS}

Creating "Target Postings"
    [Tags]              CRUD-operations-as-admin
    Create "Target Postings"  # test
    Read "Registered Postings"
    Verify "Registered Postings" Against Posting Spec
    Verify "Target Postings" Created

Updating "Target Postings"
    [Tags]                  CRUD-operations-as-admin
    Update Target Postings  # test
    Read "Registered Postings"
    Verify "Registered Postings" Against Posting Spec
    Verify "Target Postings" Modified

    # to be used by the next test case
    Set Suite Variable      @{POSTINGS_TO_DELETE}       @{EXPECTED_MODIFIED_POSTINGS}  # to be semantically correct in the next test

Deleting "Target Postings"
    [Tags]                  CRUD-operations-as-admin
    Delete "Target Postings"    # test
    Read "Registered Postings"
    Verify "Registered Postings" Against Posting Spec
    Verify Only "Pre-Set Postings" Left










