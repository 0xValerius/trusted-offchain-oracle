/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

abstract contract OracleVerifier {
    // Event declarations
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event UpdatedOffChainOracle(address indexed _address, bool _isTrusted);

    // Error declarations
    error NotTheOwner();
    error InvalidTimeStamp();
    error InvalidSignatureLength();
    error InvalidHash();
    error InvalidSigner();

    address private _owner;
    mapping(address => bool) private _isTrusted;
    uint256 private _timeThreshold;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert NotTheOwner();
        }
        _;
    }

    modifier verify(bytes memory data, uint256 timestamp, bytes32 messageHash, bytes memory signature) {
        if (timestamp > block.timestamp || block.timestamp - timestamp > _timeThreshold) {
            revert InvalidTimeStamp();
        }

        if (signature.length != 65) {
            revert InvalidSignatureLength();
        }

        bytes32 expectedMessageHash = keccak256(abi.encodePacked(data, timestamp));
        if (expectedMessageHash != messageHash) {
            revert InvalidHash();
        }

        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));

        bytes32 s;
        bytes32 r;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (!_isTrusted[ecrecover(ethSignedMessageHash, v, r, s)]) {
            revert InvalidSigner();
        }

        _;
    }

    // State modifying functions
    function transferOwnership(address newOwner) public virtual onlyOwner {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function setTimeThreshold(uint256 newTimeThreshold) external onlyOwner {
        _timeThreshold = newTimeThreshold;
    }

    function manageTrusted(address oracleAddress, bool oracleStatus) external onlyOwner {
        _isTrusted[oracleAddress] = oracleStatus;
        emit UpdatedOffChainOracle(oracleAddress, oracleStatus);
    }

    // View function
    function timeThreshold() external view returns (uint256) {
        return _timeThreshold;
    }

    function isTrusted(address _address) external view returns (bool) {
        return _isTrusted[_address];
    }
}
