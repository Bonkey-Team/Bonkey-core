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

## Run unit tests
