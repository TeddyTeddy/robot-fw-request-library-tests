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

Create "Additional Postings"
    FOR     ${p}    IN  @{POSTINGS_TO_CREATE}
        Create Posting     posting=${p}
        Verify Post Request Success
    END

Verify "Additional Postings" Created
    FOR     ${expected_posting}    IN  @{POSTINGS_TO_CREATE}
        ${is_match}   ${matched_posting} =    Is Match    expected_posting=${expected_posting}    registered_postings=${REGISTERED_POSTINGS}
        Should Be True  $is_match
    END

Update Posting
    [Arguments]        ${posting}
    ${PUT_RESPONSE} =   Make Put Request  posting=${posting}
    Should Be Equal As Integers 	${PUT_RESPONSE.status_code} 	200  # OK

Delete Posting
    [Arguments]     ${posting}
    ${DELETE_RESPONSE} =     Make Delete Request    posting=${posting}
    Should Be Equal As Integers 	${DELETE_RESPONSE.status_code} 	200  # OK

Read "Registered Postings"
    ${GET_RESPONSE} =   Make Get Request
    Should Be Equal As Integers 	${GET_RESPONSE.status_code} 	200
    @{registered_postings} =    Set Variable  ${GET_RESPONSE.json()}
    Set Suite Variable   @{REGISTERED_POSTINGS}     @{registered_postings}

Is Match
    [Documentation]     Note that registered_postings is a list of postings, which are dictionaries.
    ...                 Each posting in registered postings have 'title' & 'content' keys.
    ...                 expected_posting is a dictionary with keys 'title' and 'content' as well.
    ...                 For each posting in registered_postings, we try to find a match its title & its content
    ...                 to that of expected_posting's title & content respectively. If such a match occurs,
    ...                 we return True, otherwise we return false

    [Arguments]    ${expected_posting}    ${registered_postings}
    ${is_match}=     Set Variable    ${False}
    ${matched_posting} =    Set Variable   ${None}
    FOR     ${rp}   IN   @{registered_postings}  # rp: registered_posting
        ${is_match}=     Evaluate   $rp['title']==$expected_posting['title'] and $rp['content']==$expected_posting['content']
        ${matched_posting} =    Set Variable If   $is_match       ${rp}       ${None}
        Exit For Loop If    $is_match
    END
    [Return]    ${is_match}     ${matched_posting}

Verify BlogPostAPI Specification
    Verify Options Response     options_response=${OPTIONS_RESPONSE}

Set "Posting Spec"
    Set Suite Variable  ${POSTING_SPEC}      ${OPTIONS_RESPONSE.json()}[actions][POST]

Query BlogPostAPI Specification
    ${OPTIONS_RESPONSE} =       Make Options Request
    Set Test Variable   ${OPTIONS_RESPONSE}

Modify The Contents Of "Additional Postings"
    @{expected_modified_postings} =     Create List
    FOR     ${ptm}    IN  @{POSTINGS_TO_MODIFY}  # ptm: posting_to_modify
        ${is_match}   ${registered_posting} =  Is Match    expected_posting=${ptm}    registered_postings=${REGISTERED_POSTINGS}
        Should Be True     $is_match
        Set To Dictionary       dictionary=${registered_posting}       content=modified content   #  << modifying the content
        Update Posting    posting=${registered_posting}              # test call: supposed to update the system
        Append To List      ${expected_modified_postings}       ${registered_posting}
    END
    Set Test Variable  @{EXPECTED_MODIFIED_POSTINGS}    @{expected_modified_postings}

Verify "Additional Postings" Modified
    FOR     ${emp}    IN  @{EXPECTED_MODIFIED_POSTINGS}  # emp: expected_modified_posting
        ${is_match}   ${matched_posting} =    Is Match    expected_posting=${emp}    registered_postings=${registered_postings}
        Should Be True  $is_match
    END

Delete "Additional Postings"
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
    # to be used in later
    Set Suite Variable      @{PRE_SET_POSTINGS}     @{REGISTERED_POSTINGS}

Test Creating "Additional Postings"
    [Tags]              CRUD-operations-as-admin
    Create "Additional Postings"  # test
    Read "Registered Postings"
    Verify "Registered Postings" Against Posting Spec
    Verify "Additional Postings" Created

    # to be used by the next test case
    Set Suite Variable      @{POSTINGS_TO_MODIFY}       @{POSTINGS_TO_CREATE}  # to be semantically correct

Test Modifying The Contents Of "Additional Postings"
    [Tags]                  CRUD-operations-as-admin
    Modify The Contents Of "Additional Postings"  # test

    Read "Registered Postings"
    Verify "Registered Postings" Against Posting Spec
    Verify "Additional Postings" Modified

    # to be used by the next test case
    Set Suite Variable      @{POSTINGS_TO_DELETE}       @{EXPECTED_MODIFIED_POSTINGS}  # to be semantically correct in the next test

Deleting "Additional Postings"
    [Tags]                  CRUD-operations-as-admin
    Delete "Additional Postings"    # test
    Read "Registered Postings"
    Verify "Registered Postings" Against Posting Spec
    Verify Only "Pre-Set Postings" Left










