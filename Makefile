include .env

.PHONY: test

test:; forge test --fork-url $(RPC_URL) --fork-block-number $(FORK_BLOCK_NUMBER) $(ARGS)
unit:; forge test --match-path test/unit/Vault.t.sol $(ARGS)