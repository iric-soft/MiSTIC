import os

from setuptools import setup, find_packages

here = os.path.abspath(os.path.dirname(__file__))
README = open(os.path.join(here, 'README.md')).read()
CHANGES = open(os.path.join(here, 'CHANGES.md')).read()

requires = ['pyramid', 'pyramid_debugtoolbar']

setup(name='mistic',
      version='1.0',
      description='mistic',
      long_description=README + '\n\n' +  CHANGES,
      classifiers=[
        "Programming Language :: Python",
        "Framework :: Pylons",
        "Topic :: Internet :: WWW/HTTP",
        "Topic :: Internet :: WWW/HTTP :: WSGI :: Application",
        ],
      author='Tobias Sargeant',
      author_email='sargeant@wehi.edu.au',
      url='',
      keywords='web pyramid pylons',
      packages=find_packages(),
      include_package_data=True,
      zip_safe=False,
      install_requires=requires,
      tests_require=requires,
      test_suite="mistic",
      scripts = [
        'mistic/scripts/mistic'
      ],
      entry_points = """\
      [paste.app_factory]
      main = mistic.app:main

      [paste.paster_command]
      process-datasets = mistic.cmd.process_datasets:Command
      """,
      paster_plugins=['pyramid'],
      )

