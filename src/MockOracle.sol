/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {OracleVerifier} from "../src/OracleVerifier.sol";

contract MockOracle is OracleVerifier {
    uint256 private _price;
    string private _mock;

    function updatePrice(bytes memory data, uint256 timestamp, bytes32 messageHash, bytes memory signature)
        public
        verify(data, timestamp, messageHash, signature)
    {
        (uint256 price, string memory mock) = abi.decode(data, (uint256, string));
        _price = price;
        _mock = mock;
    }

    function getPrice() public view returns (uint256) {
        return _price;
    }
}
