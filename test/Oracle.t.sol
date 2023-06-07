/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {Oracle} from "../src/Oracle.sol";

contract OracleTest is Test {
    function setUp() public {
        Oracle oracle = new Oracle();
        oracle.setTimeThreshold(100);
    }
}
