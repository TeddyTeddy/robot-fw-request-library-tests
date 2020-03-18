from urllib.parse import urlparse
from robot.api.deco import keyword
import re
import CommonVariables
from LibraryLoader import LibraryLoader

@keyword
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

@keyword
def verify_all_postings(postings_to_verify, posting_spec):
    """
    :param postings_to_verify: a list of postings, where each posting needs to be verified against posting_spec
    :param posting_spec: a dict containing keys, which map to posting fields
    :return: None
    """
    for p in postings_to_verify:
        verify_fields(p, posting_spec)


def is_match(expected_posting, postings_set):
    is_match_found = False
    matched_posting = None
    for rp in postings_set:
        is_match_found = rp['title'] == expected_posting['title'] and rp['content'] == expected_posting['content']
        if is_match_found:
            matched_posting = rp
            break
    return is_match_found, matched_posting


@keyword
def is_subset(subset, superset):
    for posting in subset:
        is_match_found, matched_posting = is_match(expected_posting=posting, postings_set=superset)
        assert is_match_found


@keyword
def update_target_postings():
    loader = LibraryLoader.get_instance()  # singleton
    target_postings = loader.builtin.get_variable_value("${TARGET_POSTINGS}")
    registered_postings = loader.builtin.get_variable_value("${REGISTERED_POSTINGS}")
    expected_modified_postings = []
    for ptm in target_postings:
        is_match_found, matched_posting = is_match(expected_posting=ptm, postings_set=registered_postings)
        assert is_match_found
        matched_posting['content'] = 'modified content'
        # test call:
        loader.builtin.run_keyword('Make Put Request',  matched_posting) # TODO: Cannot receive put response
        expected_modified_postings.append(matched_posting)
    loader.builtin.set_test_variable('${EXPECTED_MODIFIED_POSTINGS}', expected_modified_postings)