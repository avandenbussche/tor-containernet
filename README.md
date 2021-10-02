# Tor Containernet

Run a private Tor network on containers within a virtualized network. Especially to simulate Tor over QUIC, located
at https://github.com/jaapp-/tor.

## Technology:

- [Tor](https://www.torproject.org/) - Anonymous communication network
- [Containernet](https://containernet.github.io/) - Use Docker containers as hosts in Mininet emulations.

## Inspiration

- [Simple Tor Docker container](https://hub.docker.com/r/osminogin/tor-simple/dockerfile)
- [Private Tor network through docker-compose](https://github.com/antitree/private-tor-network)

## Design

First, a directory for each node in the tor network is created under `nodes/` by`create-network.sh`.
Then, `tor_runner.py` reads `nodes/` and creates a Docker container for each of these nodes. The containers are
connected to a switch trough a rate-limited link. Containernet is used to make Docker containers work with mininet.

## Usage

1. Clone the repo with the `--recursive` flag
2. Run `make build` to build `tor/` as Docker container named `tor`
3. Run `make quic` or `make vanilla` to populate the `nodes/` directory, enabling or disabling QUIC respectively
4. Run `sudo ./tor_runner.py` to start Containernet

A private Tor network will start up, consensus is reached in about 30 seconds.

- run `./tor_runner.py -h` for options, such as adding loss, latency or artificial load to the network
- To view a node's logs (e.g. `a1`), use `docker logs mn.a1`. (pass `-f` for continuous logging)
- To do a HTTP request through the network: run `c1 curl -x socks5h://localhost:9050 example.com` inside of containernet
- `bwtool.py` is an included bandwidth measuring tool, run `bwtool.py -h` for help.
  Example: `c1 bwtool.py -p 0.5 localhost:9050 10.0.0.12:8000 -s 320 -n test`
- `bwplotter.py` creates graphs based on `bwtool.py` output files
- `bwtables.py` creates a summary table based on `bwtool.py` output files
- modify `create_network.sh` to change the amount of authority, relay and client nodes
- To recover from a crash, use `make cleanup`
