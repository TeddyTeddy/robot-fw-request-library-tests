from robot.libraries.BuiltIn import BuiltIn


class LibraryLoader:
    """
    https://www.tutorialspoint.com/python_design_patterns/python_design_patterns_singleton.htm
    """
    __instance = None

    def __init__(self):
        if LibraryLoader.__instance is not None:
            raise Exception('LibraryLoader class is a singleton. Use get_instance method instead')
        LibraryLoader.__instance = self
        self.builtin = BuiltIn()
        self._request_library = None  # lazy initialization

    @staticmethod
    def get_instance():
        if LibraryLoader.__instance is None:
            LibraryLoader()
        return LibraryLoader.__instance

    @property
    def rl(self):   # rl stands for 'request library'
        if self._request_library is None:
            try:
                self._request_library = BuiltIn().get_library_instance('RequestsLibrary')
            except RuntimeError:
                self._request_library = None
        return self._request_library


if __name__ == '__main__':
    ll = LibraryLoader.get_instance()
    print(dir(LibraryLoader))




