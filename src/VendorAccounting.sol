pragma solidity 0.8.18;
/// Simple Vendor Accounting

abstract contract VendorAccounting {
    /// `administrator` has called `payoutVendor`
    event Payment(address indexed vendor, uint256 indexed amountPaid);
    /// `administrator` has been set
    event AdminSet(address indexed admin);

    /// Vendor-related accounting
    struct Vendor {
        uint256 balanceAccrued; // The number of tokens accrued since the last call to `payoutVendor`
        uint256 totalReceived; // The total number of tokens paid to vendor
        bool isVendor; // Flag to make sure vendor is allowed, returns `false` if not Vendor
    }

    /// The account responsible for paying vendors
    address public administrator;
    /// The accounting linked to vendor accounts
    mapping(address => Vendor) public accounts;

    /// Access control: only `administrator`
    modifier onlyAdmin() {
        require(msg.sender == administrator, "Not allowed");
        _;
    }

    /// @notice Records a payment to `vendor` accounts, setting `balanceAccrued` to 0
    /// @param targetVendor The `vendor` that has been paid
    function payoutVendor(address targetVendor) external onlyAdmin {
        Vendor storage vendor = accounts[targetVendor];
        /// Update the amount received and reset the balance
        vendor.totalReceived += vendor.balanceAccrued;
        emit Payment(targetVendor, vendor.balanceAccrued);

        vendor.balanceAccrued = 0;
    }

    /// Intended to be overridden by custom logic in derived contract
    /// Note: place in `_afterTokenTransfer`
    function _updateAccounts(address vendor, uint256 amount) internal virtual {}

    /// Sets the account that makes payments to vendors
    function setAdmin(address admin) external virtual {
        administrator = admin;

        emit AdminSet(admin);
    }

    /// Sets the accounts that need to be monitored
    function setVendors(address[] calldata vendors) external virtual {}
}