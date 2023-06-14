/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/StdUtils.sol";

import {MockOracle} from "../src/MockOracle.sol";

/**
 * @title OracleVerifierTest
 * @author 0xValerius
 * @notice This contract is used to test different scenarios and validate the correct functioning of the `OracleVerifier` smart contract.
 * @dev A test contract derived from the `Test` contract in the Forge-Std library. This contract tests various aspects of the OracleVerifier smart contract like function access permissions, data verification, and error conditions.
 */
contract OracleVerifierTest is Test {
    // Errors declarations
    error NotTheOwner();
    error InvalidTimeStamp();
    error InvalidSignatureLength();
    error InvalidHash();
    error InvalidSigner();

    address oracle;
    uint256 oracleKey;
    address owner = makeAddr("owner");
    address user = makeAddr("user");
    uint256 timeThreshold = 10;

    MockOracle mock;

    /**
     * @notice This function sets up the testing environment by initializing a new MockOracle contract and setting its necessary variables.
     * @dev This function is called before each test. It sets up a new instance of the MockOracle contract and makes it ready for the next test case.
     */
    function setUp() public {
        (oracle, oracleKey) = makeAddrAndKey("oracle");
        vm.startPrank(owner);
        mock = new MockOracle();
        mock.setTimeThreshold(timeThreshold);
        mock.manageTrusted(oracle, true);
        vm.stopPrank();
    }

    /**
     * @notice Utility function used to generate a signature for a payload using a given private key.
     * @dev This function helps in testing the `verify` function of the `OracleVerifier` contract.
     * @param data The raw data that needs to be signed.
     * @param timestamp The timestamp at which the data was generated.
     * @param privateKey The private key to sign the data.
     * @return A byte array containing the signed payload.
     */
    function signPayload(bytes memory data, uint256 timestamp, uint256 privateKey) public pure returns (bytes memory) {
        bytes32 messageHash = keccak256(abi.encodePacked(data, timestamp));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, ethSignedMessageHash);
        return abi.encodePacked(r, s, v);
    }

    /**
     * @notice This utility function helps to convert string price values from the Binance API to uint256.
     * @dev This function is used in the `fetchPrice` function.
     * @param s The string containing the price value.
     * @return result A uint256 that represents the price value in wei.
     */
    function stringToUint(string memory s) public pure returns (uint256 result) {
        bytes memory b = bytes(s);
        uint256 i;
        result = 0;
        uint256 totNum = b.length;
        uint256 decPos = 0;
        for (i = 0; i < b.length; i++) {
            uint256 c = uint256(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
                decPos++;
            }
            if (c == 46) break; // encounter '.'
        }
        if (decPos < totNum) {
            for (uint256 j = decPos + 1; j < 18; j++) {
                result *= 10;
            }
        }
        return result;
    }

    /**
     * @notice This function fetches the latest BTC price from Binance's API and returns it along with the symbol.
     * @dev This function is used to simulate an oracle fetching data from an off-chain source. The function uses Foundry's Foreign Function Interface (FFI) to make a system call to curl and retrieves the latest BTC/USDT price from the Binance API. It then parses the returned JSON using the `vm.parseJson` function and extracts the `symbol` and `price` fields. This demonstrates an interesting interaction between the Ethereum Virtual Machine and an external system, a powerful feature when testing smart contract in a local development enviroment.
     */
    function fetchPrice() public returns (string memory symbol, uint256 price) {
        string[] memory inputs = new string[](5);
        inputs[0] = "curl";
        inputs[1] = "-s";
        inputs[2] = "-X";
        inputs[3] = "GET";
        inputs[4] = "https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT";

        bytes memory output = vm.ffi(inputs);
        string memory json = string(output);
        string memory symbol = abi.decode(vm.parseJson(json, "$.symbol"), (string));
        string memory priceString = abi.decode(vm.parseJson(json, "$.price"), (string));
        uint256 price = stringToUint(priceString);
        return (symbol, price);
    }

    /**
     * @notice This test case checks the initial state of the MockOracle contract after deployment.
     * @dev It asserts that the owner is correctly set, the time threshold is correctly set, and the oracle is trusted.
     */
    function test_OracleVerifierDeployment() public {
        assertEq(mock.owner(), owner);
        assertEq(mock.timeThreshold(), timeThreshold);
        assertEq(mock.isTrusted(oracle), true);
    }

    /**
     * @notice This test case checks that only the owner can call owner-only functions in the MockOracle contract.
     * @dev It tests the `onlyOwner` modifier in the MockOracle contract by making a non-owner address call owner-only functions.
     */
    function test_OnlyOwnerFunctions() public {
        vm.startPrank(user);
        vm.expectRevert(NotTheOwner.selector);
        mock.setTimeThreshold(100);
        vm.expectRevert(NotTheOwner.selector);
        mock.manageTrusted(oracle, true);
        vm.stopPrank();
    }

    /**
     * @notice This test case checks the verification process of the MockOracle contract.
     * @dev It tests the `verify` function in the MockOracle contract by passing valid and invalid signatures.
     */
    function test_VerifyTrusted() public {
        (string memory text, uint256 price) = fetchPrice();
        bytes memory data = abi.encode(price, text);
        uint256 timestamp = block.timestamp;
        bytes memory signature = signPayload(data, timestamp, oracleKey);
        mock.updateData(data, timestamp, keccak256(abi.encodePacked(data, timestamp)), signature);
        assertEq(mock.price(), price);
        assertEq(mock.text(), text);

        (, uint256 notTrustedKey) = makeAddrAndKey("notTrustedOracle");
        signature = signPayload(data, timestamp, notTrustedKey);
        vm.expectRevert(InvalidSigner.selector);
        mock.updateData(data, timestamp, keccak256(abi.encodePacked(data, timestamp)), signature);
    }

    /**
     * @notice This test case checks the timestamp validation process in the MockOracle contract.
     * @dev It tests the `verify` function in the MockOracle contract by passing valid and invalid timestamps.
     */
    function test_RevertOnTimestamp() public {
        uint256 price = 123;
        string memory text = "abc";
        bytes memory data = abi.encode(price, text);

        uint256 timestamp = block.timestamp + 1;
        bytes memory signature = signPayload(data, timestamp, oracleKey);
        vm.expectRevert(InvalidTimeStamp.selector);
        mock.updateData(data, timestamp, keccak256(abi.encodePacked(data, timestamp)), signature);

        vm.warp(100);
        timestamp = block.timestamp - timeThreshold - 1;
        signature = signPayload(data, timestamp, oracleKey);
        vm.expectRevert(InvalidTimeStamp.selector);
        mock.updateData(data, timestamp, keccak256(abi.encodePacked(data, timestamp)), signature);
    }

    /**
     * @notice This test case checks the hash validation process in the MockOracle contract.
     * @dev It tests the `verify` function in the MockOracle contract by passing valid and invalid hashes.
     */
    function test_RevertOnCorruptedHash() public {
        uint256 price = 123;
        string memory text = "abc";
        bytes memory data = abi.encode(price, text);
        bytes memory corrupted_data = abi.encode(price, "wrong");
        uint256 timestamp = block.timestamp;
        bytes memory signature = signPayload(data, timestamp, oracleKey);

        vm.expectRevert(InvalidHash.selector);
        mock.updateData(data, timestamp, keccak256(abi.encodePacked(corrupted_data, timestamp)), signature);
    }
}
