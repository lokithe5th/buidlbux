// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/BuidlBux.sol";

contract BuidlBuxTest is Test {
    BuidlBux public buidlbux;
    address public administrator;
    mapping(address => uint256) public testAccounting;

    function setUp() public {
        buidlbux = new BuidlBux();
        //address[] memory vendors = [address(1), address(2), address(3)];
        //address[] memory allowList = [address(10), address(11), address(12), address(13)];
    }

    function testSetVendors(address[] calldata vendors) public {
        buidlbux.setVendors(vendors);
    }

    function testSetAdmin() public {
        buidlbux.setAdmin(administrator);
    }

    function testSetAllowList(address[] calldata allowList) public {
        buidlbux.addToAllowList(allowList);
    }

    function testClaim(address[] calldata allowList) public {
        uint256 testAmount = 10 * 10**2;
        testSetAllowList(allowList);

        for (uint8 i; i < allowList.length; i++) {
            if (allowList[i] != address(0)) {
                vm.prank(allowList[i]);
                buidlbux.claim(allowList[i], testAmount);
            }
        }
    }

    function testSendToVendor(address[] calldata vendors) public {
        uint256 testAmount = 10 * 10 **2;

        buidlbux.setVendors(vendors);
        //buidlbux.mint(address(1), testAmount);

        for (uint8 i; i < vendors.length; i++) {
            buidlbux.mint(address(this), testAmount);
            if (vendors[i] != address(0)) {
                buidlbux.transfer(vendors[i], testAmount);
                testAccounting[vendors[i]] += testAmount;

                (uint256 accounting, , ) = buidlbux.accounts(vendors[i]);
                assertEq(accounting, testAccounting[vendors[i]]);
            }
        }
    }

    function testPayout(address[] calldata vendors) public {
        for (uint8 i; i < vendors.length; i++) {
            delete testAccounting[vendors[i]];
        }

        testSetAdmin();
        testSendToVendor(vendors);

        for (uint8 i; i < vendors.length; i++) {
            if (vendors[i] != address(0)) {
                vm.prank(administrator);
                buidlbux.payoutVendor(vendors[i]);
                (uint256 accounting, uint256 claimed, ) = buidlbux.accounts(vendors[i]);
                assertEq(accounting, 0);
                assertEq(claimed, testAccounting[vendors[i]]);
            }
        }
    }


}
