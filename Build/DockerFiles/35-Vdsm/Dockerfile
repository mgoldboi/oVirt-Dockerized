FROM fedora:20
MAINTAINER "Moran Goldboim" <mgoldboi@redhat.com>
ENV container docker

#yum updates and needed RPMs
RUN yum -y update; \
yum -y install http://plain.resources.ovirt.org/pub/yum-repo/ovirt-release35.rpm; \
yum -y install net-tools openssh-server vdsm; \
yum clean all;

RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; \
do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;

RUN ln -s /lib/systemd/system/dbus.service /lib/systemd/system/basic.target.wants/dbus.service
RUN cd /usr/lib/systemd/system/sysinit.target.wants/ && ln -s ../systemd-sysctl.service systemd-sysctl.service
RUN systemctl enable sshd.service;

RUN echo 'root:ovirt' | chpasswd

EXPOSE 22 54321

VOLUME [ "/var/log/vdsm/", "/sys/fs/cgroup" ]

#CMD ["/usr/sbin/init"]
ENTRYPOINT ["/usr/sbin/init"]
