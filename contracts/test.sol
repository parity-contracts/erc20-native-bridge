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

import "./bridge.sol";


contract MockBridge is Bridge {
	struct Message {
		address sender;
		address recipient;
		bytes data;
	}

	Message[] public messages;

	function relayMessage(bytes data, address recipient)
		external
	{
		messages.push(Message(msg.sender, recipient, data));
	}

	function deliver(uint256 n)
		external
	{
		uint256 max = n;
		if (n > messages.length) {
			max = messages.length;
		}

		for (uint256 i = 0; i < max; i++) {
			Message storage message = messages[i];
			BridgeRecipient(message.recipient).acceptMessage(message.data, message.sender);
		}

		if (max == messages.length) {
			delete messages;
		} else {
			for (i = max; i < messages.length; i++) {
				messages[i - max] = messages[i];
			}
			messages.length = messages.length - max;
		}
	}
}


/// Source
/// https://github.com/ConsenSys/Tokens/blob/fdf687c69d998266a95f15216b1955a4965a0a6d/contracts/eip20/EIP20.sol
contract SimpleERC20 is ERC20 {
	uint256 constant private MAX_UINT256 = 2**256 - 1;
	mapping (address => uint256) public balances;
	mapping (address => mapping (address => uint256)) public allowed;

	uint256 public totalSupply;

	constructor(uint256 _initialAmount)
		public
	{
		balances[msg.sender] = _initialAmount;
		totalSupply = _initialAmount;
	}

	function transfer(address _to, uint256 _value)
		public
		returns (bool success)
	{
		require(balances[msg.sender] >= _value);
		balances[msg.sender] -= _value;
		balances[_to] += _value;
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value)
		public
		returns (bool success)
	{
		uint256 allowance = allowed[_from][msg.sender];
		require(balances[_from] >= _value && allowance >= _value);
		balances[_to] += _value;
		balances[_from] -= _value;
		if (allowance < MAX_UINT256) {
			allowed[_from][msg.sender] -= _value;
		}
		emit Transfer(_from, _to, _value);
		return true;
	}

	function approve(address _spender, uint256 _value)
		public
		returns (bool success)
	{
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function balanceOf(address _owner)
		public
		view
		returns (uint256 balance)
	{
		return balances[_owner];
	}

	function allowance(address _owner, address _spender)
		public
		view
		returns (uint256 remaining)
	{
		return allowed[_owner][_spender];
	}
}
