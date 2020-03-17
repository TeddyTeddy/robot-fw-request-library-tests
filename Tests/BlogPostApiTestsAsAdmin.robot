*** Settings ***
Documentation    This test suite uses robotframework-request library to test BlogPostAPI
...              Note that the API supports only: 'GET, POST, HEAD, OPTIONS' methods on URL:
...              https://glacial-earth-31542.herokuapp.com/api/postings/
...              If you want to update/delete a posting, then you need to use its url. For example:
...              https://glacial-earth-31542.herokuapp.com/api/postings/26/
Library 	     RequestsLibrary
Library          Collections
Resource         ../Libraries/Src/CommonLibraryImport.robot
Suite Teardown   Suite Teardown

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

Verify Post Request Success
    Should Be Equal As Integers 	${POST_RESPONSE.status_code} 	201  # Created

Create "Target Postings"
    FOR     ${p}    IN  @{TARGET_POSTINGS}
        Create Posting     posting=${p}
        Verify Post Request Success
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
    Should Be Equal As Integers 	${DELETE_RESPONSE.status_code} 	200  # OK

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

Modify The Contents Of "Target Postings"
    @{expected_modified_postings} =     Create List
    FOR     ${ptm}    IN  @{TARGET_POSTINGS}  # ptm: posting_to_modify
        ${is_match}   ${registered_posting} =  Is Match    expected_posting=${ptm}    postings_set=${REGISTERED_POSTINGS}
        Should Be True     $is_match
        Set To Dictionary       dictionary=${registered_posting}       content=modified content   #  << modifying the content
        Update Posting    posting=${registered_posting}              # test call: supposed to update the system
        Should Be Equal As Integers 	${PUT_RESPONSE.status_code} 	200  # OK
        Append To List      ${expected_modified_postings}       ${registered_posting}
    END
    Set Test Variable  @{EXPECTED_MODIFIED_POSTINGS}    @{expected_modified_postings}

Verify "Target Postings" Modified
    Is Subset   subset=${EXPECTED_MODIFIED_POSTINGS}    superset=${REGISTERED_POSTINGS}

Delete "Target Postings"
    FOR     ${ptd}    IN  @{POSTINGS_TO_DELETE}  # ptd: posting_to_delete
        Delete Posting    posting=${ptd}
    END

Verify Only "Pre-Set Postings" Left
    Should Be True  $REGISTERED_POSTINGS == $PRE_SET_POSTINGS

*** Test Cases ***
Check BlogPostAPI specification
    [Tags]              smoke-as-admin
    Query BlogPostAPI Specification
    Verify BlogPostAPI Specification
    Set "Posting Spec"  # for later use in upcoming test cases

Query & Verify Pre-Set Postings (Admin)
    [Tags]              smoke-as-admin
    Read "Registered Postings"
    Verify "Registered Postings" Against Posting Spec
    # to be used later
    Set Suite Variable      @{PRE_SET_POSTINGS}     @{REGISTERED_POSTINGS}

Test Creating "Target Postings"
    [Tags]              CRUD-operations-as-admin
    Create "Target Postings"  # test
    Read "Registered Postings"
    Verify "Registered Postings" Against Posting Spec
    Verify "Target Postings" Created

Test Modifying The Contents Of "Target Postings"
    [Tags]                  CRUD-operations-as-admin
    Modify The Contents Of "Target Postings"  # test
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










