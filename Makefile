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
	@echo -e "make ovirt \t\tbuilds a configured oVirt Docker image on a single container "
	@echo -e "make ovirt-manual \tbuilds a oVirt Docker container and running interactive engine-setup (oVirt configuration)"
	@echo -e "make ovirt-rpm \t\tbuilds a clean oVirt Docker container with only RPM installation on it "
	@echo -e "make ovirt-remotedb \tbuilds a oVirt Docker linked to an external Postgres DB container "
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
	docker build --rm --tag $(maintainer)/ovirt-$(ver)-rpm DockerFiles/ovirt-rpm/ |& tee ovirt-rpm-build.log

#################################################################
##Configured oVirt build process
#################################################################
ovirt-build:
	@echo -e $(call build-message,"oVirt-SA")
	docker build --rm --tag $(maintainer)/ovirt-$(ver) DockerFiles/ovirt/ |& tee ovirt-build.log
	#run container in privileged mode with systemd working
	@echo -e $(call run-message,"oVirt-SA")
	docker run --privileged -dt -p 80:80 -p 443:443 \
	--name ovirt $(maintainer)/ovirt-$(ver)

ovirt:ovirt-build
	@echo -e $(call conf-message,"oVirt-SA")
	/usr/bin/nsenter -m -u -n -i -p -t $(ovirt-pid) -- engine-setup --config-append=/tmp/ovirt-engine-35.conf
	@echo -e $(call commit-message,"oVirt-SA")
	docker stop ovirt
	docker commit ovirt $(maintainer)/ovirt-sa-configured-$(ver)
	sudo docker rm ovirt
	@echo -e $(remove-message)
	sudo docker rmi $(maintainer)/ovirt-$(ver)
	@echo -e $(data-container-cmessage)
	sudo docker run -d -v /etc/ovirt-engine -v /etc/sysconfig/ovirt-engine \
	-v /etc/exports.d -v /etc/pki/ovirt-engine/ -v /var/log/ovirt-engine \
	-v /var/lib/pgsql/data --name ovirt-data $(maintainer)/ovirt-sa-configured-$(ver)
	@echo -e "$(OK_COLOR)\tRunning oVirt container connected to ovirt-data container$(NO_COLOR)"
	sudo docker run --privileged -dt -p 80:80 -p 443:443 \
	--name ovirt --volumes-from ovirt-data $(maintainer)/ovirt-sa-configured-$(ver) #CHECKME ovirt-configured
	@echo -e "$(OK_COLOR)\toVirt is starting...$(NO_COLOR)"
	sleep 10
	@echo -e "$(OK_COLOR)\tYour oVirt-container is ready for use (running now)"
	@echo -e "$(OK_COLOR)\tyou can login https://localhost/ovirt-engine (admin/ovirt)$(NO_COLOR)"

#################################################################
##Configured oVirt connected to remote database container
#################################################################
ovirt-remotedb-init:
	@echo -e $(call run-message,"postgres")
	sudo docker run --name ovirt-db -d postgres
#	@echo -e "$(OK_COLOR)\tbuilding ovirt container$(NO_COLOR)"
	@echo -e $(call build-message,"oVirt-remoteDB")
	docker build --rm --tag $(maintainer)/ovirt-remotedb-$(ver) \
	DockerFiles/ovirt-remotedb/ |& tee ovirt-remotedb-build.log 

ovirt-remotedb-conf:ovirt-remotedb-init
	sleep 10
	@echo -e "pid is $(ovirt-db-pid)"
	@echo -e "$(OK_COLOR)\tCreating engine DB user:engine password:ovirt$(NO_COLOR)"
	nsenter -m -u -n -i -p -t $(ovirt-db-pid) -- su - postgres -c "psql -d template1 -c \"create user engine password 'ovirt';\""
	@echo -e "$(OK_COLOR)\tcreating engine database$(NO_COLOR)"
	nsenter -m -u -n -i -p -t $(ovirt-db-pid) -- su - postgres -c "psql -d template1 -c \"create database engine owner engine template template0 encoding 'UTF8' lc_collate 'en_US.UTF-8' lc_ctype 'en_US.UTF-8';\""
	#commit a clean engine DB to image repo
	docker commit ovirt-db $(maintainer)/ovirt-db-$(ver)
	@echo -e $(call run-message,"oVirt container connected to DB")
	docker run -dt --privileged --link ovirt-db:ovirt-db \
	-p 80:80 -p 443:443  --name ovirt $(maintainer)/ovirt-remotedb-$(ver)

ovirt-remotedb:ovirt-remotedb-conf
	@echo -e $(call conf-message,"oVirt container with remote DB")
	/usr/bin/nsenter -m -u -n -i -p -t $(ovirt-pid) -- engine-setup  --config-append=/tmp/ovirt-engine-35.conf
	@echo -e $(call commit-message,"oVirt container and DB")
	@echo -e "$(OK_COLOR)\tStopping...$(NO_COLOR)"
	docker stop ovirt
#	docker stop ovirt-db
	@echo -e "$(OK_COLOR)\tCommiting...$(NO_COLOR)"
	docker commit ovirt $(maintainer)/ovirt-remotedb-configured-$(ver)
#	docker commit ovirt-db $(maintainer)/ovirt-db-configured-$(ver)
	@echo -e "$(OK_COLOR)\tRemoving..$(NO_COLOR)"
	docker rm ovirt
#	docker rm ovirt-db
	@echo -e $(remove-message)
	docker rmi $(maintainer)/ovirt-remotedb-$(ver)
	@echo -e $(data-container-cmessage)
	#ovirt data container
	docker run -d -v /etc/ovirt-engine -v /etc/sysconfig/ovirt-engine \
	-v /etc/exports.d -v /etc/pki/ovirt-engine/ -v /var/log/ovirt-engine \
	--name ovirt-data $(maintainer)/ovirt-remotedb-configured-$(ver)
	#DB data container
#	docker run -d -v /var/lib/pgsql/data --name ovirt-db-data $(maintainer)/ovirt-db-configured-$(ver)
	@echo -e "$(OK_COLOR)\tRunning oVirt container and DB container connected to data$(NO_COLOR)"
	#run ovirt-db
#	docker run --name ovirt-db -d --volumes-from ovirt-db-data $(maintainer)/ovirt-db-configured-$(ver)
	#Run ovirt
	docker run --privileged -dt -p 80:80 -p 443:443 --link ovirt-db:ovirt-db \
	--name ovirt --volumes-from ovirt-data $(maintainer)/ovirt-remotedb-configured-$(ver)
	@echo -e "$(OK_COLOR)\toVirt is starting...$(NO_COLOR)"
	sleep 10
	@echo -e "$(OK_COLOR)\tYour oVirt-container is ready for use (running now)"
	@echo -e "$(OK_COLOR)\tyou can login https://localhost/ovirt-engine (admin/ovirt)$(NO_COLOR)"

#################################################################
##Manual configuration of oVirt
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
##TODO:hosted engine
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
##TODO:container maintenance
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

test:
	
	docker run --name ovirt-db -d --volumes-from ovirt-db-data $(maintainer)/ovirt-db-configured-$(ver)
	@echo -e "$(OK_COLOR)\toVirt is starting...$(NO_COLOR)"
	sleep 10
	@echo -e "$(OK_COLOR)\tYour oVirt-container is ready for use (running now)"
	@echo -e "$(OK_COLOR)\tyou can login https://localhost/ovirt-engine (admin/ovirt)$(NO_COLOR)"
#################################################################
##Clean build containers
#################################################################
clean:
	@echo -e "$(OK_COLOR)\tStoping running containers $(NO_COLOR)"
	@docker stop $(shell sudo docker ps -a -q --filter 'name=ovi*') ||:
	@echo -e "$(OK_COLOR)\tRemoving ovirt containers$(NO_COLOR)"
	docker rm $(shell docker ps -a -q --filter 'name=ovi*') ||:
	@echo -e "$(OK_COLOR)\tRemoving log files$(NO_COLOR)"
	rm -f ovirt*.log
	
