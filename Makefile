build:
	docker build . -t openpgp-test-suite
run:
	docker run -it --entrypoint /bin/bash openpgp-test-suite 