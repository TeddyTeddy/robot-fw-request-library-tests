*** Settings ***
Documentation    This test suite uses robotframework-request library to test BlogPostAPI
...              Note that the API supports only: 'GET, POST, HEAD, OPTIONS' methods on URL:
...              https://glacial-earth-31542.herokuapp.com/api/postings/
...              If you want to update/delete a posting, then you need to use its url. For example:
...              https://glacial-earth-31542.herokuapp.com/api/postings/26/
Resource         ../Libraries/Src/CommonLibraryImport.robot
Library 	     RequestsLibrary
Library          Collections

Suite Setup      Suite Setup
Suite Teardown   Suite Teardown

# To Run
# python -m robot  --pythonpath Libraries/Src --noncritical failure-expected -d Results/ Tests/BlogPostApiTests.robot

*** Keywords ***
Suite Setup
    Create Session  alias=${SESSION_ALIAS}   url=${API_BASE_URL}  cookies={}    verify=${True}

Suite Teardown
    Delete All Sessions

Verify Options Response
    [Arguments]   ${options_response}
    Should Be Equal As Integers 	${options_response.status_code} 	200
    # make sure that expected & observed response headers match
    Should Be True     $options_response.headers['Allow']==$OPTIONS_RESPONSE_HEADERS['Allow']
    Should Be True     $options_response.headers['Vary']==$OPTIONS_RESPONSE_HEADERS['Vary']
    Should Be True     $options_response.headers['Content-Type']==$OPTIONS_RESPONSE_HEADERS['Content-Type']
    # make sure that API spec matches
    Should Be True     $options_response.json()==$EXPECTED_API_SPEC

Do Verify Posting Fields
    [Arguments]  ${posting}
    FOR   ${field}   IN   @{POSTING_SPEC}
        Should Be True      $field in $posting
        Run keyword If      $field=='url'    validate url   url=${posting}[url]  # fails if not valid url
    END

Verify Postings Against Posting Spec
    [Arguments]     ${postings}
    FOR  ${p}     IN  @{postings}
        Do Verify Posting Fields    posting=${p}
    END

Make POST Request
    [Arguments]       ${posting}
    ${response} =     Post Request      alias=${SESSION_ALIAS}    uri=${POSTINGS_URI}    headers=${POST_REQUEST_HEADERS}  data=${posting}
    Should Be Equal As Integers 	${response.status_code} 	201  # Created

Make PUT Request
    [Arguments]        ${posting}
    Set To Dictionary    dictionary=${PUT_REQUEST_HEADERS}       Referer=${posting}[url]
    ${put_request_uri}=     Get Uri  url=${posting}[url]
    ${response} =     Put Request      alias=${SESSION_ALIAS}    uri=${put_request_uri}    headers=${PUT_REQUEST_HEADERS}  data=${posting}
    Should Be Equal As Integers 	${response.status_code} 	200  # OK

Make DELETE Request
    [Arguments]     ${posting}
    Set To Dictionary    dictionary=${DELETE_REQUEST_HEADERS}       Referer=${posting}[url]
    ${delete_request_uri}=     Get Uri  url=${posting}[url]
    ${response} =     Delete Request      alias=${SESSION_ALIAS}    uri=${delete_request_uri}   headers=${DELETE_REQUEST_HEADERS}  data=None
    Should Be Equal As Integers 	${response.status_code} 	200  # OK

Get Postings
    ${response} =   Get Request     alias=${SESSION_ALIAS}    uri=${POSTINGS_URI}    headers=${GET_REQUEST_HEADERS}
    Should Be Equal As Integers 	${response.status_code} 	200
    # @{postings} =   Create List     @{response.json()}
    [Return]        ${response.json()}

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
        ${matched_posting} =    Set Variable If   $is_match==True       ${rp}       ${None}
        Exit For Loop If    $is_match==True
    END
    [Return]    ${is_match}     ${matched_posting}


*** Test Cases ***
Check BlogPostAPI specification
    [Documentation]     Make an OPTIONS Request to BlogPostAPI:
    ...                 https://glacial-earth-31542.herokuapp.com/api/postings/
    ...
    ...                 Ensure that the following response headers are correct:
    ...                 Allow, Vary, Content-Type
    ...
    ...                 Ensure that the response's JSON payload matches EXPECTED_API_SPEC
    ...                 Set the content fields of POSTING as a suite variable POSTING_SPEC
    [Tags]  smoke
    ${options_response} =   Options Request     alias=${SESSION_ALIAS}   uri=${POSTINGS_URI}    headers=${OPTIONS_REQUEST_HEADERS}
    Verify Options Response     options_response=${options_response}

    # if execution reaches here, that means the api spec has not changed
    # Set the content fields of POSTING (i.e. ${options_response.json()}[actions][POST]) as a suite variable POSTING_SPEC
    Set Suite Variable  ${POSTING_SPEC}      ${options_response.json()}[actions][POST]

Query & Verify Pre-Set Postings
    @{pre-set-postings} =   Get Postings
    Verify Postings Against Posting Spec    postings=${pre-set-postings}

    # if execution reaches here, all pre-set-postings are valid againist the API's POSTING_SPEC
    Set Suite Variable      @{PRE-SET-POSTINGS}     @{pre-set-postings}

Make POST Requests: Create New Postings: "Posting 1", "Posting 2" and "Posting 3"
    # test
    FOR     ${p}    IN  @{POSTINGS_TO_CREATE}
        Make POST Request     posting=${p}
    END

    # verify that postings in @{POSTINGS_TO_CREATE} indeed got created
    @{registered_postings} =   Get Postings
    # @{registered_postings} = [
    #    {'url': 'https://glacial-earth-31542.herokuapp.com/api/postings/2/', 'id': 2, 'user': 1, 'title': 'My Second Posting', 'content': "My Second Blog's content", 'timestamp': '2019-12-18T17:07:34.938150+02:00'},
    #    {'url': 'https://glacial-earth-31542.herokuapp.com/api/postings/1/', 'id': 1, 'user': 1, 'title': 'My First Posting', 'content': "My First Blog's content", 'timestamp': '2019-12-18T17:06:54.373451+02:00'},
    #    {'url': 'https://glacial-earth-31542.herokuapp.com/api/postings/11/', 'id': 11, 'user': 1, 'title': 'Posting 1', 'content': 'Posting 1 content', 'timestamp': '2020-03-11T14:48:37.229023+02:00'},
    #    {'url': 'https://glacial-earth-31542.herokuapp.com/api/postings/12/', 'id': 12, 'user': 1, 'title': 'Posting 2', 'content': 'Posting 2 content', 'timestamp': '2020-03-11T14:48:37.462976+02:00'},
    #    {'url': 'https://glacial-earth-31542.herokuapp.com/api/postings/13/', 'id': 13, 'user': 1, 'title': 'Posting 3', 'content': 'Posting 3 content', 'timestamp': '2020-03-11T14:48:37.724016+02:00'}
    # ]
    Verify Postings Against Posting Spec    postings=${registered_postings}
    FOR     ${expected_posting}    IN  @{POSTINGS_TO_CREATE}
        ${is_match}   ${matched_posting} =    Is Match    expected_posting=${expected_posting}    registered_postings=${registered_postings}
        Should Be True  $is_match
    END

    # to be used by the next test case
    Set Suite Variable      @{REGISTERED_POSTINGS}      @{registered_postings}
    Set Suite Variable      @{POSTINGS_TO_MODIFY}       @{POSTINGS_TO_CREATE}  # to be semantically correct in the next test

Make PUT Requests : Modify The Content Of "Posting 1", "Posting 2" and "Posting 3"
    # test
    # in the previous test case, we have created the postings in @{POSTINGS_TO_CREATE}
    # now, we are going to modify the postings in @{POSTINGS_TO_CREATE}
    @{expected_modified_postings} =     Create List
    FOR     ${ptm}    IN  @{POSTINGS_TO_MODIFY}  # ptm: posting_to_modify
        ${is_match}   ${matched_posting} =  Is Match    expected_posting=${ptm}    registered_postings=${REGISTERED_POSTINGS}
        Set To Dictionary       dictionary=${matched_posting}       content=modified content   #  << modifying the content
        Make PUT Request    posting=${matched_posting}
        Append To List      ${expected_modified_postings}       ${matched_posting}
    END

    # verify that postings in @{POSTINGS_TO_MODIFY} indeed got modified
    @{registered_postings} =   Get Postings  # i.e.
    Verify Postings Against Posting Spec    postings=${registered_postings}
    # @{registered_postings} = [
    #    {'url': 'https://glacial-earth-31542.herokuapp.com/api/postings/2/', 'id': 2, 'user': 1, 'title': 'My Second Posting', 'content': "My Second Blog's content", 'timestamp': '2019-12-18T17:07:34.938150+02:00'},
    #    {'url': 'https://glacial-earth-31542.herokuapp.com/api/postings/1/', 'id': 1, 'user': 1, 'title': 'My First Posting', 'content': "My First Blog's content", 'timestamp': '2019-12-18T17:06:54.373451+02:00'},
    #    {'url': 'https://glacial-earth-31542.herokuapp.com/api/postings/11/', 'id': 11, 'user': 1, 'title': 'Posting 1', 'content': 'modified content', 'timestamp': '2020-03-11T14:48:37.229023+02:00'},
    #    {'url': 'https://glacial-earth-31542.herokuapp.com/api/postings/12/', 'id': 12, 'user': 1, 'title': 'Posting 2', 'content': 'modified content', 'timestamp': '2020-03-11T14:48:37.462976+02:00'},
    #    {'url': 'https://glacial-earth-31542.herokuapp.com/api/postings/13/', 'id': 13, 'user': 1, 'title': 'Posting 3', 'content': 'modified content', 'timestamp': '2020-03-11T14:48:37.724016+02:00'}
    # ]
    FOR     ${emp}    IN  @{expected_modified_postings}  # emp: expected_modified_posting
        ${is_match}   ${matched_posting} =    Is Match    expected_posting=${emp}    registered_postings=${registered_postings}
        Should Be True  $is_match
    END

    # to be used by the next test case
    Set Suite Variable      @{POSTINGS_TO_DELETE}       @{expected_modified_postings}  # to be semantically correct in the next test

Make DELETE Requests : Deleting "Posting 1", "Posting 2" and "Posting 3"
    # test
    # in the previous test case, we have formed @{POSTINGS_TO_DELETE}
    # now, we are going to delete the postings in @{POSTINGS_TO_DELETE}
    FOR     ${ptd}    IN  @{POSTINGS_TO_DELETE}  # ptd: posting_to_delete
        Make DELETE Request    posting=${ptd}
    END

    # verify that postings in @{POSTINGS_TO_DELETE} indeed got deleted
    @{registered_postings} =   Get Postings  # i.e.
    Verify Postings Against Posting Spec    postings=${registered_postings}
    # @{registered_postings} = [
    #    {'url': 'https://glacial-earth-31542.herokuapp.com/api/postings/2/', 'id': 2, 'user': 1, 'title': 'My Second Posting', 'content': "My Second Blog's content", 'timestamp': '2019-12-18T17:07:34.938150+02:00'},
    #    {'url': 'https://glacial-earth-31542.herokuapp.com/api/postings/1/', 'id': 1, 'user': 1, 'title': 'My First Posting', 'content': "My First Blog's content", 'timestamp': '2019-12-18T17:06:54.373451+02:00'},
    #    {'url': 'https://glacial-earth-31542.herokuapp.com/api/postings/11/', 'id': 11, 'user': 1, 'title': 'Posting 1', 'content': 'modified content', 'timestamp': '2020-03-11T14:48:37.229023+02:00'},
    #    {'url': 'https://glacial-earth-31542.herokuapp.com/api/postings/12/', 'id': 12, 'user': 1, 'title': 'Posting 2', 'content': 'modified content', 'timestamp': '2020-03-11T14:48:37.462976+02:00'},
    #    {'url': 'https://glacial-earth-31542.herokuapp.com/api/postings/13/', 'id': 13, 'user': 1, 'title': 'Posting 3', 'content': 'modified content', 'timestamp': '2020-03-11T14:48:37.724016+02:00'}
    # ]
    FOR     ${ptd}    IN  @{POSTINGS_TO_DELETE}  # ptd: posting_to_delete
        ${is_match}   ${matched_posting} =    Is Match    expected_posting=${ptd}    registered_postings=${registered_postings}
        Should Not Be True  $is_match
    END










