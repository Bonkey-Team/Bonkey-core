# Bonkey-core

Bonkey-core is the sets of smart contracts running on Binance Smart Chain (BSC). They serve as the back-end of Bonkey-dAPP.

## How to install

Node version v12.18.2, make sure using nvm to manage version

```
npm install
```

## How to compile

Compile the contracts first

```
npx hardhat compile
```

Flatten the contracts to test in remix,
[flatten contract](https://www.sitepoint.com/flattening-contracts-debugging-remix/)

```
truffle init
truffle-flattener contracts/Project.sol > Project_flatten.sol
```

## How to deploy / upgrade

```
# deploy BEP20 token contract
npx hardhat run --network <localhost mainnet | rinkeby | bsc_test> scripts/deploy_bep20.js
# deploy a project contract
npx hardhat run --network <localhost mainnet | rinkeby | bsc_test> scripts/deploy.js
```

secret.json will be like:

```
{
  "mnemonic": "xxxx yyyy ...... xxxx",
  "projectId": "fa350140428049b8ad42add9ac178781"
}

```

Upgradable deployment:
```
npx hardhat run --network <mainnet | rinkeby | bsc_test> scripts/deploy_upgradeable.js
```

## Run unit tests

```
npx hardhat test
```
