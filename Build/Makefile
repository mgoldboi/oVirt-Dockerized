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
	@echo -e "\n\tINFO:docker/-io and nsenter are required for this makefile to run\n"
	@echo -e "make ovirt \t\tBuilds a configured oVirt Docker image and a Database image"
	@echo -e "make ovirt-SA \t\tBuilds a configured stand alone oVirt Docker image"
	@echo -e "make ovirt-manual \tbuilds a oVirt Docker container and running interactive engine-setup (oVirt configuration)"
	@echo -e "make ovirt-rpm \t\tbuilds a clean oVirt Docker container with only RPM installation on it "
	@echo -e "make clean- \t\tDestroy and deletes oVirt containers"
	@echo -e "End help"

#################################################################
ovirt-db-pid = $(shell docker inspect --format {{.State.Pid}} ovirt-db)
ovirt-pid = $(shell docker inspect --format {{.State.Pid}} ovirt)

#################################################################
#Consts
#################################################################
ver = "3.5.0"
maintainer = "mgoldboi"
conf-message = "$(OK_COLOR)\tConfiguring $1 container...$(NO_COLOR)"
commit-message = "$(OK_COLOR)\tCommiting $1 container to an image$(NO_COLOR)"
termination-message = "$(OK_COLOR)\tA configured image is ready in your repo\n\t \
Your oVirt-container is ready for use (running now)\n\t \
You can login to https://localhost/ovirt-engine (admin/ovirt)$(NO_COLOR)"
build-message = "$(OK_COLOR)\tBuilding a $1 container...$(NO_COLOR)"
run-message = "$(OK_COLOR)\tRunning a $1 container...$(NO_COLOR)"
remove-message = "$(OK_COLOR)\tRemoving temp image/s...$(NO_COLOR)"
data-container-cmessage = "$(OK_COLOR)\tCreating data only container$(NO_COLOR)"
#################################################################
##oVirt clean RPM deployment
#################################################################
ovirt-rpm:
	@echo -e "$(OK_COLOR)\tBuilding a oVirt Docker container...$(NO_COLOR)"
	docker build --rm --no-cache --tag $(maintainer)/ovirt-$(ver)-rpm DockerFiles/ovirt-rpm/ |& tee ovirt-rpm-build.log


#################################################################
##oVirt configured - testing
#################################################################
ovirt-init:
#log
	@echo -e $(call build-message,"oVirt remote postgres")
	docker build --rm --tag $(maintainer)/ovirt-db-$(ver) \
	DockerFiles/ovirt-db/ |& tee ovirt-remotedb-build.log
	@echo -e $(call build-message,"oVirt")
	docker build --rm --tag $(maintainer)/ovirt-remotedb-$(ver) \
	DockerFiles/ovirt-remotedb/ |& tee ovirt-remotedb-build.log
	docker run --name ovirt-db -d $(maintainer)/ovirt-db-$(ver)
	@echo -e $(call run-message,"oVirt container connected to DB")
	docker run -dt --privileged --link ovirt-db:ovirt-db \
	-p 80:80 -p 443:443  --name ovirt $(maintainer)/ovirt-remotedb-$(ver)

ovirt:ovirt-init
	@echo -e $(call conf-message,"oVirt container with remote DB")
	/usr/bin/nsenter -m -u -n -i -p -t $(ovirt-pid) -- engine-setup  --config-append=/tmp/ovirt-engine-35.conf
	@echo -e $(call commit-message,"oVirt container and DB")
	@echo -e "$(OK_COLOR)\tCommiting oVirt...$(NO_COLOR)"
	docker commit ovirt $(maintainer)/ovirt-engine-$(ver)
	@echo -e "$(OK_COLOR)\tCommiting DB...$(NO_COLOR)"
	docker commit ovirt-db $(maintainer)/ovirt-db-$(ver)
	@echo -e "$(OK_COLOR)\tRemoving temp containers..$(NO_COLOR)"
	docker rm -f ovirt
	docker rm -f ovirt-db
	@echo -e $(remove-message)
	docker rmi $(maintainer)/ovirt-remotedb-$(ver)

#################################################################
##Configured oVirt build process
#################################################################
ovirt-SA-build:
	@echo -e $(call build-message,"oVirt-SA")
	docker build --rm --tag $(maintainer)/ovirt-$(ver) DockerFiles/ovirt-SA/ |& tee ovirt-build.log
	#run container in privileged mode with systemd working
	@echo -e $(call run-message,"oVirt-SA")
	docker run --privileged -dt -p 80:80 -p 443:443 \
	--name ovirt $(maintainer)/ovirt-$(ver)

ovirt-SA:ovirt-SA-build
	@echo -e $(call conf-message,"oVirt-SA")
	/usr/bin/nsenter -m -u -n -i -p -t $(ovirt-pid) -- engine-setup --config-append=/tmp/ovirt-engine-35.conf
	@echo -e $(call commit-message,"oVirt-SA")
	docker stop ovirt
	docker commit ovirt $(maintainer)/ovirt-sa-configured-$(ver)
	sudo docker rm ovirt
	@echo -e $(remove-message)
	sudo docker rmi $(maintainer)/ovirt-$(ver)

#################################################################
##TODO:Manual configuration of oVirt -WIP
#################################################################
ovirt-manual-run:ovirt-rpm
	@echo -e "$(OK_COLOR)running ovirt-rpm\(clean install image\)$(NO_COLOR)"
	docker run --privileged -dt -p 80:80 -p 443:443 \
        --name ovirt $(maintainer)/ovirt-rpm-$(ver)

ovirt-manual:ovirt-manual-run		
	@echo -e "$(OK_COLOR) /tRuning engine-setup  - please setup oVirt manually.$(NO_COLOR)"
	/usr/bin/nsenter -m -u -n -i -p -t $(ovirt-pid) -- engine-setup --jboss-home=/usr/share/ovirt-engine-jboss-as/
	docker commit -p ovirt ovirt-manual-configured-$(ver)
	@echo -e "$(OK_COLOR)\tA configured image is ready in your repo"
	@echo -e "$(OK_COLOR)\tYour oVirt-container is ready for use (running now)"
	@echo -e "$(OK_COLOR)\tyou can login https://localhost/ovirt-engine (admin/ovirt)$(NO_COLOR)"

#################################################################
##TODO:hosted engine - WIP
#################################################################
ovirt-hosted-build:ovirt-rpm
	@echo -e "$(OK_COLOR)\tBuilding a oVirt configured Docker container$(NO_COLOR)"
	docker build --rm --tag $(maintainer)/ovirt DockerFiles/ovirt-hosted/ |& tee ovirt-build.log
	#run container in privileged mode with systemd working
	@echo -e "$(OK_COLOR)\tRunning oVirt container...$(NO_COLOR)"
	docker run --privileged -dt -p 80:80 -p 443:443 \
	--name ovirt $(maintainer)/ovirt-rpm-$(ver)

ovirt-hosted:ovirt-hosted-build
	@echo -e "$(OK_COLOR)\tRuning engine-setup using nsenter$(NO_COLOR)"
	/usr/bin/nsenter -m -u -n -i -p -t $(ovirt-pid) -- engine-setup  --config-append=/tmp/ovirt-engine-35.conf
	@echo -e "$(OK_COLOR)\tStopping oVirt container$(NO_COLOR)"
	docker stop ovirt
	@echo -e "$(OK_COLOR)\tcommiting ovirt container to an image$(NO_COLOR)"
	docker commit -p ovirt $(maintainer)/ovirt-configured-$(ver)
	@echo -e "$(OK_COLOR)\tA configured image is ready in your repo"
	@echo -e "$(OK_COLOR)\tRunning oVirt container$(NO_COLOR)"
	sudo docker start ovirt
	@echo -e "$(OK_COLOR)\tYour oVirt-container is ready for use (running now)"
	@echo -e "$(OK_COLOR)\tyou can login https://localhost/ovirt-engine (admin/ovirt)$(NO_COLOR)"

#################################################################
##TODO:container maintenance - WIP
#################################################################
ovirt-container-deliver:ovirt-container-configured
	#flatten the image
	docker export  > /home/export.tar
   
ovirt-reports-container:
	@echo -e "$(OK_COLOR) Building a RHEV-reports container:$(NO_COLOR)"
	docker build --rm --tag $(maintainer)/ovirt-reports35 DockerFiles/35-reports/ |& tee dockerbuild.log

ovirt-vdsm-rpm:
	@echo -e "$(OK_COLOR) Building a vdsm container:$(NO_COLOR)"
	docker build --rm --tag $(maintainer)/ovirt-vdsm35 DockerFiles/35-Vdsm/ |& tee dockerbuild.log

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

#################################################################
##Clean build containers
#################################################################
clean:
	#@echo -e "$(OK_COLOR)\tStoping running containers $(NO_COLOR)"
	#@docker stop $(shell sudo docker ps -a -q --filter 'name=ovi*') ||:
	@echo -e "$(OK_COLOR)\tRemoving ovirt containers$(NO_COLOR)"
	docker rm -f $(shell docker ps -a -q --filter 'name=ovi*') ||:
	@echo -e "$(OK_COLOR)\tRemoving log files$(NO_COLOR)"
	rm -f ovirt*.log
	
