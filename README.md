MiSTIC
==========
MiSTIC is built on the python framework [Pyramid] (http://www.pylonsproject.org/). 


To install MiSTIC, you'll need :

For the web server application : 
* Python2.7 or later Python2.x 
* Pyramid-1.x (Python2.x compatible)	
* SQLite3
* Python packages :   
  * setuptools : https://pypi.python.org/pypi/setuptools
  * numpy, scipy (requires fortran), pyYAML, pandas, pyramid-beaker, pyramid-tm, SQLAlchemy, zope.sqlalchemy, lxml  
  
  
For the mst tool : 
* boost
* C++ compilator
* cmake

For pdf generation
* Graphviz
* phantomjs or rsvg-convert

1. Pyramid installation 
------------------------
Follow the instructions on the Pyramid website for installation [here](http://docs.pylonsproject.org/projects/pyramid/en/1.4-branch/narr/install.html) and have a look at the [general documentation] (http://docs.pylonsproject.org/en/latest/docs/pyramid.html)

If you've installed a new instance of Python as recommended on the Pyramid website, don't forget to install the needed packages using this python version.

2. Create a virtual environment
---------------------------
```
virtualenv $HOME/.virtualenvs/mistic  # or any other place you want to create your virtualenv
source $HOME/.virtualenvs/mistic/bin/activate
```

3. Install dependencies  
-----------------------------
### a. Graphviz (non-interactive layout) 

http://www.graphviz.org/

Note : Graphviz must be compiled with the triangulation library

### b. Tool to generate PDF : 

Choose between **rsvg-convert OR phantomjs**

**rsvg-convert** :  

To install rsvg-convert, you'll need xz, librsvg, pkgconfig.

http://tukaani.org/xz/  
http://sourceforge.net/projects/macpkg/files/XZ/5.0.5/XZ.pkg/download  
http://ftp.gnome.org/pub/GNOME/sources/librsvg/  
http://ftp.gnome.org/pub/GNOME/sources/librsvg/2.40/librsvg-2.40.1.tar.xz  
```
xz -d librsvg-2.40.1  
tar -xf librsvg  
```

http://pkgconfig.freedesktop.org/releases/
 
**phantomjs** 

http://phantomjs.org/download.html

### c. To build the mst tool : 

**g++ compiler** 

**cmake** 
http://www.cmake.org/cmake/ressources/software.html  

**boost** 
http://www.boost.org/users/download/  



4. Download and install the MiSTIC package 
-------------------------------------
### a. MiSTIC application

Clone this master branch (development) or the freeze-paper-2017 branch to get the code.
Data can be found in the freeze-paper-2017 branch.

```
git clone -b freeze-paper-2017 https://github.com/iric-soft/MiSTIC.git
```


In the mistic directory with the virtual environment activated, do

```
pip install numpy==1.6.2  # some strange problem when installing from Requirements.txt
pip install -r Requirements.txt  
python setup.py install    #   Use develop if you intend to do development work on it
```

Using develop instead of install doesn't install the package, but creates symbolic links in the site-python directory that point to the current working instance.  This means that your local edits are reflected immediately.

###  b. Build the mst tool

This steps relies on a c++ compiler, cmake, and boost:

```
cd mst
mkdir build
cd build
cmake ..
make
```
Copy mst executable to the bin directory of the virtual environment
```
cp mst/mst $(dirname $(which python))  #  ~/.virtualenvs/mistic/bin/. 
```


###  b.Edit the configuration files 

**In your copy of sample.ini file**, you may want to change/add/remove username and password used for authentification.  By default, the username:password is mistic:mistic.  
```
mistic.basic.auth = mistic:{SHA}YXM/zdQK+NRTPy52mrmXlJl/Xzw=
```

You can generate the authentication string as follows:  
```
htpasswd -bsn username password
```


Set the tools to use to generate the pdf : 
```
mistic.prepare.layout = sfdp # this controls the graphviz graph layout tool 
```

Specify the path where you've installed either phantomjs or rsvg-convert
```
mistic.phantomjs = /u/user/phantomjs-1.6.1-macosx-static/bin/phantomjs
or
mistic.rsvg-convert = /u/user/bin/rsvg-convert
```

Specify the name of the dataset configuration file with the `here` keyword which is relative the the .ini file.
```
mistic.data = %(here)s/sample.yaml
```

Specify the name of the sqlite database.  If it does not exists, it will be created by the application.
```
sqlalchemy.url = sqlite:///%(here)s/mistic.db
```

Lastly, you can specify the port which will serve the web application in the `[server:main]` section.
```
port = 8082 
```

See Pyramid documentation for more server options.



**In your copy of sample.yaml**, specify the path to the dataset and annotation files : 

The data directory need to be in the root directory of the application.  Create a symbolic link if you want to have it somewhere else (to share the data between different instances for example).

```
ontology: data/ontology
orthology: data/annotation/orthology.txt
```

To add annotations or dataset_annotations, append to the annotations or dataset_annotations section : 
```
- id:  identifier
  name: name
  path: data/annotation/annotation_file.txt
```

Annotation files contain information about the rows in the dataset file (if RPKM, then the annotation file may contain the gene description, the chromosome, synonyms,...)

Dataset_annotations files contain information about the columns in the dataset file (if RPKM, then the dataset_annotation file may contain the sample name, gender, tissue type, cell type, ...)

Both of those type of file need to map the identifier use in the dataset file. 

To add a dataset, in the dataset section, specify : 
```
- id: identifier
  name: name
  path: data/datasets/myDataset.txt
  annc: id of the dataset_annotation file as stated in the dataset_annotation section
  annr: id of the annotation file as stated in the annotations section
  desc: text description of the dataset
  expt: which kind of experiment  'ngs' or 'hts' 
  tags: 
    tissue: type of tissue
    project: name of the project 
    technology: technology used to generate the data
  txid: taxon id 
  type: type of data : rpkm
  xfrm: type of transformation to apply : ["log","rank","none"]
```





5. Data preprocessing 
-------------------------------------

Make sure that `mst` and `sfdp` are in your path, and then type:

```
mistic prepare sample.ini
```

This step computes MSTs for each dataset and transformation, and then lays the graphs out using graphviz.
It is make-like, so if you run it again, it should only execute the commands that it needs to, based upon file timestamps.

6. Start the application 
-------------------------------------
To start the web application : 
```
paster serve sample.ini
```




-----------------------------

LICENCE 
================================


Dependencies name | Link |  License | License Details
------------------|------|----------|-----------------
CMAKE             |http://www.cmake.org/ |  - | http://www.cmake.org/cmake/project/license.html
Pyramid           |http://www.pylonsproject.org/ | -| http://www.pylonsproject.org/about/license
SQLite            |http://www.sqlite.org/| public domain | http://www.sqlite.org/copyright.html
Graphivz          |http://www.graphviz.org/ | EPL v.1.0 (new version) | http://www.graphviz.org/License.php
PhantomJS         |http://phantomjs.org/ | BSD |  https://github.com/ariya/phantomjs/blob/master/LICENSE.BSD
rsvg-convert      |https://developer.gnome.org/rsvg/stable/ | GNU GPL | https://developer.gnome.org/rsvg/stable/ 
NumPy             |http://www.numpy.org/ | - |http://www.numpy.org/license.html
SciPy             |http://www.scipy.org/| - |http://www.scipy.org/scipylib/license.html
PyYAML            |http://pyyaml.org/ | MIT |  http://svn.pyyaml.org/pyyaml-legacy/trunk/docs/LICENSE  https://pypi.python.org/pypi/PyYAML
SQLAlchemy        |http://www.sqlalchemy.org/ | MIT | http://www.sqlalchemy.org/download.html
zope.sqlalchemy   |https://pypi.python.org/pypi/zope.sqlalchemy | ZPL 2.1 | http://old.zope.org/Resources/ZPL/
pandas            |http://pandas.pydata.org/ | BSD |  http://pandas.pydata.org/pandas-docs/stable/overview.html#license
lxml              |http://lxml.de/ |  BSD | http://lxml.de/index.html#license
d3.js             |http://d3js.org/ | BSD  | http://opensource.org/licenses/BSD-3-Clause
Bootstrap         |http://getbootstrap.com/2.3.2/  | Apache license v2.0 | http://www.apache.org/licenses/LICENSE-2.0
JQuery            |http://jquery.com/ | MIT | https://jquery.org/license/
Datatable.js      |http://www.datatables.net/ | GPL v2 or BSD(3-point) | http://datatables.net/license_bsd http://datatables.net/license_gpl2
Backbone.js      |http://backbonejs.org/ | MIT  | https://github.com/jashkenas/backbone/blob/master/LICENSE
Underscore.js | http://underscorejs.org | MIT | 
bootstrap-select.js | http://silviomoreto.github.io/bootstrap-select/ | MIT | 
ZeroClipboard | http://zeroclipboard.org/ | MIT | 
Spectrum Colorpicker | https://github.com/bgrins/spectrum | MIT
setuptools | https://pypi.python.org/pypi/setuptools | PSF or ZPL | 


