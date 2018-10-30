// Copyright 2018 Parity Technologies (UK) Ltd.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

pragma solidity ^0.4.24;

interface BlockReward {
	function reward(address[] beneficiaries, uint16[] kind)
		external
		returns (address[], uint256[]);
}

interface Bridge {
	function relayMessage(bytes data, address recipient)
		external;
}

interface BridgeRecipient {
	function acceptMessage(bytes data, address sender)
		external;
}

interface ERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);

	function transfer(address to, uint256 value)
		external
		returns (bool);

	function transferFrom(address from, address to, uint256 value)
		external
		returns (bool);

	function approve(address spender, uint256 value)
		external
		returns (bool);
}


contract ERC20BridgeRecipient is BridgeRecipient {
	event Deposit(address indexed from, address indexed recipient, uint256 value);
	event Withdraw(address indexed recipient, uint256 value);

	address public bridgedRecipientAddress;
	Bridge public bridge;

	ERC20 public erc20;

	constructor(address bridgeAddr, address bridgedRecipientAddr, address erc20Addr)
		public
	{
		bridgedRecipientAddress = bridgedRecipientAddr;
		bridge = Bridge(bridgeAddr);
		erc20 = ERC20(erc20Addr);
	}

	function acceptMessage(bytes data, address sender)
		external
	{
		require(msg.sender == address(bridge));
		require(sender == bridgedRecipientAddress);

		(address recipient, uint256 value) = MessageSerialization.deserializeMessage(data);

		require(erc20.transfer(recipient, value));

		emit Withdraw(recipient, value);
	}

	function deposit(address recipient, uint256 value)
		external
	{
		require(erc20.transferFrom(msg.sender, address(this), value));

		bytes memory data = MessageSerialization.serializeMessage(recipient, value);
		bridge.relayMessage(data, bridgedRecipientAddress);

		emit Deposit(msg.sender, recipient, value);
	}
}


contract NativeBridgeRecipient is BridgeRecipient, BlockReward {
	struct Mint {
		address recipient;
		uint256 value;
	}

	event Minting(address indexed recipient, uint256 value);
	event Burned(uint256 value);

	address constant BURN_ADDRESS = 0x0000000000000000000000000000000000000000;
	address constant SYSTEM_ADDRESS = 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE;

	address public bridgedRecipientAddress;
	Bridge public bridge;

	uint256 public totalSupply;

	Mint[] public minting;

	constructor(address bridgeAddr)
		public
	{
		bridge = Bridge(bridgeAddr);
	}

	function setBridgedRecipientAddress(address bridgedRecipientAddr)
		external
	{
		require(bridgedRecipientAddress == 0);

		bridgedRecipientAddress = bridgedRecipientAddr;
	}

	function acceptMessage(bytes data, address sender)
		external
	{
		require(bridgedRecipientAddress != 0);

		require(msg.sender == address(bridge));
		require(sender == bridgedRecipientAddress);

		(address recipient, uint256 value) = MessageSerialization.deserializeMessage(data);
		mint(recipient, value);
	}

	function withdraw(address recipient)
		external
		payable
	{
		require(bridgedRecipientAddress != 0);

		bytes memory data = MessageSerialization.serializeMessage(recipient, msg.value);
		bridge.relayMessage(data, bridgedRecipientAddress);
		burn(msg.value);
	}

	function reward(address[], uint16[])
		external
		returns (address[], uint256[])
	{
		require(msg.sender == SYSTEM_ADDRESS);

		address[] memory beneficiaries = new address[](minting.length);
		uint256[] memory rewards = new uint256[](minting.length);

		for (uint256 i = 0; i < minting.length; i++) {
			beneficiaries[i] = minting[i].recipient;
			rewards[i] = minting[i].value;

			totalSupply += minting[i].value;
		}

		delete minting;

		return (beneficiaries, rewards);
	}

	function mint(address recipient, uint256 value)
		internal
	{
		minting.push(Mint(recipient, value));
		emit Minting(recipient, value);
	}

	function burn(uint256 value)
		internal
	{
		totalSupply -= value;
		BURN_ADDRESS.transfer(value);
		emit Burned(value);
	}
}


library MessageSerialization {
	function serializeMessage(address recipient, uint256 value)
		external
		pure
		returns (bytes)
	{
		bytes memory buffer = new bytes(52);

		// solium-disable-next-line security/no-inline-assembly
		assembly {
			// buffer has a total of 84 bytes (32 bytes length + 52 bytes capacity)
			// we write the recipient address at offset 52 (84 - 32), and
			// afterwards we write the 32 bytes of the value at offset 32 (52 - 20)
			// overwriting the first 12 bytes of the previous write which will be set
			// to 0 (since address is only 20 bytes long).
			mstore(add(buffer, 52), recipient)
			mstore(add(buffer, 32), value)
		}

		return buffer;
	}

	function deserializeMessage(bytes buffer)
		public
		pure
		returns (address, uint256)
	{
		require(buffer.length == 52);

		address recipient;
		uint256 value;

		// solium-disable-next-line security/no-inline-assembly
		assembly {
			recipient := mload(add(buffer, 52))
			value := mload(add(buffer, 32))
		}

		return (recipient, value);
	}
}
