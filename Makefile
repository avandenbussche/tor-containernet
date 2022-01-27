.PHONY: quic vanilla run cleanup

build: # use buildkit to avoid having to rebuild rust deps each time, call `docker builder prune --filter type=exec.cachemount` to clear cache
	sudo DOCKER_BUILDKIT=1 docker build -t torsh-containernet . --progress=plain

quic:
	sudo rm -rf nodes/
	sudo ./create_network.sh quic

vanilla:
	sudo ./create_network.sh vanilla

run:
	sudo service openvswitch-switch start
	sudo ./tor_runner.py -i torsh-containernet

cleanup:
	sudo docker rm -f $(sudo docker ps --filter 'name=mn.' -a -q) 2> /dev/null || echo "No containers to clean up"
	sudo mn -c
