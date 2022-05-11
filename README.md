# Unagii v3 Vaults

### Installation

Install [**Foundry**](https://github.com/foundry-rs/foundry) (if you don't have it already):

```shell
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

Alternative Foundry installation instructions can be found [here](https://book.getfoundry.sh/getting-started/installation.html).

Next, install dependencies with:

```shell
forge install
cp .env.sample .env # and fill in RPC_URL
```

### Tests

```shell
make t # run all tests
make unit # run only unit tests
make integration # run mainnet integration tests
```
