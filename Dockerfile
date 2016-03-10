FROM ubuntu:14.04
MAINTAINER Sunil Kapil <snlkapil@gmail.com>

ARG SSH_KEY_LOC

ENV CHROME_DRIVER_VERSION 2.14
ENV PYTHON_VERSION 2.7.10
ENV PYTHON_PIP_VERSION 7.0.3
ENV LANG C.UTF-8
ENV DISPLAY :99
ENV UID 1000
ENV GID 1000

USER root
#================================================
# Add dedicated user
#================================================
RUN apt-get -y install sudo
# Install software 
RUN apt-get update
RUN apt-get install -y git
RUN apt-get install -y curl

#========================
#  GIT Configuration
#========================
RUN mkdir -p /opt/git/.ssh
RUN mkdir -p /root/.ssh
RUN chmod -R 700 /root/.ssh
ADD ${SSH_KEY_LOC} /opt/git/.ssh/id_rsa
RUN chmod -R 700 /opt/git/.ssh

RUN echo "\n\
Host github.com\n\ 
    HostName github.com\n\ 
    Port 7999\n\
    User git\n\
    IdentityFile /opt/git/.ssh/id_rsa\n\
    StrictHostKeyChecking no\n\
    UserKnownHostsFile=/dev/null\n\
" >> /root/.ssh/config  

#================================================
# Customize sources for apt-get
#================================================

RUN  echo "deb http://archive.ubuntu.com/ubuntu trusty main universe\n" > /etc/apt/sources.list \
  && echo "deb http://archive.ubuntu.com/ubuntu trusty-updates main universe\n" >> /etc/apt/sources.list

RUN apt-get update -y \
  && apt-get -y install build-essential wget unzip curl xvfb xz-utils zlib1g-dev libssl-dev

#===============
# Google Chrome
#===============
RUN wget -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
  && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
  && apt-get update -y \
  && apt-get -y install google-chrome-stable \
  && rm /etc/apt/sources.list.d/google-chrome.list \
  && rm -rf /var/lib/apt/lists/*

#==================
# Chrome webdriver
#==================
RUN wget --no-verbose -O /tmp/chromedriver_linux64.zip http://chromedriver.storage.googleapis.com/$CHROME_DRIVER_VERSION/chromedriver_linux64.zip \
  && rm -rf /opt/selenium/chromedriver \
  && unzip /tmp/chromedriver_linux64.zip -d /opt/selenium \
  && rm /tmp/chromedriver_linux64.zip \
  && mv /opt/selenium/chromedriver /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION \
  && chmod 755 /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION \
  && ln -fs /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION /usr/bin/chromedriver

#=========
# Firefox
#=========
RUN apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install \
    firefox \
  && rm -rf /var/lib/apt/lists/*

#==================
# Python
#==================
RUN apt-get purge -y python.*
RUN gpg --keyserver ha.pool.sks-keyservers.net --recv-keys C01E1CAD5EA2C4F0B8E3571504C367C218ADD4FF
RUN set -x \
	&& mkdir -p /usr/src/python \
	&& curl -SL "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tar.xz" -o python.tar.xz \
	&& curl -SL "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tar.xz.asc" -o python.tar.xz.asc \
	&& gpg --verify python.tar.xz.asc \
	&& tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
	&& rm python.tar.xz* \
	&& cd /usr/src/python \
	&& ./configure --enable-shared --enable-unicode=ucs4 \
	&& make -j$(nproc) \
	&& make install \
	&& ldconfig \
	&& curl -SL 'https://bootstrap.pypa.io/get-pip.py' | python2 \
	&& pip install --upgrade pip==$PYTHON_PIP_VERSION \
	&& find /usr/local \
		\( -type d -a -name test -o -name tests \) \
		-o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
		-exec rm -rf '{}' + \
	&& rm -rf /usr/src/python

RUN pip install -I selenium==2.45.0 unittest-xml-reporting==1.12.0

#=====
# VNC
#=====
RUN apt-get update -y \
  && apt-get -y install \
    x11vnc \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir -p ~/.vnc \
  && x11vnc -storepasswd secret ~/.vnc/passwd

#=========
# fluxbox
# A fast, lightweight and responsive window manager
#=========
RUN apt-get update -qqy \
  && apt-get -qqy install \
    fluxbox \
  && rm -rf /var/lib/apt/lists/*

#==================
# Xvfb + init scripts
#==================
RUN apt-get update -y 
RUN apt-get install -y unzip xvfb
ENV DISPLAY :99

#Install google chome
RUN chmod a+x /usr/bin/google-chrome

#=================
# Locale settings
#=================
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
RUN locale-gen en_US.UTF-8 \
  && dpkg-reconfigure --frontend noninteractive locales \
  && apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install \
    language-pack-en \
  && rm -rf /var/lib/apt/lists/*

#=======
# Fonts
#=======
RUN apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install \
    fonts-ipafont-gothic \
    xfonts-100dpi \
    xfonts-75dpi \
    xfonts-cyrillic \
    xfonts-scalable \
  && rm -rf /var/lib/apt/lists/*

#=========
#Clean up
#=========
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ~/.config/google-chrome

#check out your  repo
# your_git_repo could be like this: => git@github.com:skapil/expressrestapi.git
RUN git clone <your_git_repo> /opt/git/<name_dir>
RUN git clone <your_git_repo> /opt/git/<name_dir>

WORKDIR /opt/git
EXPOSE 5900
CMD <your test command to run>
