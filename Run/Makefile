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
	@echo -e "make ovirt-run \t\tRuns a configured oVirt Docker container connected to Database container"
	@echo -e "make ovirt-manual \tbuilds a oVirt Docker container and running interactive engine-setup (oVirt configuration)"
	@echo -e "make ovirt-SA-run \tRuns a oVirt stand alone container"
	@echo -e "End help"

#################################################################
ovirt-db-pid = $(shell docker inspect --format {{.State.Pid}} ovirt-db)
ovirt-pid = $(shell docker inspect --format {{.State.Pid}} ovirt)

#################################################################
#Consts
#################################################################
ver = "3.5.0"
maintainer = "mgoldboi"
run-message = "$(OK_COLOR)\tRunning a $1 container...$(NO_COLOR)"
remove-message = "$(OK_COLOR)\tRemoving temp image/s...$(NO_COLOR)"
data-container-cmessage = "$(OK_COLOR)\tCreating data only container$(NO_COLOR)"

#################################################################
##oVirt configured
#################################################################
ovirt-run:
	@echo -e $(data-container-cmessage)
	#ovirt data container
	docker run -d -v /etc/ovirt-engine -v /etc/sysconfig/ovirt-engine \
	-v /etc/exports.d -v /etc/pki/ovirt-engine/ -v /var/log/ovirt-engine \
	--name ovirt-data $(maintainer)/ovirt-engine-$(ver)
	#DB data container
	docker run -d -v /var/lib/pgsql/data --name ovirt-db-data $(maintainer)/ovirt-db-$(ver)
	@echo -e "$(OK_COLOR)\tRunning oVirt container and DB container connected to data$(NO_COLOR)"
	#run ovirt-db
	docker run --name ovirt-db -d --volumes-from ovirt-db-data $(maintainer)/ovirt-db-$(ver)
	#Run ovirt
	docker run --privileged -dt -p 80:80 -p 443:443 --link ovirt-db:ovirt-db \
	--name ovirt --volumes-from ovirt-data $(maintainer)/ovirt-engine-$(ver)
	@echo -e "$(OK_COLOR)\toVirt is starting...$(NO_COLOR)"
	sleep 10
	@echo -e "$(OK_COLOR)\tYour oVirt-container is ready for use (running now) it may take it a few moments to come up.."
	@echo -e "$(OK_COLOR)\tyou can login https://localhost/ovirt-engine (admin/ovirt)$(NO_COLOR)"


#################################################################
##Configured oVirt build process
#################################################################
ovirt-SA-run:
	@echo -e $(data-container-cmessage)
	sudo docker run -d -v /etc/ovirt-engine -v /etc/sysconfig/ovirt-engine \
	-v /etc/exports.d -v /etc/pki/ovirt-engine/ -v /var/log/ovirt-engine \
	-v /var/lib/pgsql/data --name ovirt-data $(maintainer)/ovirt-sa-configured-$(ver)
	@echo -e "$(OK_COLOR)\tRunning oVirt container connected to ovirt-data container$(NO_COLOR)"
	sudo docker run --privileged -dt -p 80:80 -p 443:443 \
	--name ovirt --volumes-from ovirt-data $(maintainer)/ovirt-sa-configured-$(ver) #CHECKME ovirt-configured
	@echo -e "$(OK_COLOR)\tYour oVirt-container is ready for use (running now) it may take it a few moments to come up.."
	@echo -e "$(OK_COLOR)\tyou can login https://localhost/ovirt-engine (admin/ovirt)$(NO_COLOR)"


#################################################################
##Manual configuration of oVirt
#################################################################
ovirt-manual-run:
	@echo -e "$(OK_COLOR)running ovirt-rpm\(clean install image\)$(NO_COLOR)"
	docker run --privileged -dt -p 80:80 -p 443:443 \
        --name ovirt $(maintainer)/ovirt-$(ver)-rpm

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
#################################################################
##TODO:container maintenance
#################################################################
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
	
