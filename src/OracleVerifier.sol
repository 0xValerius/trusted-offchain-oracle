/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {Ownable} from "openzeppelin/access/Ownable.sol";

contract OracleVerifier is Ownable {
    mapping(address => bool) public isTrusted;
    uint256 public timeThreshold;

    constructor() {
        isTrusted[msg.sender] = true;
    }

    // add a replay attack protection?

    function verify(uint256 _data, uint256 _timestamp, bytes32 _messageHash, bytes memory _signature)
        public
        view
        returns (bool)
    {
        require(block.timestamp - _timestamp <= timeThreshold, "Timestamp is too old.");
        require(_signature.length == 65, "Invalid signature length.");
        require(_timestamp <= block.timestamp, "Timestamp is in the future.");
        bytes32 messageHash = keccak256(abi.encodePacked(_data, _timestamp));
        require(messageHash == _messageHash, "Invalid message hash.");

        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));

        bytes32 s;
        bytes32 r;
        uint8 v;

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        return isTrusted[ecrecover(ethSignedMessageHash, v, r, s)];
    }

    function setTimeThreshold(uint256 _timeThreshold) external onlyOwner {
        timeThreshold = _timeThreshold;
    }

    function manageTrusted(address _address, bool _isTruded) external onlyOwner {
        isTrusted[_address] = _isTruded;
    }
}
