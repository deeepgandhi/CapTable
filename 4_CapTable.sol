// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.20;

import "fhevm/abstracts/EIP712WithModifier.sol";
import "fhevm/lib/TFHE.sol";
import {EncryptedERC20} from "contracts/EncryptedERC20.sol";


contract EncryptedCapTable {

 // Events for logging changes and transactions
    event AllocationAdded(string title, address stakeholder);
    event FundsAdded(string title, uint256 amount);
    event ClaimMade(string title, address stakeholder, uint256 amount);
    event ClaimAvailabilityUpdated(string title, bool availability);
    event WalletUpdated(string title, address newWallet);


    struct Allocation {
        address stakeholder; // Address of the stakeholder
        // string category; // Category of the stakeholder, e.g., Investor, Seed
        uint256 totalAllocation; // Total amount of assets allocated
        uint256 distribution; // Amount distributed
        uint256 funded; // Amount funded
        uint256 unlocked; // Amount unlocked and available to claim
        uint256 claimed; // Amount that has already been claimed
        bool isClaimAvailable; // Flag to indicate if a claim is available
        address ercAddres;
    }

    struct CompanyDetails {
        bytes32 companyKey;
        uint256 AllocationNumber;
        address admin;
        uint256 totalFund;
        uint256 distributesFundl;
        uint256 totalClaimedFund;
        uint256 totalLocked;
    }

    mapping(bytes32 => CompanyDetails) public company;
    mapping(bytes32 => mapping(address => bool)) public isEmpoloy;
    mapping(bytes32 => mapping(address => Allocation)) public allocation;

    function createCompanykey(
        string memory _string,
        uint256 _registeryear
    ) external returns (bytes32, address) {
        string memory tokenName = string(abi.encodePacked("EERC20", _string));
        EncryptedERC20 token = new EncryptedERC20(tokenName);
        return (
            keccak256(abi.encodePacked(_string, _registeryear)),
            address(token)
        );
    }

    function addEmploy(address _address, bytes32 _key) external {
        isEmpoloy[_key][_address] = true;
        CompanyDetails memory details = company[_key];
        require(msg.sender == details.admin, "caller is not admin");
        details.AllocationNumber = details.AllocationNumber + 1;
        company[_key] = details;

        Allocation memory employ = allocation[_key][_address];
        employ.stakeholder = _address;
        allocation[_key][_address] = employ;
    }

    function addAllocation(
        address _address,
        uint256 _tokenAmount,
        bytes32 _key
    ) public {
        Allocation memory alloc = allocation[_key][_address];
        alloc.totalAllocation = _tokenAmount;
        allocation[_key][_address] = alloc;
    }
}


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Simple role-based access control
contract AccessControl {
    mapping(address => bool) private admins;

    event AdminRoleGranted(address indexed grantedTo);
    event AdminRoleRevoked(address indexed revokedFrom);

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "AccessControl: caller is not an admin");
        _;
    }

    constructor() {
        // Grant the contract deployer the default admin role.
        _grantAdminRole(msg.sender);
    }

    function grantAdminRole(address account) external onlyAdmin {
        _grantAdminRole(account);
    }

    function revokeAdminRole(address account) external onlyAdmin {
        _revokeAdminRole(account);
    }

    function _grantAdminRole(address account) internal {
        admins[account] = true;
        emit AdminRoleGranted(account);
    }

    function _revokeAdminRole(address account) internal {
        admins[account] = false;
        emit AdminRoleRevoked(account);
    }

    function isAdmin(address account) public view returns (bool) {
        return admins[account];
    }


     // ... [Rest of the previous code] ...

    // Function to update allocation distribution
    function updateDistribution(string memory _title, uint256 _amount) public onlyAdmin {
        Allocation storage allocation = allocations[_title];
        require(_amount <= allocation.funded, "Cannot distribute more than funded");
        allocation.distribution += _amount;
        emit FundsAdded(_title, _amount);
    }

    // Function to update a stakeholder's wallet address
    function updateWallet(string memory _title, address _newWallet) public onlyAdmin {
        Allocation storage allocation = allocations[_title];
        allocation.stakeholder = _newWallet;
        emit WalletUpdated(_title, _newWallet);
    }

    // Function for a stakeholder to withdraw their claim
    function withdrawClaim(string memory _title) public {
        Allocation storage allocation = allocations[_title];
        require(msg.sender == allocation.stakeholder, "Caller is not stakeholder");
        require(allocation.claimed > 0, "No claimed funds to withdraw");

        // Add the token transfer logic here, e.g., ERC20 transfer
        // Make sure to check the result of the token transfer operation

        emit ClaimMade(_title, msg.sender, allocation.claimed);
        allocation.claimed = 0; // Reset claimed funds after withdrawal
    }

    // Additional administrative functions as required ...

    // ... Rest of the smart contract ...
}




}

   
   