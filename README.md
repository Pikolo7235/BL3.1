// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

interface ISubmission {
    function getApprovedRecords() external view returns (string[] memory);

    function addRecord(string memory _albumName) external;

    function getUserFavorites(
        address _address
    ) external view returns (string[] memory);

    function resetUserFavorites() external;
}

contract Submission is ISubmission {
    mapping(address => string[]) public userFavorites;

    function getApprovedRecords()
        external
        pure
        override
        returns (string[] memory)
    {
        string[] memory approved = new string[](9);
        approved[0] = "Boss";
        approved[1] = "Mona";
        approved[2] = "Kirk";
        approved[3] = "Yes to";
        approved[4] = "To the Moon";
        approved[5] = "Hassan";
        approved[6] = "Pocket";
        approved[7] = "Pikolo";
        approved[8] = "Kosynier";
        return approved;
    }

    function addRecord(string memory _albumName) external override {
        userFavorites[msg.sender].push(_albumName);
    }

    function getUserFavorites(
        address _address
    ) external view override returns (string[] memory) {
        return userFavorites[_address];
    }

    function resetUserFavorites() external override {
        delete userFavorites[msg.sender];
    }
}# BL3.1
