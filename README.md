oVirt-Docker
============

oVirt dockorizing infrastructure 

Prerequisites(required for this makefile to run):
	-docker/-io
	-nsenter are 

following option are currently working:
	-make ovirt 		builds a configured oVirt Docker image on a single container 
	-make ovirt-manual 	builds a oVirt Docker container and running interactive engine-setup (oVirt configuration)
	-make ovirt-rpm 		builds a clean oVirt Docker container with only RPM installation on it 
	-make ovirt-remotedb 	builds a oVirt Docker linked to an external Postgres DB container 
