build:
	sudo docker build -t tor .

run:
	sudo python3 tor_runner.py

cleanup:
	sudo mn -c
