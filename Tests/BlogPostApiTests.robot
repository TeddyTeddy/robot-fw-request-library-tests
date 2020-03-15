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
    [Documentation]     For each field in @{POSTING_SPEC}, check the following:
    ...                 The field must exist in the posting, if not fail
    ...                 If the field is url field, then value it has must be a valid url, if not fail
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
        ${matched_posting} =    Set Variable If   $is_match       ${rp}       ${None}
        Exit For Loop If    $is_match
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
    ...                 Set ${options_response.json()}[actions][POST] as suite variable POSTING_SPEC for later use
    [Tags]              smoke
    ${options_response} =   Options Request     alias=${SESSION_ALIAS}   uri=${POSTINGS_URI}    headers=${OPTIONS_REQUEST_HEADERS}
    Verify Options Response     options_response=${options_response}

    # if execution reaches here, that means the api spec has not changed
    # Set the content fields of POSTING (i.e. ${options_response.json()}[actions][POST]) as a suite variable POSTING_SPEC
    Set Suite Variable  ${POSTING_SPEC}      ${options_response.json()}[actions][POST]

Query & Verify Pre-Set Postings
    [Documentation]     In the previous test case, we verified the BlogPostAPI's specification.
    ...                 In this test case, we query the API for existing postings in the system.
    ...                 If there are pre-existing postings in the system, we check if each posting's fields
    ...                 are matching against the POSTING_SPEC. That is, each pre-set posting has all the fields
    ...                 specified in POSTING_SPEC. If not, the test fails. If success, then we store the
    ...                 pre-set postings into @{PRE-SET-POSTINGS} suite variable for later use
    [Tags]              smoke-admin
    @{pre-set-postings} =   Get Postings
    Verify Postings Against Posting Spec    postings=${pre-set-postings}

    # if execution reaches here, all pre-set-postings are valid againist the API's POSTING_SPEC
    Set Suite Variable      @{PRE-SET-POSTINGS}     @{pre-set-postings}

Make POST Requests: Create New Postings
    [Documentation]     Having set @{PRE-SET-POSTINGS} in the previous test case, we now will create
    ...                 new postings as specified in  @{POSTINGS_TO_CREATE}. Test part: For each posting in @{POSTINGS_TO_CREATE}
    ...                 we will make a seperate POST request.
    ...                 Verification part: After executing the POST requests, we will query the API for
    ...                 all the postings into @{registered_postings}.
    ...                 First, We ensure that each posting in @{registered_postings}, have all the required
    ...                 fields in ${POSTING_SPEC}. Once that first verification step is successful, we move into the second
    ...                 step of verification; we check that all the postings in
    ...                 @{POSTINGS_TO_CREATE} have indeed been created in the system; i.e. we compare each posting
    ...                 in @{POSTINGS_TO_CREATE} against @{registered_postings}; there has to be a match of title & content
    [Tags]              CRUD-operations-as-admin
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
    Verify Postings Against Posting Spec    postings=${registered_postings}  # first phase of verification
    # second phase of verification starts here
    FOR     ${expected_posting}    IN  @{POSTINGS_TO_CREATE}
        ${is_match}   ${matched_posting} =    Is Match    expected_posting=${expected_posting}    registered_postings=${registered_postings}
        Should Be True  $is_match
    END

    # to be used by the next test case
    Set Suite Variable      @{REGISTERED_POSTINGS}      @{registered_postings}
    Set Suite Variable      @{POSTINGS_TO_MODIFY}       @{POSTINGS_TO_CREATE}  # to be semantically correct in the next test

Make PUT Requests : Modify The Contents Of Previously Created Postings
    [Documentation]         In the previous test, we stored @{POSTINGS_TO_CREATE} as @{POSTINGS_TO_MODIFY}.
    ...                     (i.e. the newly created postings are stored as @{POSTINGS_TO_MODIFY},
    ...                     where each posting posting to modify (i.e. ptm in short) has only 'title' and 'content'
    ...                     fields (i.e. an incomplete posting entry with missing fields url, id, user, timestamp).
    ...                     ptm(s) cannot be updated into system via PUT request.
    ...                     However, for each ptm, there is a matching complete posting entry in @{REGISTERED_POSTINGS};
    ...                     matching via title & content fields. We use that entry to make a PUT request.
    ...                     Before making the PUT request, we make a deliberate modification to the entry's
    ...                     content field and after that we make a PUT request passing the entry.
    ...                     The entry is stored into @{expected_modified_postings} for verification phase two.
    ...
    ...                     We also know the currently available postings in the system via @{REGISTERED_POSTINGS}
    ...                     (i.e. pre-set-postings + newly created postings).
    ...
    ...                     After having made the PUT request(s) and formed @{expected_modified_postings},
    ...                     we make a GET request to have all the postings stored (& updated) in the system. The json
    ...                     payload of the GET request is stored into @{registered_postings}.

    ...                     Verification part one: we will ensure that each posting in @{registered_postings}
    ...                     is according to the posting spec (i.e. each posting has all the fields in ${POSTING_SPEC})
    ...
    ...                     Verfication phase two: for each expected modified posting (aka. emp in short; an entry
    ...                     in @{expected_modified_postings}), there must be a matching entry in @{registered_postings};
    ...                     matching should be via title & content fields
    [Tags]                  CRUD-operations-as-admin
    # test
    # in the previous test case, we have created the postings in @{POSTINGS_TO_CREATE}
    # now, we are going to modify the postings in @{POSTINGS_TO_CREATE}
    @{expected_modified_postings} =     Create List
    FOR     ${ptm}    IN  @{POSTINGS_TO_MODIFY}  # ptm: posting_to_modify
        ${is_match}   ${registered_posting} =  Is Match    expected_posting=${ptm}    registered_postings=${REGISTERED_POSTINGS}
        Should Be True     $is_match
        Set To Dictionary       dictionary=${registered_posting}       content=modified content   #  << modifying the content
        Make PUT Request    posting=${registered_posting}              # test call: supposed to update the system
        Append To List      ${expected_modified_postings}       ${registered_posting}
    END

    # verify that postings in @{POSTINGS_TO_MODIFY} indeed got modified
    @{registered_postings} =   Get Postings  # i.e.
    Verify Postings Against Posting Spec    postings=${registered_postings}  # Verification part one
    # @{registered_postings} = [
    #    {'url': 'https://glacial-earth-31542.herokuapp.com/api/postings/2/', 'id': 2, 'user': 1, 'title': 'My Second Posting', 'content': "My Second Blog's content", 'timestamp': '2019-12-18T17:07:34.938150+02:00'},
    #    {'url': 'https://glacial-earth-31542.herokuapp.com/api/postings/1/', 'id': 1, 'user': 1, 'title': 'My First Posting', 'content': "My First Blog's content", 'timestamp': '2019-12-18T17:06:54.373451+02:00'},
    #    {'url': 'https://glacial-earth-31542.herokuapp.com/api/postings/11/', 'id': 11, 'user': 1, 'title': 'Posting 1', 'content': 'modified content', 'timestamp': '2020-03-11T14:48:37.229023+02:00'},
    #    {'url': 'https://glacial-earth-31542.herokuapp.com/api/postings/12/', 'id': 12, 'user': 1, 'title': 'Posting 2', 'content': 'modified content', 'timestamp': '2020-03-11T14:48:37.462976+02:00'},
    #    {'url': 'https://glacial-earth-31542.herokuapp.com/api/postings/13/', 'id': 13, 'user': 1, 'title': 'Posting 3', 'content': 'modified content', 'timestamp': '2020-03-11T14:48:37.724016+02:00'}
    # ]
    # Verfication phase two
    FOR     ${emp}    IN  @{expected_modified_postings}  # emp: expected_modified_posting
        ${is_match}   ${matched_posting} =    Is Match    expected_posting=${emp}    registered_postings=${registered_postings}
        Should Be True  $is_match
    END

    # at this point we know that the postings we made PUT requests for have indeed been updated in the system
    # to be used by the next test case
    Set Suite Variable      @{POSTINGS_TO_DELETE}       @{expected_modified_postings}  # to be semantically correct in the next test

Make DELETE Requests : Deleting Previously Updated Postings
    [Documentation]     In the previous test case, we updated specific posting(s) (i.e. @{expected_modified_postings})
    ...                 in the system. These postings have been passed as @{POSTINGS_TO_DELETE} to this test case.
    ...
    ...                 For each posting to delete (aka. ptd in short) in @{POSTINGS_TO_DELETE},
    ...                 We make a DELETE Request for that very ptd. Once all DELETE request(s) are done,
    ...                 a GET request is made into @{registered_postings}. Then verification begins.
    ...
    ...                 Verification phase one: all the remaining entries in the system are summed up to @{PRE-SET-POSTINGS}.
    ...                 (i.e. @{registered_postings} == @{PRE-SET-POSTINGS})
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
        Make DELETE Request    posting=${ptd}
    END

    # verify that postings in @{POSTINGS_TO_DELETE} indeed got deleted
    @{registered_postings} =   Get Postings  # i.e.
    Verify Postings Against Posting Spec    postings=${registered_postings}  # verification phase two
    # @{registered_postings} = [
    #    {'url': 'https://glacial-earth-31542.herokuapp.com/api/postings/2/', 'id': 2, 'user': 1, 'title': 'My Second Posting', 'content': "My Second Blog's content", 'timestamp': '2019-12-18T17:07:34.938150+02:00'},
    #    {'url': 'https://glacial-earth-31542.herokuapp.com/api/postings/1/', 'id': 1, 'user': 1, 'title': 'My First Posting', 'content': "My First Blog's content", 'timestamp': '2019-12-18T17:06:54.373451+02:00'},
    # ]
    FOR     ${ptd}    IN  @{POSTINGS_TO_DELETE}  # ptd: posting_to_delete
        ${is_match}   ${matched_posting} =    Is Match    expected_posting=${ptd}    registered_postings=${registered_postings}
        Should Not Be True  $is_match
    END










