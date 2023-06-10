/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract OracleVerifier {
    address private _owner;
    mapping(address => bool) private _isTrusted;
    uint256 public timeThreshold;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event UpdatedOffChainOracle(address indexed _address, bool _isTrusted);

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner.");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function verify(bytes memory _data, uint256 _timestamp, bytes32 _messageHash, bytes memory _signature)
        public
        view
        returns (bool)
    {
        require(_timestamp <= block.timestamp, "Timestamp is in the future.");
        require(block.timestamp - _timestamp <= timeThreshold, "Timestamp is too old.");
        require(_signature.length == 65, "Invalid signature length.");
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

        require(_isTrusted[ecrecover(ethSignedMessageHash, v, r, s)], "Invalid signer.");

        return true;
    }

    function setTimeThreshold(uint256 _timeThreshold) external onlyOwner {
        timeThreshold = _timeThreshold;
    }

    function manageTrusted(address _address, bool _isTruded) external onlyOwner {
        _isTrusted[_address] = _isTruded;
        emit UpdatedOffChainOracle(_address, _isTruded);
    }

    function isTrusted(address _address) external view returns (bool) {
        return _isTrusted[_address];
    }
}
