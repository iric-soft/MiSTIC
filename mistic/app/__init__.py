from pyramid.config import Configurator
from mistic.app.resources import Root
import collections
import data
import exceptions
import ConfigParser
import json

import binascii

from zope.interface import implements

from paste.httpheaders import AUTHORIZATION
from paste.httpheaders import WWW_AUTHENTICATE
from pyramid.httpexceptions import *

from pyramid.interfaces import IAuthenticationPolicy
from pyramid.security import forget
from pyramid.security import Everyone
from pyramid.security import Authenticated
from pyramid.security import NO_PERMISSION_REQUIRED
from pyramid.authorization import ACLAuthorizationPolicy
from pyramid.security import authenticated_userid
from pyramid_beaker import set_cache_regions_from_settings
from pyramid.session import UnencryptedCookieSessionFactoryConfig

from sqlalchemy import engine_from_config

import mistic.app.views.pdffile
import mistic.app.tables

def _get_basicauth_credentials(request):
    authorization = AUTHORIZATION(request.environ)
    try:
        authmeth, auth = authorization.split(' ', 1)
    except ValueError: # not enough values to unpack
        return None
    if authmeth.lower() == 'basic':
        try:
            auth = auth.strip().decode('base64')
        except binascii.Error: # can't decode
            return None
        try:
            login, password = auth.split(':', 1)
        except ValueError: # not enough values to unpack
            return None
        return {'login':login, 'password':password}

    return None

class BasicAuthenticationPolicy(object):
    """ A :app:`Pyramid` :term:`authentication policy` which
    obtains data from basic authentication headers.

    Constructor Arguments

    ``check``

        A callback passed the credentials and the request,
        expected to return None if the userid doesn't exist or a sequence
        of group identifiers (possibly empty) if the user does exist.
        Required.

    ``realm``

        Default: ``Realm``.  The Basic Auth realm string.

    """
   
    def __init__(self, check, realm='Realm'):
        self.check = check
        self.realm = realm

    def authenticated_userid(self, request):
        credentials = _get_basicauth_credentials(request)
        if credentials is None:
            return None
        userid = credentials['login']
        if self.check(credentials, request) is not None: # is not None!
            return userid

    def effective_principals(self, request):
        effective_principals = [Everyone]
        credentials = _get_basicauth_credentials(request)
        if credentials is None:
            return effective_principals
        userid = credentials['login']
        groups = self.check(credentials, request)
        if groups is None: # is None!
            return effective_principals
        effective_principals.append(Authenticated)
        effective_principals.append(userid)
        effective_principals.extend(groups)
        return effective_principals

    def unauthenticated_userid(self, request):
        creds = _get_basicauth_credentials(request)
        if creds is not None:
            return creds['login']
        return None

    def remember(self, request, principal, **kw):
        return []

    def forget(self, request):
        head = WWW_AUTHENTICATE.tuples('Basic realm="%s"' % self.realm)
        return head



def http_basic_authenticator(auth):

    auths = dict([tuple([x  for x  in a.split(':')]) for a in auth.split(' ')])
    isSHA = all(['{SHA}' in x for x in auths.values()])
    if isSHA:
        import base64
        import sha

        def http_basic_auth(credentials, request):
            if (credentials['login'] in auths.keys() and
                base64.standard_b64encode(sha.sha(credentials['password']).digest()) ==  auths[credentials['login']][5:]):
                return []
            return None

        return http_basic_auth
    else:
        raise exceptions.RuntimeError('only SHA authentication hashes are supported')


def load_datasets_settings (configurationFile, global_config):

    defaultByKey = {'here' : global_config['here']}
    configParser = ConfigParser.ConfigParser(defaultByKey)

    if not configParser.read(configurationFile):
        raise ConfigParser.Error('Could not open %s' % configurationFile)
    datasets_settings = {}
    for key, value in configParser.items('datasets:mistic'):
      datasets_settings[key] = value

    return datasets_settings


def main(global_config, **settings):
    """ This function returns a Pyramid WSGI application.
    """
    print 'settings', settings
    set_cache_regions_from_settings(settings)

    engine = engine_from_config(settings, 'sqlalchemy.')
    mistic.app.tables.create(engine)
    mistic.app.tables.Base.metadata.create_all(engine)

    if 'mistic.datasets' in settings:
      settings.update(load_datasets_settings (settings['mistic.datasets'], global_config))

    config_args = dict(root_factory=Root,settings=settings,default_permission='view')

    
    
    
    if 'mistic.basic.auth' in settings:
      
        if '=' not in settings['mistic.basic.auth'] : 
            authorized_credentials = open(settings['mistic.basic.auth'], 'r').readlines()
            authorized_credentials = ' '.join([a.strip() for a in authorized_credentials])
            
            authorized_credentials = authorized_credentials.strip()
        else : 
            authorized_credentials = settings['mistic.basic.auth']
       
        config_args.update(dict(
                authentication_policy=BasicAuthenticationPolicy(
                    http_basic_authenticator(authorized_credentials),
                    realm=settings.get('mistic.basic.realm', 'mistic')),
                authorization_policy=ACLAuthorizationPolicy() ))

    my_session_factory = UnencryptedCookieSessionFactoryConfig('myouwnsekreetfactory')
    config_args.update(dict(session_factory= my_session_factory))

    config = Configurator(**config_args)

    def authorize(request):
        return HTTPUnauthorized(headers = forget(request)) ## Response(body='hello world!', content_type='text/plain')
    config.add_view(authorize, context=HTTPForbidden, permission=NO_PERMISSION_REQUIRED)

    if 'mistic.data' not in settings:
        raise exceptions.RuntimeError('no dataset configuration supplied')

    data.load(settings['mistic.data'])

    if 'mistic.rsvg-convert' in settings:
        mistic.app.views.pdffile.PDFData.rsvg_convert = settings['mistic.rsvg-convert']
    if 'mistic.phantomjs' in settings:
        mistic.app.views.pdffile.PDFData.phantomjs = settings['mistic.phantomjs']

    config.add_route('mistic.template.root',               '/')

    config.add_route('mistic.modal.datasets',              '/modal/datasets')
    # params: go=GO_ID - filter the list of returned genes by GO term.
    config.add_route('mistic.json.annotation.genes',       '/annotations/{annotation}/genes')
    config.add_route('mistic.json.annotation.gene_ids',    '/annotations/{annotation}/gene_ids')
    config.add_route('mistic.json.annotation.gene',        '/annotations/{annotation}/genes/{gene_id}')
    config.add_route('mistic.json.annotation.gene.gs',     '/annotations/{annotation}/genes/{gene_id}/gs*gsid')
    config.add_route('mistic.json.annotation.gene.name',   '/annotations/{annotation}/genes/{gene_id}/name')
    config.add_route('mistic.json.annotation.gene.symbol', '/annotations/{annotation}/genes/{gene_id}/symbol')

    config.add_route('mistic.json.annotation.gs',          '/annotations/{annotation}/gs')

    config.add_route('mistic.json.cannotation.items',      '/cannotations/datasets/{dataset}')

    config.add_route('mistic.json.datasets',               '/datasets')
    config.add_route('mistic.json.dataset',                '/datasets/{dataset}')
    config.add_route('mistic.json.dataset.search',         '/datasets/{dataset}/search')

    config.add_route('mistic.json.dataset.sampleinfo',     '/datasets/{dataset}/sampleinfo')
    config.add_route('mistic.json.dataset.samples',        '/datasets/{dataset}/samples')
    config.add_route('mistic.json.dataset.samples.enrich', '/datasets/{dataset}/samples/enrichment')
    config.add_route('mistic.json.dataset.geneset.enrich', '/datasets/{dataset}/geneset/enrichment')
    config.add_route('mistic.json.sample',                 '/datasets/{dataset}/samples/{sample_id}')

    config.add_route('mistic.json.dataset.sampleinfo.search',     '/datasets/{dataset}/sampleinfo/search')

    config.add_route('mistic.json.dataset.mst',            '/datasets/{dataset}/mst/{xform}')
    config.add_route('mistic.json.dataset.mapped_mst',     '/datasets/{dataset}/mst/{xform}/{tgt_annotation}')

    config.add_route('mistic.json.dataset.genes',          '/datasets/{dataset}/genes')
    config.add_route('mistic.json.gene',                   '/datasets/{dataset}/genes/{gene_id}')
    config.add_route('mistic.json.gene.corr',              '/datasets/{dataset}/genes/{gene_id}/corr')
    config.add_route('mistic.json.gene.expr',              '/datasets/{dataset}/genes/{gene_id}/expr')
    config.add_route('mistic.json.gene.utest',             '/datasets/{dataset}/genes/{gene_id}/utest')
    config.add_route('mistic.json.gene.gorilla',           '/datasets/{dataset}/genes/{gene_id}/gorilla')

    config.add_route('mistic.json.go',                     '/go')
    config.add_route('mistic.json.go.search',              '/go/search')
    config.add_route('mistic.json.go.id',                  '/go/{go_id}')
    config.add_route('mistic.json.go.name',                '/go/{go_id}/name')

    config.add_route('mistic.json.attr.set',               '/attr')
    config.add_route('mistic.json.attr.get',               '/attr/{id}')
    
    config.add_route('mistic.json.saveValueInSession',     '/saveInSession')

    config.add_route('mistic.template.corrgraph',          '/genecorr')
    config.add_route('mistic.template.scatterplot',        '/scatterplot') 
    config.add_route('mistic.template.pairplot',           '/pairplot/{dataset}*genes')

    config.add_route('mistic.csv.root',                    '/csv/root')
    config.add_route('mistic.pdf.fromsvg',                 '/pdf')
    config.add_route('mistic.csv.corr',                    '/csv/genecorr/{dataset}/{gene}')
    config.add_route('mistic.csv.corrds',                  '/csv/genecorr/{dataset}/{gene}/all')

    config.add_route('mistic.template.clustering',         '/clustering/{dataset}/{xform}')
    config.add_route('mistic.template.mstplot',            '/mstplot/{dataset}/{xform}')
   

    config.add_static_view('static', 'mistic:app/static', cache_max_age=3600)
    config.add_static_view('images', 'mistic:resources/images', cache_max_age=3600)


    config.scan()

    return config.make_wsgi_app()
