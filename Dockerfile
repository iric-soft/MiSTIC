FROM ubuntu:trusty

RUN sudo sed -i -e 's#archive.ubuntu.com#au.archive.ubuntu.com#g' /etc/apt/sources.list
RUN apt-get update
RUN apt-get -q -y install python python-dev python-pip gcc g++ gfortran cmake libboost-all-dev libblas-dev liblapack-dev libxml2-dev libxslt1-dev python-numpy python-scipy python-pandas python-lxml cython phantomjs librsvg2-bin graphviz

ADD . /mistic-src

# build mst
RUN mkdir /mistic-src/mst/build
WORKDIR /mistic-src/mst/build
RUN cmake -DCMAKE_BUILD_TYPE=Release ..
RUN make
RUN make install

# install dependencies
WORKDIR /mistic-src
RUN pip install -r Requirements.txt

# install mistic
RUN pip install /mistic-src
