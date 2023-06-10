/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {OracleVerifier} from "../src/OracleVerifier.sol";

contract MockOracle is OracleVerifier {
    uint256 public price;
    string public text;

    function updatePrice(bytes memory data, uint256 timestamp, bytes32 messageHash, bytes memory signature)
        public
        verify(data, timestamp, messageHash, signature)
    {
        (uint256 newPrice, string memory newText) = abi.decode(data, (uint256, string));
        price = newPrice;
        text = newText;
    }
}
