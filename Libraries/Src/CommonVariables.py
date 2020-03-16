def get_variables():
    variables = {
        'ADMIN_SESSION': 'Common Session For All Requests As Admin',
        'API_BASE_URL': 'https://glacial-earth-31542.herokuapp.com',
        'ADMIN': {
            'OPTIONS_REQUEST_HEADERS': {
                'Cookie': 'tabstyle=raw-tab; csrftoken=PEGpUJxFm7n1HZhkWTByL6J1YVg80jZKyrd6vupbApicnJpcFk4l2BPbAOsULVcA; sessionid=qn80bru50vcxk9r06tr9850w7v2de68x',
                'Host': 'glacial-earth-31542.herokuapp.com',
                'Connection': 'keep-alive',
                'Accept': 'application/json',
                # Note: this is different from what browser sends to server. Refer to OPTIONS_RESPONSE_HEADERS['content-type']
                'Origin': 'https://glacial-earth-31542.herokuapp.com',
                'X-Requested-With': 'XMLHttpRequest',
                'Sec-Fetch-Dest': 'empty',
                'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) snap Chromium/80.0.3987.132 Chrome/80.0.3987.132 Safari/537.36',
                'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
                'Sec-Fetch-Site': 'same-origin',
                'Sec-Fetch-Mode': 'cors',
                'Referer': 'https://glacial-earth-31542.herokuapp.com/api/postings/',
                'Accept-Encoding': 'gzip, deflate, br',
                'Accept-Language': 'en-US,en;q=0.9,fi;q=0.8',
            },
            'GET_REQUEST_HEADERS': {
                'Cookie': 'tabstyle=raw-tab; csrftoken=PEGpUJxFm7n1HZhkWTByL6J1YVg80jZKyrd6vupbApicnJpcFk4l2BPbAOsULVcA; sessionid=qn80bru50vcxk9r06tr9850w7v2de68x',
                'Host': 'glacial-earth-31542.herokuapp.com',
                'Connection': 'keep-alive',
                'Cache-Control': 'max-age=0',
                'Upgrade-Insecure-Requests': '1',
                'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) snap Chromium/80.0.3987.132 Chrome/80.0.3987.132 Safari/537.36',
                'Sec-Fetch-Dest': 'document',
                'Accept': 'application/json',  # Note: this is different from what browser sends to server.
                'Sec-Fetch-Site': 'same-origin',
                'Sec-Fetch-Mode': 'navigate',
                'Sec-Fetch-User': '?1',
                'Referer': 'https://glacial-earth-31542.herokuapp.com/api/postings/',
                'Accept-Encoding': 'gzip, deflate, br',
                'Accept-Language': 'en-US,en;q=0.9,fi;q=0.8',
            },
            'POST_REQUEST_HEADERS': {
                'Host': 'glacial-earth-31542.herokuapp.com',
                'Connection': 'keep-alive',
                 # Content-Length: 64
                'Origin': 'https://glacial-earth-31542.herokuapp.com',
                'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) snap Chromium/80.0.3987.132 Chrome/80.0.3987.132 Safari/537.36',
                'Content-Type': 'application/json',
                'Accept': 'text/html; q=1.0, */*',
                'Sec-Fetch-Dest': 'empty',
                'X-Requested-With': 'XMLHttpRequest',
                'X-CSRFTOKEN': '5cLs1tbLS7a3xEEbwKWq8NkcWu585U26OZi9Ce3h6p5edoM3fbpdpiqmynhUQwfW',
                'Sec-Fetch-Site': 'same-origin',
                'Sec-Fetch-Mode': 'cors',
                'Referer': 'https://glacial-earth-31542.herokuapp.com/api/postings/',
                'Accept-Encoding': 'gzip, deflate, br',
                'Accept-Language': 'en-US,en;q=0.9,fi;q=0.8',
                'Cookie': 'tabstyle=raw-tab; csrftoken=PEGpUJxFm7n1HZhkWTByL6J1YVg80jZKyrd6vupbApicnJpcFk4l2BPbAOsULVcA; sessionid=qn80bru50vcxk9r06tr9850w7v2de68x',
            },
            'PUT_REQUEST_HEADERS': {
                'Host': 'glacial-earth-31542.herokuapp.com',
                'Connection': 'keep-alive',
                 # 'Content-Length': '243',
                'Origin': 'https://glacial-earth-31542.herokuapp.com',
                'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) snap Chromium/80.0.3987.132 Chrome/80.0.3987.132 Safari/537.36',
                'Content-Type': 'application/json',
                'Accept': 'text/html; q=1.0, */*',
                'Sec-Fetch-Dest': 'empty',
                'X-Requested-With': 'XMLHttpRequest',
                'X-CSRFTOKEN': '5cLs1tbLS7a3xEEbwKWq8NkcWu585U26OZi9Ce3h6p5edoM3fbpdpiqmynhUQwfW',
                'Sec-Fetch-Site': 'same-origin',
                'Sec-Fetch-Mode': 'cors',
                'Referer': '',  # expects the url of the posting resource here!
                'Accept-Encoding': 'gzip, deflate, br',
                'Accept-Language': 'en-US,en;q=0.9,fi;q=0.8',
                'Cookie': 'tabstyle=raw-tab; csrftoken=PEGpUJxFm7n1HZhkWTByL6J1YVg80jZKyrd6vupbApicnJpcFk4l2BPbAOsULVcA; sessionid=qn80bru50vcxk9r06tr9850w7v2de68x',
            },
            'DELETE_REQUEST_HEADERS': {
                'Host': 'glacial-earth-31542.herokuapp.com',
                'Connection': 'keep-alive',
                'Origin': 'https://glacial-earth-31542.herokuapp.com',
                'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) snap Chromium/80.0.3987.132 Chrome/80.0.3987.132 Safari/537.36',
                'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
                'Accept': 'text/html; q=1.0, */*',
                'Sec-Fetch-Dest': 'empty',
                'X-Requested-With': 'XMLHttpRequest',
                'X-CSRFTOKEN': '5cLs1tbLS7a3xEEbwKWq8NkcWu585U26OZi9Ce3h6p5edoM3fbpdpiqmynhUQwfW',
                'Sec-Fetch-Site': 'same-origin',
                'Sec-Fetch-Mode': 'cors',
                'Referer': '',  # expects the url of the posting resource here!
                'Accept-Encoding': 'gzip, deflate, br',
                'Accept-Language': 'en-US,en;q=0.9,fi;q=0.8',
                'Cookie': 'tabstyle=raw-tab; csrftoken=PEGpUJxFm7n1HZhkWTByL6J1YVg80jZKyrd6vupbApicnJpcFk4l2BPbAOsULVcA; sessionid=qn80bru50vcxk9r06tr9850w7v2de68x',
            },
        },
        'POSTINGS_TO_CREATE': [
            {'title': 'Posting 1', 'content': 'Posting 1 content'},
            {'title': 'Posting 2', 'content': 'Posting 2 content'},
            {'title': 'Posting 3', 'content': 'Posting 3 content'},
        ],
        'POSTINGS_URI': '/api/postings/',
        'OPTIONS_RESPONSE_HEADERS': {
            'Allow': 'GET, POST, HEAD, OPTIONS',
            'Vary': 'Accept, Cookie',
            'Content-Type': 'application/json',
        },
        'EXPECTED_API_SPEC': {
            'name': 'Blog Post Api',
            'description': '',
            'renders': [
                'application/json',
                'text/html'
            ],
            'parses': [
                'application/json',
                'application/x-www-form-urlencoded',
                'multipart/form-data'
            ],
            'actions': {
                'POST': {
                    'url': {
                        'type': 'field',
                        'required': False,
                        'read_only': True,
                        'label': 'Url'
                    },
                    'id': {
                        'type': 'integer',
                        'required': False,
                        'read_only': True,
                        'label': 'ID'
                    },
                    'user': {
                        'type': 'field',
                        'required': False,
                        'read_only': True,
                        'label': 'User'
                    },
                    'title': {
                        'type': 'string',
                        'required': False,
                        'read_only': False,
                        'label': 'Title',
                        'max_length': 120
                    },
                    'content': {
                        'type': 'string',
                        'required': False,
                        'read_only': False,
                        'label': 'Content',
                        'max_length': 120
                    },
                    'timestamp': {
                        'type': 'datetime',
                        'required': False,
                        'read_only': True,
                        'label': 'Timestamp'
                    }
                }
            }
        },

    }
    return variables



