# Unagii v3 Vaults

### Installation

Uses [**Foundry**](https://github.com/foundry-rs/foundry), which can be installed with:

```shell
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Setup

```shell
forge install
cp .env.sample .env # and fill in RPC_URL
```

### Tests

```shell
make test # run all tests (unit & integration)
make unit # run only vault unit tests
```

Pass extra arguments with `ARGS='...'`, e.g. `make test ARGS='match-path test/integration/UsdcVault.t.sol'` to only test that file.
