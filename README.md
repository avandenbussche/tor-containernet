# Tor Containernet
Run a private Tor network on containers within a virtualized network.

## Technology:
- [Tor](https://www.torproject.org/) - Anonymous communication network
- [Containernet](https://containernet.github.io/) - Use Docker containers as hosts in Mininet emulations.

## Inspiration
- [Simple Tor Docker container](https://hub.docker.com/r/osminogin/tor-simple/dockerfile)
- [Private Tor network through docker-compose](https://github.com/antitree/private-tor-network)


## Design
First, a directory for each node in the tor network is created under `nodes/` by`create-network.sh`.
Then, `tor_runner.py` reads `nodes/` and creates a Docker container for each of these nodes.
The containers are connected to a switch trough a rate-limited link.
Containernet is used to make Docker containers work with mininet.

## Usage
1. Run `make` to build the Tor Dockerfile
2. Run `./create-network.sh` to populate the `nodes/` directory
3. Run `make run` to start Containernet

A private Tor network will startup, consensus is reached in about 30 seconds.

- To view a node's logs (e.g. `a1`), use `docker logs mn.a1`. (pass `-f` for continuous logging)
- To do a HTTP request through the network: run `c1 curl -x socks5h://localhost:9050 example.com` inside of containernet
