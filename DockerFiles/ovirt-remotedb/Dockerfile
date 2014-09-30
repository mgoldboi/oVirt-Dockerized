FROM mgoldboi/ovirt-rpm:latest
MAINTAINER "Moran Goldboim" <mgoldboi@redhat.com>
ENV container docker

RUN yum -y update; yum clean all
ADD ovirt-engine-35-remotedb.conf /tmp/ovirt-engine-35.conf
#ADD engine-setup.service /etc/init.d/engine-setup
#RUN /sbin/chkconfig engine-setup on
