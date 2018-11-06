# https://github.com/mobile-insight/
FROM ubuntu:16.04

LABEL net.caseonit.mobileinsight.version="0.0.1-beta"
LABEL net.caseonit.mobileinsight.release-date="2018-11-05"
MAINTAINER carlos@caseonit.net

ARG DEBIAN_FRONTEND=noninteractive
WORKDIR /opt

# Add i386 architecture and Java repositories
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get -y install software-properties-common
RUN add-apt-repository -y ppa:webupd8team/java && \
    apt-get update

# 1 - DEPENDENCIES
# ================
# 1.1 General dependencies
RUN apt-get -y install build-essential git unzip ant ccache wget && \
    apt-get -y install bison byacc flex sudo && \
    apt-get -y install autoconf automake && \
    apt-get -y install zlib1g-dev libtool && \
    apt-get -y install openjdk-8-jdk openjdk-8-jre && \
    apt-get -y install python2.7-dev python-setuptools python-pip ruby python-wxgtk3.0
RUN apt-get -y install libc6:i386 libncurses5:i386 libstdc++6:i386 libbz2-1.0:i386 lib32z1 zlib1g:i386
RUN pip install --upgrade pip
RUN pip install cython==0.25.2 && \
    pip install pyyaml xmltodict serial pyserial virtualenv virtualenvwrapper

# 1.2 Java 8
RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    apt-get install -y oracle-java8-installer && \
    apt-get install -y --force-yes expect lib32stdc++6 lib32gcc1 lib32ncurses5 curl && \
    apt-get install -q -y wget build-essential libx11-6:i386 && \
    apt-get clean

# 1.3 Android SDK
ENV ANDROID_HOME /opt/android-sdk
ENV ANDROID_SDK_HOME /opt/android-sdk
ENV PATH ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools
RUN mkdir /opt/android-sdk
RUN gem install android-sdk-installer
COPY android-sdk-installer.yml /opt
RUN ruby -v /usr/local/bin/android-sdk-installer -i -p linux

# 1.4 Replace SDK tool with v25.2.5 to use ant build
RUN cd $ANDROID_HOME && rm -rf tools && \
    wget https://dl.google.com/android/repository/tools_r25.2.5-linux.zip && \
    unzip tools_r25.2.5-linux.zip && \
    rm tools_r25.2.5-linux.zip
RUN cd /opt

# 1.5 Android NDK r10e
ENV ANDROID_NDK_HOME /opt/android-ndk-r10e
ENV PATH ${PATH}:${ANDROID_NDK_HOME}
RUN wget https://dl.google.com/android/repository/android-ndk-r10e-linux-x86_64.zip && \
    unzip android-ndk-r10e-linux-x86_64.zip && \
    rm android-ndk-r10e-linux-x86_64.zip
RUN cd /opt

# 2 - MOBILEINSIGHT REPOS
# =======================
# Official repos - Branch 3.4
#RUN git clone https://github.com/mobile-insight/python-for-android.git
#RUN git clone -b 'v3.4' --single-branch https://github.com/mobile-insight/mobileinsight-core.git
#RUN git clone -b 'v3.4.0' --single-branch https://github.com/mobile-insight/mobileinsight-mobile.git

# Custom repos
RUN git clone https://github.com/Kr0n0/python-for-android
RUN git clone -b medux --single-branch https://github.com/Kr0n0/mobileinsight-core.git
RUN git clone -b medux --single-branch https://github.com/Kr0n0/mobileinsight-mobile.git

# 2.1 Python for Android
RUN cd /opt/python-for-android && \
    python setup.py install
RUN cd /opt

# 2.2 Mobileinsight-Core
RUN cd /opt/mobileinsight-core && \
    ./install-ubuntu.sh
RUN cd /opt

# 2.3 Mobileinsight-Mobile
RUN cd /opt/mobileinsight-mobile && \
    make config
COPY config.yml /opt/mobileinsight-mobile/config
RUN cd /opt/mobileinsight-mobile && make dist && \
    make apk_debug
RUN cd /opt

# 3 - SHELL
# =========
CMD ["/bin/bash"]
