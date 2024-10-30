.PHONY: run fmt install-tools dev

run:
	@if [ "$$(uname -s)" != "Linux" ]; then \
		echo "Error: This script must be run on Linux"; \
		exit 1; \
	fi
	./preflight.sh

fmt:
	@command -v shellcheck >/dev/null 2>&1 || (echo "Installing shellcheck..." && apt-get update && sudo apt-get install -y shellcheck)
	shellcheck preflight.sh

install-tools:
	apt-get update && apt-get install -y shellcheck

dev:
	docker build -t preflight-dev-env .
	docker run --rm -it \
		--privileged \
		-v /sys:/sys \
		-v "$(PWD):/workspace" \
		-w /workspace \
		preflight-dev-env bash
