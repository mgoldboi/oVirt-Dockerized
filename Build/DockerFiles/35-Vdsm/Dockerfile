FROM rhel7 
MAINTAINER "Moran Goldboim" <mgoldboi@redhat.com>
ENV container docker
RUN yum -y update && yum clean all
RUN rpm -e --nodeps fakesystemd
RUN yum -y install systemd

#yum updates and needed RPMs
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
RUN systemctl enable sshd.service; \
systemctl enable libvirtd; \
systemctl enable virtlockd

RUN echo "listen_tls = 0" >> /etc/libvirt/libvirtd.conf; \
echo 'listen_tcp = 1' >> /etc/libvirt/libvirtd.conf; \
echo 'tls_port = "16514"' >> /etc/libvirt/libvirtd.conf; \
echo 'tcp_port = "16509"' >> /etc/libvirt/libvirtd.conf; \
echo 'auth_tcp = "none"' >> /etc/libvirt/libvirtd.conf

RUN echo 'LIBVIRTD_ARGS="--listen"' >> /etc/sysconfig/libvirtd
RUN mkdir -p /var/lib/libvirt/images/

# Edit the service file which includes ExecStartPost to chmod /dev/kvm
RUN sed -i "/Service/a ExecStartPost=\/bin\/chmod 666 /dev/kvm" /usr/lib/systemd/system/libvirtd.service


RUN echo 'root:ovirt' | chpasswd

EXPOSE 22 54321 16509

VOLUME [ "/var/log/vdsm/", "/sys/fs/cgroup", "/proc/modules", "/var/lib/libvirt", "/sys/fs/cgroup" ]

#CMD ["/usr/sbin/init"]
ENTRYPOINT ["/usr/sbin/init"]
