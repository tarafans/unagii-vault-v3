include .env

.PHONY: test

test:; forge test --fork-url $(RPC_URL) --fork-block-number $(FORK_BLOCK_NUMBER) -vv