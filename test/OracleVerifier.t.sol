/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {OracleVerifier} from "../src/OracleVerifier.sol";

contract OracleVerifierTest is Test {
    address owner = makeAddr("owner");
    address oracle = makeAddr("oracle");
    address user = makeAddr("user");

    OracleVerifier verifier;

    function setUp() public {
        vm.startPrank(owner);
        verifier = new OracleVerifier();
        verifier.setTimeThreshold(100);
    }

    function test_OracleVerifierDeployment() public {
        assertEq(verifier.owner(), owner);
        assertEq(verifier.timeThreshold(), 100);
    }
}
