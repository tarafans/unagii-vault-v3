# Unagii v3 Vaults

### Installation

Uses [**Foundry**](https://github.com/foundry-rs/foundry), which can be installed with:

```shell
# with Rust
cargo install --git https://github.com/foundry-rs/foundry --locked foundry-cli anvil

# without Rust
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Setup

```shell
forge install
cp .env.sample .env # and fill in RPC_URL with one that supports Ethereum archive requests
```

### Test

```shell
make test # run all tests
make unit # run only vault unit tests

# use args='...' to pass extra arguments, e.g.:
make test args='--match-path test/integration/UsdcVault.t.sol -vvv'
```
