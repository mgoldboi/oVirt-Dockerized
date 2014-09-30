################################################################
## Makefile for oVirt Dockorized project folder
################################################################
## Definitions
################################################################
.SILENT:
SHELL     := /bin/bash
.PHONY: all clean ctan allwithoutclean
################################################################
## Colordefinition
################################################################
NO_COLOR    = \x1b[0m
OK_COLOR    = \x1b[32;01m
WARN_COLOR  = \x1b[33;01m
ERROR_COLOR = \x1b[31;01m
################################################################
## make help
################################################################
help:
	@echo
	@echo -e "oVirt dockorized Makefile defenitions" 
	@echo -e "*************************************"
	@echo -e "INFO:docker/-io and nsenter are required for this makefile to run"
	@echo -e "\tmake ovirt \t\t\tbuilds a configured oVirt Docker image on a single container "
	@echo -e "\tmake ovirt-manual \t\tbuilds a oVirt Docker container and running interactive engine-setup (oVirt configuration)"
	@echo -e "\tmake ovirt-rpm \t\t\tbuilds a clean oVirt Docker container with only RPM installation on it "
	@echo -e "\tmake ovirt-remotedb \t\tbuilds a oVirt Docker linked to an external Postgres DB container "
	@echo -e "End help"

#################################################################
#vars
#################################################################
ovirt-db-pid = $(shell docker inspect --format {{.State.Pid}} ovirt-db)
ovirt-pid = $(shell docker inspect --format {{.State.Pid}} ovirt)

#################################################################
##oVirt clean RPM deployment
#################################################################
ovirt-rpm:
	@echo -e "$(OK_COLOR)\tBuilding a oVirt Docker container...$(NO_COLOR)"
	docker build --rm --tag mgoldboi/ovirt-rpm DockerFiles/ovirt-rpm/ |& tee ovirt-rpm-build.log

#################################################################
##Configured oVirt build proccess
#################################################################	
ovirt-build:ovirt-rpm
	@echo -e "$(OK_COLOR)\tBuilding a oVirt configured Docker container$(NO_COLOR)"
	docker build --rm --tag mgoldboi/ovirt DockerFiles/ovirt/ |& tee ovirt-build.log
	#run container in privilaged mode with systemd working
	@echo -e "$(OK_COLOR)\tRunning oVirt container...$(NO_COLOR)"
	docker run --privileged -dt -p 80:80 -p 443:443 \
	--name ovirt mgoldboi/ovirt

ovirt:ovirt-build
	@echo -e "$(OK_COLOR)\tRuning engine-setup using nsenter$(NO_COLOR)"
	/usr/bin/nsenter -m -u -n -i -p -t $(ovirt-pid) -- engine-setup --jboss-home=/usr/share/ovirt-engine-jboss-as/ --config=/tmp/ovirt-engine-35.conf
	@echo -e "$(OK_COLOR)\tcommiting ovirt container to an image$(NO_COLOR)"
	docker commit -p ovirt ovirt-configured:3.5
	@echo -e "$(OK_COLOR)\tA configured image is ready in your repo"
	@echo -e "$(OK_COLOR)\tYour oVirt-container is ready for use (running now)"
	@echo -e "$(OK_COLOR)\tyou can login https://localhost/ovirt-engine (admin/ovirt)$(NO_COLOR)"

#################################################################
##Configured oVirt connected to remote database container
#################################################################
ovirt-remotedb-init:ovirt-rpm
	@echo -e "$(OK_COLOR)\tfatching/runing postgres container$(NO_COLOR)"
	sudo docker run --name ovirt-db -d postgres
	@echo -e "$(OK_COLOR)\tbuilding ovirt container$(NO_COLOR)"
	docker build --rm --tag mgoldboi/ovirt-remotedb \
        DockerFiles/ovirt-remotedb/ |& tee ovirt-remotedb-build.log 

ovirt-remotedb-conf:ovirt-remotedb-init
	@echo -e "$(OK_COLOR)\tcreating DB user:engine password:ovirt$(NO_COLOR)"
	sleep 3
	nsenter -m -u -n -i -p -t $(ovirt-db-pid) -- su - postgres -c "psql -d template1 -c \"create user engine password 'ovirt';\""
	@echo -e "$(OK_COLOR)\tcreating engine database$(NO_COLOR)"
	nsenter -m -u -n -i -p -t $(ovirt-db-pid) -- su - postgres -c "psql -d template1 -c \"create database engine owner engine template template0 encoding 'UTF8' lc_collate 'en_US.UTF-8' lc_ctype 'en_US.UTF-8';\""
	@echo -e "$(OK_COLOR)\trunning ovirt-base connected to DB container$(NO_COLOR)"
	docker run -dt --privileged --link ovirt-db:ovirt-db \
        -p 80:80 -p 443:443  --name ovirt mgoldboi/ovirt-remotedb

ovirt-remotedb:ovirt-remotedb-conf
	@echo -e "$(OK_COLOR)\tsetting up oVirt with remote DB container$(NO_COLOR)"
	/usr/bin/nsenter -m -u -n -i -p -t $(ovirt-pid) -- engine-setup --jboss-home=/usr/share/ovirt-engine-jboss-as/ --config=/tmp/ovirt-engine-35.conf
	@echo -e "$(OK_COLOR)\tcommiting ovirt container to an image$(NO_COLOR)"
	docker commit -p ovirt ovirt-remotedb-configured:3.5
	@echo -e "$(OK_COLOR)\tA configured image is ready in your repo"
	@echo -e "$(OK_COLOR)\tYour oVirt-container is ready for use (running now)"
	@echo -e "$(OK_COLOR)\tyou can login https://localhost/ovirt-engine (admin/ovirt)$(NO_COLOR)"
	
#################################################################
##Manual configuration of oVirt
#################################################################
ovirt-manual-run:ovirt-rpm
	@echo -e "$(OK_COLOR)running ovirt-rpm\(clean install image\)$(NO_COLOR)"
	docker run --privileged -dt -p 80:80 -p 443:443 \
        --name ovirt mgoldboi/ovirt-rpm

ovirt-manual:ovirt-manual-run		
	@echo -e "$(OK_COLOR) /tRuning engine-setup  - please setup oVirt manually.$(NO_COLOR)"
	/usr/bin/nsenter -m -u -n -i -p -t $(ovirt-pid) -- engine-setup --jboss-home=/usr/share/ovirt-engine-jboss-as/
	docker commit -p ovirt ovirt-manual-configured:3.5
	@echo -e "$(OK_COLOR)\tA configured image is ready in your repo"
	@echo -e "$(OK_COLOR)\tYour oVirt-container is ready for use (running now)"
	@echo -e "$(OK_COLOR)\tyou can login https://localhost/ovirt-engine (admin/ovirt)$(NO_COLOR)"

#################################################################
ovirt-container-deliver:ovirt-container-configured
	#flatten the image
	docker export  > /home/export.tar
   
ovirt-reports-container:
	@echo -e "$(OK_COLOR) Building a RHEV-reports container:$(NO_COLOR)"
	docker build --rm --tag mgoldboi/ovirt-reports35 DockerFiles/35-reports/ |& tee dockerbuild.log

ovirt-vdsm:
	@echo -e "$(OK_COLOR) Building a vdsm container:"
	docker build --rm --tag mgoldboi/ovirt-vdsm35 DockerFiles/35-Vdsm/ |& tee dockerbuild.log

ovirt-data-container:
	# TODO check if data container exists
	docker run -d --name=ovirt-data \
		-v /etc/ovirt-engine \
		-v /etc/sysconfig/ovirt-engine \
		-v /etc/exports.d \
		-v /etc/pki/ovirt-engine \
		-v /var/log/ovirt-engine \
		rhel6 true >.ovirt-data.cid

dir-volume-map: data-container
	docker inspect --format='{{.Volumes}}' $(shell cat .ovirt.cid) | tr '[' ' ' | tr ' '  '\n' | tr -d ']' | grep -v map >dir-volume-map.txt

test:

#################################################################
##Clean build env
#################################################################
clean:
	@echo -e "$(OK_COLOR)\tStoping running containers $(NO_COLOR)"
	@docker stop $(shell sudo docker ps -a -q --filter 'name=ovi*') ||:
	@echo -e "$(OK_COLOR)\tRemoving ovirt containers$(NO_COLOR)"
	docker rm $(shell docker ps -a -q --filter 'name=ovi*') ||:
	@echo -e "$(OK_COLOR)\tRemoving log files$(NO_COLOR)"
	rm -f ovirt*.log
	
