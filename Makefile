.PHONY: quic vanilla run cleanup torsh image torsh-clean

torsh:
	cargo build --target x86_64-unknown-linux-gnu --manifest-path torsh/Cargo.toml --target-dir build/ 

torsh-clean:
	cargo clean --manifest-path torsh/Cargo.toml --target-dir build/ 

image:
	docker build -t torsh-containernet . --no-cache

quic:
	rm -rf nodes/
	./create_network.sh quic

vanilla:
	./create_network.sh vanilla

run:
	sudo service openvswitch-switch start
	sudo ./tor_runner.py -i torsh-containernet

cleanup:
	docker rm -f $(sudo docker ps --filter 'name=mn.' -a -q) 2> /dev/null || echo "No containers to clean up"
	mn -c
