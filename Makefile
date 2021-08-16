.PHONY: quic vanilla run cleanup

build:
	sudo docker build -t tor .

quic: build
	./create_network.sh quic

vanilla: build
	./create_network.sh vanilla

run:
	sudo python3 tor_runner.py

cleanup:
	sudo docker rm -f $(sudo docker ps --filter 'name=mn.' -a -q) || echo "No conainers to clean up"
	sudo mn -c
