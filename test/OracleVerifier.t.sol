/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/StdUtils.sol";

import {OracleVerifier} from "../src/OracleVerifier.sol";

contract OracleVerifierTest is Test {
    address oracle;
    uint256 oracle_key;
    address owner = makeAddr("owner");
    address user = makeAddr("user");
    uint256 timeThreshold = 100;

    OracleVerifier verifier;

    function setUp() public {
        (oracle, oracle_key) = makeAddrAndKey("oracle");
        vm.startPrank(owner);
        verifier = new OracleVerifier();
        verifier.setTimeThreshold(timeThreshold);
        verifier.manageTrusted(oracle, true);
        vm.stopPrank();
    }

    // utils function
    function signPayload(bytes memory data, uint256 timestamp, uint256 privateKey) public pure returns (bytes memory) {
        bytes32 messageHash = keccak256(abi.encodePacked(data, timestamp));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, ethSignedMessageHash);
        return abi.encodePacked(r, s, v);
    }

    function test_OracleVerifierDeployment() public {
        assertEq(verifier.owner(), owner);
        assertEq(verifier.timeThreshold(), 100);
        assertEq(verifier.isTrusted(oracle), true);
    }

    function test_OnlyOwnerFunctions() public {
        vm.startPrank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        verifier.setTimeThreshold(100);
        vm.expectRevert("Ownable: caller is not the owner");
        verifier.manageTrusted(oracle, true);
        vm.stopPrank();
    }

    function test_VerifyTrusted() public {
        uint256 price = 123;
        string memory mock = "abc";
        bytes memory data = abi.encode(price, mock);
        uint256 timestamp = block.timestamp;
        bytes memory signature = signPayload(data, timestamp, oracle_key);
        assertEq(verifier.verify(data, timestamp, keccak256(abi.encodePacked(data, timestamp)), signature), true);
    }

    function test_RevertOnTimestamp() public {
        uint256 price = 123;
        string memory mock = "abc";
        bytes memory data = abi.encode(price, mock);
        uint256 timestamp = block.timestamp + 1;
        bytes memory signature = signPayload(data, timestamp, oracle_key);
        vm.expectRevert("Timestamp is in the future.");
        assertEq(verifier.verify(data, timestamp, keccak256(abi.encodePacked(data, timestamp)), signature), true);

        timestamp = block.timestamp - timeThreshold - 1;
        signature = signPayload(data, timestamp, oracle_key);
        vm.expectRevert("Timestamp is too old.");
        assertEq(verifier.verify(data, timestamp, keccak256(abi.encodePacked(data, timestamp)), signature), true);
    }
}
