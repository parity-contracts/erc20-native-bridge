# erc20-native-bridge

[![Build Status][travis-image]][travis-url]
[![Solidity Coverage Status][coveralls-image]][coveralls-url]

[travis-image]: https://travis-ci.org/parity-contracts/erc20-native-bridge.svg?branch=master
[travis-url]: https://travis-ci.org/parity-contracts/erc20-native-bridge
[coveralls-image]: https://coveralls.io/repos/github/parity-contracts/erc20-native-bridge/badge.svg?branch=master
[coveralls-url]: https://coveralls.io/github/parity-contracts/erc20-native-bridge?branch=master

ERC20 to Native token bridge.

**Disclaimer**: The contracts in this repo should be considered **alpha** quality. They have not
been audited or thoroughly tested yet.

## Description

This repo contains contracts for bridging ERC20 tokens from one chain to native tokens (i.e. ETH) on
another chain. The contracts are meant to be used on different networks bridged by a
[parity-bridge](https://github.com/paritytech/parity-bridge) and rely on the
[bridge](https://github.com/parity-contracts/bridge) recipient contract interface for relaying and
receiving bridged messages. For native token emission the bridge recipient uses parity's [block
reward contract](https://wiki.parity.io/Block-Reward-Contract) functionality.

- `ERC20BridgeRecipient` - Manages deposits of the given ERC20 token into the contract and transfers
  from messages received through the bridge. Before depositing into the contract the user must
  previously call `approve` on the ERC20 contract so that the bridge recipient can then successfully
  call `transferFrom` when depositing.
- `NativeBridgeRecipient` - Is meant to be set as the `BlockReward` contract of the host chain,
  processes messages from the bridge and enqueues mint requests to be distributed on the next block
  production. Also processes withdrawals requests by burning the ETH (transfer to 0x0 address) and
  relaying the withdrawal message through the bridge. Keeps track of the total supply.

## Getting started

This project uses the [Truffle](http://truffleframework.com/) framework. To install the required
dependencies run:

```
yarn install
```

To run the test suite:

```
yarn test
```
