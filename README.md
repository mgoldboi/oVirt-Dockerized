#oVirt-Dockerized

###Prerequisites(required for this makefile to run):
	-docker/-io
	-nsenter (comes with fc20)

###project is devided to Build dir:
  building images

###and Run dir
  running containers based on docker hub or local hub
  
###following Run option are working:
######make ovirt-run -	Runs a configured oVirt Docker container connected to Database container
######make ovirt-manual - builds a oVirt Docker container and running interactive engine-setup (oVirt configuration)
######make ovirt-SA-run -Runs a oVirt stand alone container

###following build option are currently working:
######make ovirt -      Builds a configured oVirt Docker image and a Database image
######make ovirt-SA -	Builds a configured stand alone oVirt Docker image
######make ovirt-manual- builds a oVirt Docker container and running interactive engine-setup (oVirt configuration)
######make ovirt-rpm -	builds a clean oVirt Docker container with only RPM installation on it 
######make clean -	Destroy and deletes oVirt containers




*tested on FC20*
