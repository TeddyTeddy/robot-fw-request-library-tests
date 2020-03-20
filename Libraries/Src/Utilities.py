from urllib.parse import urlparse
from robot.api.deco import keyword
import re
import CommonVariables
from LibraryLoader import LibraryLoader


def validate_url(url):
    try:
        result = urlparse(url)
        assert all([result.scheme, result.netloc, result.path])
    except ValueError:
        assert False


def get_uri(url):
    # url is for ex: 'https://glacial-earth-31542.herokuapp.com/api/postings/11/'
    api_base_url = CommonVariables.get_variables()['API_BASE_URL']  # 'https://glacial-earth-31542.herokuapp.com'
    pattern = f'{api_base_url}(.+)'
    match = re.match(pattern, url)
    return match.groups()[0]    # /api/postings/11/


def verify_fields(posting, posting_spec):
    for field in posting_spec:
        assert field in posting
        if field == 'url':
            validate_url(posting['url'])

@keyword
def verify_all_postings(postings_to_verify, posting_spec):
    """
    :param postings_to_verify: a list of postings, where each posting needs to be verified against posting_spec
    :param posting_spec: a dict containing keys, which map to posting fields
    :return: None
    """
    for p in postings_to_verify:
        verify_fields(p, posting_spec)


def is_match(expected_posting, super_set):
    is_match_found = False
    matched_posting = None
    for p in super_set:
        is_match_found = p['title'] == expected_posting['title'] and p['content'] == expected_posting['content']
        if is_match_found:
            matched_posting = p
            break
    return is_match_found, matched_posting


@keyword
def is_subset(subset, superset):
    result = True
    for posting in subset:
        is_match_found, matched_posting = is_match(expected_posting=posting, super_set=superset)
        result = result and is_match_found
        if not result:
            break
    return result

@keyword
def target_postings_are_updated():
    """
    EXPECTED PRECONDITION: When this method is called, REGISTERED_POSTINGS = pre-set postings + target postings.
    Note that REGISTERED_POSTINGS are the the postings that have been read from the API in the previous test case:
    Creating "Target Postings". Note that all the postings in REGISTERED_POSTINGS have all the fields necessary
    (i.e. title , content, url, id, timestamp fields)

    target_postings contain only title & content fields; they do not contain url, id, timestamp fields.
    Therefore target_postings are incomplete postings that can not be used in a PUT request.
    However, for each target_posting (aka. tp), there must be a matched_posting in REGISTERED_POSTINGS.
    With matched_posting, we can make PUT request (i.e. the test call)
    :return: None
    """
    loader = LibraryLoader.get_instance()  # singleton
    incomplete_target_postings = loader.builtin.get_variable_value("${INCOMPLETE_TARGET_POSTINGS}")
    registered_postings = loader.builtin.get_variable_value("${REGISTERED_POSTINGS}")
    for tp in incomplete_target_postings:  # tp: target_posting
        is_match_found, matched_posting = is_match(expected_posting=tp, super_set=registered_postings)
        assert is_match_found
        matched_posting['content'] = 'modified content'
        # test call:
        loader.builtin.run_keyword('Make Put Request',  matched_posting)  # TODO: Cannot receive put response
        tp['content'] = 'modified content'

    loader.builtin.set_test_variable('${INCOMPLETE_TARGET_POSTINGS}', incomplete_target_postings)


@keyword
def get_subset(subset, superset):
    result = []
    for partial_posting in subset:
        is_match_found, matched_posting = is_match(expected_posting=partial_posting, super_set=superset)
        if is_match_found:
            result.append(matched_posting)
    return result


@keyword
def is_none_found(subset,  superset):
    result = True
    for partial_posting in subset:
        is_match_found, matched_posting = is_match(expected_posting=partial_posting, super_set=superset)
        result = result and not is_match_found
        if not result:
            break
    return result

