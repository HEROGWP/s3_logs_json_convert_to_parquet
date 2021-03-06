FROM ubuntu:16.04

USER root

ARG JENKINS_REMOTING_VERSION=3.12

WORKDIR /home/jenkins

COPY jenkins-slave /usr/local/bin/jenkins-slave

# Customize sources for apt-get
RUN DISTRIB_CODENAME=$(cat /etc/*release* | grep DISTRIB_CODENAME | cut -f2 -d'=') \
    && echo "deb http://archive.ubuntu.com/ubuntu ${DISTRIB_CODENAME} main universe\n" > /etc/apt/sources.list \
    && echo "deb http://archive.ubuntu.com/ubuntu ${DISTRIB_CODENAME}-updates main universe\n" >> /etc/apt/sources.list \
    && echo "deb http://security.ubuntu.com/ubuntu ${DISTRIB_CODENAME}-security main universe\n" >> /etc/apt/sources.list

#========================
# Install packages
#========================
RUN apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install software-properties-common \
  && add-apt-repository -y ppa:git-core/ppa \
  && apt-get -qqy --no-install-recommends install \
    openssh-client ssh-askpass \
    ca-certificates \
    openjdk-8-jdk \
    tar zip unzip bzip2 \
    wget curl \
    git \
    build-essential \
    jq \
    python2.7-dev python-pip \
    libssl-dev \
  && rm -rf /var/lib/apt/lists/* \
  && sed -i 's/securerandom\.source=file:\/dev\/random/securerandom\.source=file:\/dev\/urandom/' ./usr/lib/jvm/java-8-openjdk-amd64/jre/lib/security/java.security \
  # workaround https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=775775
  && [ -f "/etc/ssl/certs/java/cacerts" ] || /var/lib/dpkg/info/ca-certificates-java.postinst configure \
&& pip install --upgrade \
&& pip install setuptools \
&& pip install awscli \
&& pip install json2parquet \
# Configure ubuntu timezone
&& apt-get update -qqy \
&& apt-get -qqy --no-install-recommends install -y tzdata \
  && ln -sf /usr/share/zoneinfo/Asia/Taipei /etc/localtime \
  && dpkg-reconfigure -f noninteractive tzdata \
# Add normal user with passwordless sudo
&& useradd jenkins --shell /bin/bash --create-home \
  && usermod -a -G sudo jenkins \
  && echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers \
  && echo 'jenkins:secret' | chpasswd \
#==============================
# Jenkins slave
# See https://github.com/jenkinsci/docker-slave/blob/2.62/Dockerfile#L32
#==============================
&& curl --create-dirs -sSLo /usr/share/jenkins/slave.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/$JENKINS_REMOTING_VERSION/remoting-$JENKINS_REMOTING_VERSION.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/slave.jar \
  && chmod a+rwx /home/jenkins \
  && chmod o+x /usr/local/bin/jenkins-slave

#==========
# RVM
#==========
USER jenkins
RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB \
  && curl -sSL https://get.rvm.io | bash

#==========
# Ruby
#==========
USER root
RUN /home/jenkins/.rvm/bin/rvm install 2.3.3

ENTRYPOINT ["/usr/local/bin/jenkins-slave"]
