.PHONY: quic vanilla run cleanup torsh image

torsh:
	cargo build --target x86_64-unknown-linux-gnu --manifest-path torsh/Cargo.toml --target-dir build/ 

image:
	sudo docker build -t torsh-containernet . --no-cache

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
