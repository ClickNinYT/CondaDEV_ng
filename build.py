import glob
import sys
import os
import platform
from setuptools import setup
from Cython.Distutils import build_ext
from Cython.Distutils.extension import Extension
from Cython.Build import cythonize

from Cython.Compiler import Options
directive_defaults = Options.get_directive_defaults()
Options.docstrings = False
if sys.argv[0].count('profile'):
    directive_defaults['profile'] = True

directive_defaults['cdivision'] = True
directive_defaults['infer_types'] = True
directive_defaults['auto_cpdef'] = True
directive_defaults['wraparound'] = False

ext_modules = []
libraries = []
include_dirs = ['./mmfparser/player']

names = open('names.txt', 'r').read().splitlines()

is_pypy = platform.python_implementation() == 'PyPy'

trans_start = 99#os.environ.get('MMF_TRANS_START', None)
compile_env = {'IS_PYPY': True, 'USE_TRANS': trans_start is not None}
define_macros = []
if trans_start is not None:
    define_macros.append(('TRANS_START', trans_start))

kw = dict(language='c++')

for name in names:
    if name.startswith('#'):
        continue
    ext_modules.append(Extension(name,
                                 ['./' + name.replace('.', '/') + '.pyx'],
                                 define_macros=define_macros,
                                 include_dirs=include_dirs, **kw))
setup(
    name = 'mmfparser extensions',
    ext_modules = cythonize(ext_modules, compile_time_env=compile_env, language_level = "3")
)
