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

    /// The account responsible for paying vendor
    address public administrator;
    /// The accounting linked to vendor accounts
    mapping(address => Vendor) public accounts;

    /// Access control: only `administrator`
    modifier onlyAdmin(address admin) {
        require(msg.sender == admin, "Not allowed");
        _;
    }

    /// @notice Records a payment in `vendor` accounts
    /// @param targetVendor The `vendor` that has been paid
    /// @param amount The amount that was paid to the vendor
    function payoutVendor(address targetVendor) external onlyAdmin {
        Vendor storage vendor = accounts[targetVendor];
        /// Update the amount received and reset the balance
        vendor.totalReceived += amount;
        vendor.balanceAccrued = 0;

        emit Payment(targetVendor, amount);
    }

    /// Intended to be overridden by custom logic in derived contract
    /// Note: place in `_afterTokenTransfer`
    function _updateAccounts(address vendor, uint256 amount) internal virtual {}

    function setAdmin(address admin) public virtual {
        administrator = admin;
        emit AdminSet(admin);
    }

    function setVendors(address[] calldata vendors) public virtual {
        for (uint8 i; i < vendors.length; i++) {
            Vendor storage vendor = accounts[vendors[i]];
            vendor.isVendor = true;
        }
    }
}