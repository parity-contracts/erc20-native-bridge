"use strict";

const ERC20BridgeRecipient = artifacts.require("ERC20BridgeRecipient");
const NativeBridgeRecipient = artifacts.require("NativeBridgeRecipient");
const MessageSerialization = artifacts.require("MessageSerialization");

const MockBridge = artifacts.require("MockBridge");
const SimpleERC20 = artifacts.require("SimpleERC20");

module.exports = deployer => {
  const erc20initialAmount = 9000;

  deployer.deploy(SimpleERC20, erc20initialAmount)
    .then(() => {
      return deployer.deploy(MockBridge);
    }).then(() => {
      return deployer.deploy(MessageSerialization);
    }).then(() => {
      return deployer.link(MessageSerialization, [NativeBridgeRecipient, ERC20BridgeRecipient]);
    }).then(() => {
      return deployer.deploy(NativeBridgeRecipient, MockBridge.address);
    }).then(() => {
      return deployer.deploy(
        ERC20BridgeRecipient,
        MockBridge.address,
        NativeBridgeRecipient.address,
        SimpleERC20.address,
      );
    }).then(async () => {
      const nativeBridgeRecipient = await NativeBridgeRecipient.deployed();
      const erc20BridgeRecipient = await ERC20BridgeRecipient.deployed();

      await nativeBridgeRecipient.setBridgedRecipientAddress(erc20BridgeRecipient.address);

      console.log();
      console.log("***************************************************************************");
      console.log("ERC20 Token address:             " + SimpleERC20.address);
      console.log("Mock Bridge address:             " + MockBridge.address);
      console.log("ERC20 Bridge Recipient address:  " + ERC20BridgeRecipient.address);
      console.log("Native Bridge Recipient address: " + NativeBridgeRecipient.address);
      console.log("***************************************************************************");
      console.log();
    });
};
