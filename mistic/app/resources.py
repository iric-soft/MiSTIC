import data
from pyramid.security import Everyone, Authenticated
from pyramid.security import Allow, Deny
from pyramid.security import DENY_ALL

class Root(object):
    __acl__ = [ (Allow, Authenticated, 'view'), DENY_ALL ]

    def __init__(self, request):
        self.request = request
