ovirt-rpm:
	@echo Building a oVirt Docker container...
	docker build --rm --tag mgoldboi/ovirt-rpm DockerFiles/ovirt-rpm/ |& tee dockerbuild.log
	
ovirt-build:ovirt-rpm
	@echo Building a oVirt configured Docker container,ALL PASSWORDS ARE: ovirt
	docker build --rm --tag mgoldboi/ovirt DockerFiles/ovirt/ |& tee dockerbuild.log
	#run container in privilaged mode with systemd working
	docker run --privileged -dt -p 80:80 -p 443:443 \
	--name ovirt mgoldboi/ovirt

ovirt-pid = $(shell docker inspect --format {{.State.Pid}} ovirt)

ovirt:ovirt-build
	#get pid and run setup from the back door
	/usr/bin/nsenter -m -u -n -i -p -t $(ovirt-pid) -- engine-setup --jboss-home=/usr/share/ovirt-engine-jboss-as/ --config=/tmp/ovirt-engine-35.conf
	#docker commit -p ovirt
	@echo "oVirt-container is ready for use - you can login https://localhost/ovirt-engine (admin/ovirt)"

ovirt-remotedb-init:
	@echo fatching/runing postgres container
	sudo docker run --name ovirt-db -d postgres
	@echo building ovirt container
	docker build --rm --tag mgoldboi/ovirt-remotedb \
        DockerFiles/35-Engine-remotedb/ |& tee dockerbuild.log 

ovirt-db-pid = $(shell docker inspect --format {{.State.Pid}} ovirt-db)
ovirt-remotedb-conf:ovirt-remotedb-init
	@echo creating user:engine password:ovirt
	sleep 3
	nsenter -m -u -n -i -p -t $(ovirt-db-pid) -- su - postgres -c "psql -d template1 -c \"create user engine password 'ovirt';\""
	@echo creating engine DB        
	nsenter -m -u -n -i -p -t $(ovirt-db-pid) -- su - postgres -c "psql -d template1 -c \"create database engine owner engine template template0 encoding 'UTF8' lc_collate 'en_US.UTF-8' lc_ctype 'en_US.UTF-8';\""
	@echo running ovirt-base connected to DB container
	docker run -dt --privileged --link ovirt-db:ovirt-db \
        -p 80:80 -p 443:443  --name ovirt-remotedb mgoldboi/ovirt-remotedb

ovirt-remotedb-pid = $(shell docker inspect --format {{.State.Pid}} ovirt-remotedb)
ovirt-remotedb:ovirt-remotedb-conf
	/usr/bin/nsenter -m -u -n -i -p -t $(ovirt-remotedb-pid) -- engine-setup --jboss-home=/usr/share/ovirt-engine-jboss-as/ --config=/tmp/ovirt-engine-35.conf
	
	
ovirt-db-build:
	docker build --rm --tag mgoldboi/ovirt-db \
        DockerFiles/35-DB/ |& tee dockerbuild.log

ovirt-remotedb-build:
	#build the image with config file.
	docker build --rm --tag mgoldboi/ovirt-remotedb \
	DockerFiles/35-Engine-remotedb/ |& tee dockerbuild.log
	#take care of postgres container
	@echo fatching/runing postgres container
	sudo docker run --name ovirt-db -d postgres

ovirt-remotedb-postgres:ovirt-remotedb-build	
	@echo running ovirt-base connected to db (ovirt-postgres)
	docker run -dt --privileged --link ovirt-db:ovirt-db \
	-p 80:80 -p 443:443  --name ovirt-configured mgoldboi/ovirt-remotedb

ovirt-remotedb-pid = $(shell docker inspect --format {{.State.Pid}} ovirt-remotedb)
ovirt-remotedb2:ovirt-remotedb-postgres
	#configure ovirt to use remote db
	/usr/bin/nsenter -m -u -n -i -p -t -- engine-setup --jboss-home=/usr/share/ovirt-engine-jboss-as/ --config=/tmp/ovirt-engine-35.conf

ovirt-manual-config:
		

ovirt-container-deliver:ovirt-container-configured
	#flatten the image
	docker export  > /home/export.tar
   
ovirt-reports-container:
	@echo Building a RHEV-reports container:
	docker build --rm --tag mgoldboi/ovirt-reports35 DockerFiles/35-reports/ |& tee dockerbuild.log

db-container:
	@echo Building a RHEV-DB container:
	docker build --rm --tag mgoldboi/ovirt-db35 DockerFiles/35-DB/ |& tee dockerbuild.log

vdsm-container:
	@echo Building a vdsm container:
	docker build --rm --tag mgoldboi/ovirt-vdsm35 DockerFiles/35-Vdsm/ |& tee dockerbuild.log

ovirt-FB-container:
	@echo Building a ovirt-fullblown container:
	docker build --rm --tag mgoldboi/ovirt-fullblown DockerFiles/35-FB/ |& tee dockerbuild.log

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

exist = $(shell docker ps | grep ovirt-localdb -c)
test:
	if [ $(exist) = 1 ]; then \
		docker stop ovirt-localdb; \
		docker rm ovirt-localdb; \
	fi
	

clean:
	if [ -a dockerbuild.log ]; then rm dockerbuild.log; fi
	docker stop ovirt*
	docker rm ovirt* 
	docker rmi mgoldboi/ovirt-*
