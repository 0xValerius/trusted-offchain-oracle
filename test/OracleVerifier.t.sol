/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {OracleVerifier} from "../src/OracleVerifier.sol";

contract OracleVerifierTest is Test {
    function setUp() public {
        Oracle oracle = new Oracle();
        oracle.setTimeThreshold(100);
    }
}
