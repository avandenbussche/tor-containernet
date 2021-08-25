.PHONY: quic vanilla run cleanup

build:
	sudo docker build -t tor .

quic:
	./create_network.sh quic

vanilla:
	./create_network.sh vanilla

run:
	sudo python3 tor_runner.py

cleanup:
	sudo docker rm -f $(sudo docker ps --filter 'name=mn.' -a -q) 2> /dev/null || echo "No containers to clean up"
	sudo mn -c
