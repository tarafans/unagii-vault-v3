include .env

t:; forge test --fork-url $(RPC_URL) --fork-block-number $(FORK_BLOCK_NUMBER)
unit:; forge test --match-path test/unit/*
integration:; forge test --fork-url $(RPC_URL) --fork-block-number $(FORK_BLOCK_NUMBER) --match-path test/integration/* -vvv