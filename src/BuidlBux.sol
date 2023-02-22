// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
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

    function claim(address to, uint256 amount) public onlyAllowListedOrOwner {
        _transfer(address(this), to, amount);
    }

    function addToAllowList(address[] calldata addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; ++i) {
            allowList[addresses[i]] = true;
        }
    }

    /// Vendor-specific changes
    function setVendors(address[] calldata vendors) external override onlyOwner {
        VendorAccounting.setVendors(vendors);
    }

    function setAdmin(address admin) external override onlyOwner {
        administrator = admin;
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal override {
        /// Only update if:
        /// NOT minting AND
        /// NOT burning AND
        /// NOT from Vendors AND
        /// IS a vendor
        if (
            from != address(0x00) &&
            !accounts[from].isVendor &&
            to != address(0x00) &&
            accounts[to].isVendor
        ) {
            _updateAccounts(vendor, amount);
        }
    }

    /// @notice BuidlBux-specific accounting
    /// @param vendor The target vendor
    /// @param amount The amount to increase the vendor's `balanceAccrued`
    function _updateAccounts(address vendor, uint256 amount) internal override {
        VendorAccounting storage vendor = accounts[vendor];
        vendor.balanceAccrued += amount;
    }
}
