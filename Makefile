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
	sudo mn -c
	sudo docker rm -f $(sudo docker ps --filter 'label=com.containernet' -a -q)
