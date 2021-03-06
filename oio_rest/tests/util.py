#
# Copyright (c) 2017-2018, Magenta ApS
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#


import json
import os
import pprint
import subprocess
import sys
import tempfile
import uuid

import click
import flask_testing
import mock
import testing.postgresql
import psycopg2
import pytest

from oio_rest import app
from oio_rest import db
import settings

TESTS_DIR = os.path.dirname(__file__)
BASE_DIR = os.path.dirname(TESTS_DIR)
TOP_DIR = os.path.dirname(BASE_DIR)
FIXTURE_DIR = os.path.join(TESTS_DIR, 'fixtures')


def get_fixture(fixture_name, mode='rt'):
    """Reads data from fixture folder. If the file name ends with
    ``.json``, we parse it, otherwise, we just return it as text.
    """
    with open(os.path.join(FIXTURE_DIR, fixture_name), mode) as fp:
        if os.path.splitext(fixture_name)[1] == '.json':
            return json.load(fp)
        else:
            return fp.read()


def initdb(psql):
    dsn = psql.dsn()

    env = os.environ.copy()

    env.update(
        TESTING='1',
        PYTHON=sys.executable,
        MOX_DB=settings.DATABASE,
        MOX_DB_USER=settings.DB_USER,
        MOX_DB_PASSWORD=settings.DB_PASSWORD,
    )

    with psycopg2.connect(**dsn) as conn:
        conn.autocommit = True

        with conn.cursor() as curs:
            curs.execute(
                "CREATE USER {} WITH SUPERUSER PASSWORD %s".format(
                    settings.DB_USER,
                ),
                (
                    settings.DB_PASSWORD,
                ),
            )

            curs.execute(
                "CREATE DATABASE {} WITH OWNER = %s".format(settings.DATABASE),
                (
                    settings.DB_USER,
                ),
            )

    dsn = dsn.copy()
    dsn['database'] = settings.DATABASE
    dsn['user'] = settings.DB_USER
    dsn['password'] = settings.DB_PASSWORD

    mkdb_path = os.path.join(BASE_DIR, '..', 'db', 'mkdb.sh')

    with psycopg2.connect(**dsn) as conn, conn.cursor() as curs:
        curs.execute(subprocess.check_output([mkdb_path], env=env))


@pytest.mark.slow
class TestCaseMixin(object):

    '''Base class for LoRA test cases with database access.
    '''

    maxDiff = None

    def create_app(self):
        app.app.config['DEBUG'] = False
        app.app.config['TESTING'] = True
        app.app.config['LIVESERVER_PORT'] = 0
        app.app.config['PRESERVE_CONTEXT_ON_EXCEPTION'] = False

        return app.app

    @classmethod
    def setUpClass(cls):
        super(TestCaseMixin, cls).setUpClass()

        cls.psql_factory = testing.postgresql.PostgresqlFactory(
            cache_initialized_db=True,
            on_initialized=initdb
        )

    @classmethod
    def tearDownClass(cls):
        cls.psql_factory.clear_cache()

        super(TestCaseMixin, cls).tearDownClass()

    def setUp(self):
        super(TestCaseMixin, self).setUp()

        self.psql = self.psql_factory()
        self.psql.wait_booting()

        dsn = self.psql.dsn()

        self.patches = [
            mock.patch('settings.LOG_AMQP_SERVER', None),
            mock.patch('settings.DB_HOST', dsn['host'],
                       create=True),
            mock.patch('settings.DB_PORT', dsn['port'],
                       create=True),
        ]

        for p in self.patches:
            p.start()
            self.addCleanup(p.stop)

        if hasattr(db.adapt, 'connection'):
            del db.adapt.connection

    def tearDown(self):
        super(TestCaseMixin, self).tearDown()

        self.psql.stop()

    def assertRequestResponse(self, path, expected, message=None,
                              status_code=None, drop_keys=(), **kwargs):
        '''Issue a request and assert that it succeeds (and does not
        redirect) and yields the expected output.

        **kwargs is passed directly to the test client -- see the
        documentation for werkzeug.test.EnvironBuilder for details.

        One addition is that we support a 'json' argument that
        automatically posts the given JSON data.

        '''

        r = self.perform_request(path, **kwargs)

        actual = (
            json.loads(r.get_data(as_text=True))
            if r.mimetype == 'application/json'
            else r.get_data(as_text=True)
        )

        for k in drop_keys:
            try:
                actual.pop(k)
            except (IndexError, KeyError, TypeError):
                pass

        if not message:
            status_message = 'request {!r} failed with status {}'.format(
                path, r.status_code,
            )
            content_message = 'request {!r} yielded an expected result'.format(
                path,
            )
        else:
            status_message = content_message = message

        try:
            if status_code is None:
                self.assertLess(r.status_code, 300, status_message)
                self.assertGreaterEqual(r.status_code, 200, status_message)
            else:
                self.assertEqual(r.status_code, status_code, status_message)

            self.assertEqual(expected, actual, content_message)
        except AssertionError:
            print(path)
            print(r.status_code)
            pprint.pprint(actual)

            raise

    def assertRequestFails(self, path, code, message=None, **kwargs):
        '''Issue a request and assert that it succeeds (and does not
        redirect) and yields the expected output.

        **kwargs is passed directly to the test client -- see the
        documentation for werkzeug.test.EnvironBuilder for details.

        One addition is that we support a 'json' argument that
        automatically posts the given JSON data.
        '''
        message = message or "request {!r} didn't fail properly".format(path)

        r = self.perform_request(path, **kwargs)

        self.assertEqual(r.status_code, code, message)

    def perform_request(self, path, **kwargs):
        if 'json' in kwargs:
            kwargs.setdefault('method', 'POST')
            kwargs.setdefault('data', json.dumps(kwargs.pop('json'), indent=2))
            kwargs.setdefault('headers', {'Content-Type': 'application/json'})

        return self.client.open(path, **kwargs)

    def assertRegistrationsEqual(self, expected, actual, message=None):
        def sort_inner_lists(obj):
            """Sort all inner lists and tuples by their JSON string value,
            recursively. This is quite stupid and slow, but works!

            This is purely to help comparison tests, as we don't care about the
            list ordering

            """
            if isinstance(obj, dict):
                return {
                    k: sort_inner_lists(v)
                    for k, v in obj.items()
                }
            elif isinstance(obj, (list, tuple)):
                return sorted(
                    map(sort_inner_lists, obj),
                    key=(lambda p: json.dumps(p, sort_keys=True)),
                )
            else:
                return obj

        # drop lora-generated timestamps & users
        expected.pop('fratidspunkt', None)
        expected.pop('tiltidspunkt', None)
        expected.pop('brugerref', None)

        actual.pop('fratidspunkt', None)
        actual.pop('tiltidspunkt', None)
        actual.pop('brugerref', None)

        # Sort all inner lists and compare
        self.assertEqual(
            sort_inner_lists(expected),
            sort_inner_lists(actual),
            message,
        )

    def assertUUID(self, s):
        try:
            uuid.UUID(s)
        except (TypeError, ValueError):
            self.fail('{!r} is not a uuid!'.format(s))

    def assert201(self, response):
        """
        Verify that the response from LoRa is 201 and contains the correct
        JSON.
        :param response: Response from LoRa when creating a new object
        """
        self.assertEquals(201, response.status_code)
        self.assertEquals(1, len(response.json))
        self.assertUUID(response.json['uuid'])

    def get(self, path, **params):
        r = self.perform_request(path, query_string=params)
        self.assertLess(r.status_code, 300)
        self.assertGreaterEqual(r.status_code, 200)

        d = r.json['results'][0]

        assert len(d) == 1
        registrations = d[0]['registreringer']

        if set(params.keys()) & {'registreretfra', 'registrerettil',
                                 'registreringstid'}:
            return registrations
        else:
            assert len(registrations) == 1
            return registrations[0]

    def put(self, path, json):
        r = self.perform_request(path, json=json, method="PUT")
        self.assertLess(r.status_code, 300)
        self.assertGreaterEqual(r.status_code, 200)

        return r.json['uuid']

    def patch(self, path, json):
        r = self.perform_request(path, json=json, method="PATCH")
        self.assertLess(r.status_code, 300)
        self.assertGreaterEqual(r.status_code, 200)

        return r.json['uuid']

    def post(self, path, json):
        r = self.perform_request(path, json=json, method="POST")
        self.assertLess(r.status_code, 300)
        self.assertGreaterEqual(r.status_code, 200)

        return r.json['uuid']

    def assertQueryResponse(self, path, expected, **params):
        """Perform a request towards LoRa, and assert that it yields the
        expected output.

        Results are unpacked from the LoRa result structure and filtered of
        metadata before comparison

        **params are passed as part of the query string in the request.
        """

        actual = self.get(path, **params)

        print(json.dumps(actual, indent=2))

        return self.assertRegistrationsEqual(expected, actual)

    def load_fixture(self, path, fixture_name, uuid=None):
        """Load a fixture, i.e. a JSON file in the 'fixtures' directory,
        into LoRA at the given path & UUID.
        """
        if uuid:
            method = 'PUT'
            path = '{}/{}'.format(path, uuid)
        else:
            method = 'POST'

        r = self.perform_request(
            path, json=get_fixture(fixture_name), method=method,
        )

        assert r, 'write of {!r} to {!r} failed!'.format(fixture_name, path)

        objid = r.json.get('uuid')

        print(r.get_data(as_text=True), path)
        self.assertTrue(objid)

        return objid


class TestCase(TestCaseMixin, flask_testing.TestCase):
    pass


@click.command()
@click.option('-p', '--port', type=int, default=5000)
def run_with_db(**kwargs):
    with testing.postgresql.Postgresql(
        base_dir=tempfile.mkdtemp(prefix='mox'),
        postgres_args=(
            '-h localhost -F '
            '-c logging_collector=off '
            '-c synchronous_commit=off '
            '-c fsync=off'
        ),
    ) as psql:
        # We take over the process, given that this is a CLI command.
        # Hence, there's no need to restore these variables afterwards
        settings.LOG_AMQP_SERVER = None
        settings.DB_HOST = psql.dsn()['host']
        settings.DB_PORT = psql.dsn()['port']

        initdb(psql)

        app.app.run(**kwargs)


if __name__ == '__main__':
    run_with_db()
