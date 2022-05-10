# Unagii v3 Vaults

## Setup

Install [**Foundry**](https://github.com/foundry-rs/foundry):

```shell
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

Alternative installation instructions can be found [here](https://book.getfoundry.sh/getting-started/installation.html).

## Testing

```shell
forge build
forge test -vvv
forge test -vvv --fork-url <your_rpc_url> --fork-block-number 1 --gas-report
```
