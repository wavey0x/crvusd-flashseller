// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {FlashSeller} from "src/FlashSeller.sol";
import {IPegKeeper} from "interfaces/IPegKeeper.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ICurvePool} from "interfaces/ICurvePool.sol";

contract FlashSellerTest is Test {
    FlashSeller public flashSeller;
    IPegKeeper public pegKeeper;
    IERC20 public crvUsd;
    uint256 public AMOUNT_TO_FLASH = 150_000e18;
    ICurvePool public immutable POOL = ICurvePool(0x30cE6E5A75586F0E83bCAc77C9135E980e6bc7A8);

    function setUp() public {
        flashSeller = new FlashSeller();
        pegKeeper = IPegKeeper(flashSeller.PEG_KEEPER());
        vm.prank(pegKeeper.admin());
        pegKeeper.set_new_action_delay(0);
        crvUsd = IERC20(flashSeller.CRVUSD());
    }

    function test_FlashLoan() public {
        uint256 pegkeeperBalance = POOL.balanceOf(address(pegKeeper));
        uint256 initialBalance = 100e18;
        deal(address(crvUsd), address(flashSeller), initialBalance);
        flashSeller.execute(4, AMOUNT_TO_FLASH);
        uint256 finalBalance = crvUsd.balanceOf(address(flashSeller));
        uint256 pegkeeperBalanceAfter = POOL.balanceOf(address(pegKeeper));
        uint256 diff = pegkeeperBalance - pegkeeperBalanceAfter;
        console.log("Reduction in pegkeeper balance", diff/1e18);
        console.log("Remaining pegkeeper balance", pegkeeperBalanceAfter/1e18);
        console.log("Losses", (initialBalance - finalBalance)/1e18);
        assertGt(diff, 0);
    }
}
