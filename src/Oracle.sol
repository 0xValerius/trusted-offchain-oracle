/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Oracle {
    mapping(address => bool) public isTrusted;
    uint256 public timeThreshold;

    // verify a signature came from a trusted source

    function setTimeThreshold(uint256 _timeThreshold) external onlyOwner() {
        timeThreshold = _timeThreshold;
    }
}
