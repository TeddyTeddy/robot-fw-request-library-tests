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

Verify OPTIONS Response (Admin)
    [Arguments]   ${options_response}
    Should Be Equal As Integers 	${options_response.status_code} 	200
    # make sure that expected & observed response headers match
    Should Be True     $options_response.headers['Allow']==$OPTIONS_RESPONSE_HEADERS['Allow']
    Should Be True     $options_response.headers['Vary']==$OPTIONS_RESPONSE_HEADERS['Vary']
    Should Be True     $options_response.headers['Content-Type']==$OPTIONS_RESPONSE_HEADERS['Content-Type']
    # make sure that API spec matches
    Should Be True     $options_response.json()==${ADMIN}[EXPECTED_API_SPEC]

Do Verify Posting Fields
    [Documentation]     For each field in @{POSTING_SPEC}, check the following:
    ...                 The field must exist in the posting, if not fail
    ...                 If the field is url field, then value it has must be a valid url, if not fail
    [Arguments]  ${posting}
    FOR   ${field}   IN   @{POSTING_SPEC}
        Should Be True      $field in $posting
        Run keyword If      $field=='url'    validate url   url=${posting}[url]  # fails if not valid url
    END

Verify "Registered Postings" Against Posting Spec
    FOR  ${p}     IN  @{REGISTERED_POSTINGS}
        Do Verify Posting Fields    posting=${p}
    END

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

Make PUT Request (Admin)
    [Arguments]        ${posting}
    ${PUT_RESPONSE} =   Make Put Request  posting=${posting}
    Should Be Equal As Integers 	${PUT_RESPONSE.status_code} 	200  # OK

Make DELETE Request (Admin)
    [Arguments]     ${posting}
    Set To Dictionary    dictionary=${ADMIN}[DELETE_REQUEST_HEADERS]       Referer=${posting}[url]
    ${delete_request_uri}=     Get Uri  url=${posting}[url]
    ${response} =     Delete Request      alias=${ADMIN_SESSION}    uri=${delete_request_uri}   headers=${ADMIN}[DELETE_REQUEST_HEADERS]  data=None
    Should Be Equal As Integers 	${response.status_code} 	200  # OK

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
        Make PUT Request (Admin)    posting=${registered_posting}              # test call: supposed to update the system
        Append To List      ${expected_modified_postings}       ${registered_posting}
    END
    Set Test Variable  @{EXPECTED_MODIFIED_POSTINGS}    @{expected_modified_postings}

Verify "Additional Postings" Modified
    FOR     ${emp}    IN  @{EXPECTED_MODIFIED_POSTINGS}  # emp: expected_modified_posting
        ${is_match}   ${matched_posting} =    Is Match    expected_posting=${emp}    registered_postings=${registered_postings}
        Should Be True  $is_match
    END

*** Test Cases ***
Check BlogPostAPI specification
    [Tags]              smoke-as-admin
    Query BlogPostAPI Specification
    Verify BlogPostAPI Specification
    Set "Posting Spec"  # for later use in upcoming test cases

Query & Verify Pre-Set Postings (Admin)
    [Documentation]     In the previous test case, we verified the BlogPostAPI's specification.
    ...                 In this test case, we query the API for existing postings in the system.
    ...                 If there are pre-existing postings in the system, we check if each posting's fields
    ...                 are matching against the POSTING_SPEC. That is, each pre-set posting has all the fields
    ...                 specified in POSTING_SPEC. If not, the test fails. If success, then we store the
    ...                 pre-set postings into @{PRE_SET_POSTINGS} suite variable for later use
    [Tags]              smoke-as-admin
    Read "Registered Postings"
    Verify "Registered Postings" Against Posting Spec
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
    Modify The Contents of "Additional Postings"  # test

    Read "Registered Postings"
    Verify "Registered Postings" Against Posting Spec
    Verify "Additional Postings" Modified

    # to be used by the next test case
    Set Suite Variable      @{POSTINGS_TO_DELETE}       @{EXPECTED_MODIFIED_POSTINGS}  # to be semantically correct in the next test

Make DELETE Requests (Admin) : Deleting Previously Updated Postings
    [Documentation]     In the previous test case, we updated specific posting(s) (i.e. @{expected_modified_postings})
    ...                 in the system. These postings have been passed as @{POSTINGS_TO_DELETE} to this test case.
    ...
    ...                 For each posting to delete (aka. ptd in short) in @{POSTINGS_TO_DELETE},
    ...                 We make a DELETE Request for that very ptd. Once all DELETE request(s) are done,
    ...                 a GET request is made into @{registered_postings}. Then verification begins.
    ...
    ...                 Verification phase one: all the remaining entries in the system are summed up to @{PRE_SET_POSTINGS}.
    ...                 (i.e. @{registered_postings} == @{PRE_SET_POSTINGS})
    ...
    ...                 Verification phase two: all the remaining entries in the system are according to ${POSTING_SPEC}
    ...
    ...                 Verification phase three: none of the postings in @{POSTINGS_TO_DELETE} can be found
    ...                 in @{registered_postings}

    [Tags]                  CRUD-operations-as-admin
    # test
    # in the previous test case, we set @{POSTINGS_TO_DELETE}
    # now, we are going to delete the postings in @{POSTINGS_TO_DELETE}
    FOR     ${ptd}    IN  @{POSTINGS_TO_DELETE}  # ptd: posting_to_delete
        Make DELETE Request (Admin)    posting=${ptd}
    END

    # verify that postings in @{POSTINGS_TO_DELETE} indeed got deleted
    Read "Registered Postings"

    # Verification phase one
    Should Be True  $REGISTERED_POSTINGS == $PRE_SET_POSTINGS
    # verification phase two
    Verify "Registered Postings" Against Posting Spec
    # @{registered_postings} = [
    #    {'url': 'https://glacial-earth-31542.herokuapp.com/api/postings/2/', 'id': 2, 'user': 1, 'title': 'My Second Posting', 'content': "My Second Blog's content", 'timestamp': '2019-12-18T17:07:34.938150+02:00'},
    #    {'url': 'https://glacial-earth-31542.herokuapp.com/api/postings/1/', 'id': 1, 'user': 1, 'title': 'My First Posting', 'content': "My First Blog's content", 'timestamp': '2019-12-18T17:06:54.373451+02:00'},
    # ]
    # verification phase three
    FOR     ${ptd}    IN  @{POSTINGS_TO_DELETE}  # ptd: posting_to_delete
        ${is_match}   ${matched_posting} =    Is Match    expected_posting=${ptd}    registered_postings=${registered_postings}
        Should Not Be True  $is_match
    END










