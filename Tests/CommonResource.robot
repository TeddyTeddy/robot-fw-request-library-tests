*** Settings ***

*** Variables ***
${REGISTERED_POSTINGS}      A list of postings read from the API, set dynamically
${POST_RESPONSE}            A response object to POST request, set dynamically
${OPTIONS_RESPONSE}         A response object to OPTIONS request, set dynamically
${POSTING_SPEC}             A dictionary object, where items are posting fields. Set dynamically
${DELETE_RESPONSE}          A response object to DELETE request, set dynamically
${PRE_SET_POSTINGS}         A list of pre-existing postings in the system before tests with the tag 'CRUD-operations-as-admin' run
${RANDOM_TARGET_POSTING}    A dynamically picked target posting during test run. Set to None at the beginning & end of every test

*** Keywords ***