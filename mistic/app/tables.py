# -*- python-indent: 4 -*-
"""
"""

import os
import datetime
import collections
import exceptions
import unicodedata
import re

from sqlalchemy import *

from sqlalchemy import event

from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.ext.declarative import declared_attr

from sqlalchemy.orm import scoped_session
from sqlalchemy.orm import object_session
from sqlalchemy.orm import class_mapper
from sqlalchemy.orm import ColumnProperty
from sqlalchemy.orm import sessionmaker
from sqlalchemy.orm import synonym
from sqlalchemy.orm import relationship
from sqlalchemy.orm import backref

from sqlalchemy.orm.attributes import get_history

from sqlalchemy.util import memoized_property


from zope.sqlalchemy import ZopeTransactionExtension

from hashlib import sha256

import datetime
import time
import uuid

from beaker import cache

import logging
logger = logging.getLogger(__name__)

Base = declarative_base()

class JSONStore(Base):
    __tablename__ = 'm_jsonstore'

    id =  Column(Integer,     Sequence('m_id_seq'), primary_key=True, autoincrement=True)
    key = Column(String(32),                        nullable=False, default=lambda: str(uuid.uuid4()))
    val = Column(Text(),                            nullable=False)

    @property
    def client_id(self):
        return '{0.id}:{0.key}'.format(self)

    @classmethod
    def store(cls, session, _val):
        row = session.query(JSONStore).filter(JSONStore.val == _val).scalar()
        if row is None:
            row = JSONStore(val = _val)
            session.add(row)
            row = session.merge(row)
        return row.client_id

    @classmethod
    def fetch(cls, session, cid):
        _id, _key = cid.split(':',1)
        _id = int(_id)
        row = session.query(JSONStore).filter(and_(JSONStore.id == _id, JSONStore.key == _key)).scalar()
        if row is not None:
            return row.val
        return None

Index('m_jsonstore_i1',  JSONStore.id, JSONStore.key)
Index('m_jsonstore_i2',  JSONStore.val)


DBSession = scoped_session(sessionmaker(extension=ZopeTransactionExtension()))

def create(engine, session = DBSession):
    session.configure(bind = engine)
    Base.metadata.bind = engine



__all__ = [
    'Base',
    'DBSession',
    'create',

    'JSONStore',
]
