// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/** 
    NB: The contract inherits `VendorAccounting` for accounting logic.
        This internal accounting logic is divorced from the normal ERC20 accounting.

    Calling `payoutVendor` means that the `administrator` has paid the vendor.
    These payments should be checked against the `balanceOf(vendor)`. 
    At the end of the conference `vendor[address].totalReceived` should == `balanceOf(vendor)`
    BUT, this accounting logic will fail if vendors transfer BuidlBux between accounts. 
    To remedy this the `_afterTokenTransfer` hook only updates when a transfer is to a vendor,
    but not from a vendor account.

  */

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./VendorAccounting.sol";

contract BuidlBux is VendorAccounting, ERC20, Ownable {

    mapping(address => bool) public allowList;

    modifier onlyAllowListedOrOwner() {
        require(allowList[msg.sender] || owner() == _msgSender(), "Not allowlisted or owner");
        _;
    }

    constructor() ERC20("BUIDLBux", "BUIDL") {
        _mint(address(this), 100000 * 10 ** decimals());
    }

    function decimals() public view virtual override returns (uint8) {
        return 2;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /// Note: only for testing must be changed in production contract
    /// NB: Don't forget to decrement the allocated amount to each Allowlisted address!
    function claim(address to, uint256 amount) public onlyAllowListedOrOwner {
        _transfer(address(this), to, amount);
    }

    function addToAllowList(address[] calldata addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; ++i) {
            allowList[addresses[i]] = true;
        }
    }

    /// @dev Sets the accounts which are vendors
    /// @param vendors The array of accounts allocated to vendors
    function setVendors(address[] calldata vendors) external override onlyOwner {
        for (uint8 i; i < vendors.length; i++) {
            Vendor storage vendor = accounts[vendors[i]];
            vendor.isVendor = true;
        }
    }

    /// @dev Sets the `administrator` that is allowed to make `payments`
    function setAdmin(address admin) external override onlyOwner {
        administrator = admin;
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal override {
        /// Only update if: NOT minting AND NOT from Vendors AND IS a vendor
        /// Token is not burnable, will revert if sending to zero address
        if (
            from != address(0x00) &&
            !accounts[from].isVendor &&
            accounts[to].isVendor
        ) {
            _updateAccounts(to, amount);
        }
    }

    /// @notice BuidlBux-specific accounting
    /// @param targetVendor The vendor receiving tokens
    /// @param amount The amount to increase the vendor's `balanceAccrued`
    function _updateAccounts(address targetVendor, uint256 amount) internal override {
        Vendor storage vendor = accounts[targetVendor];
        vendor.balanceAccrued += amount;
    }
}
