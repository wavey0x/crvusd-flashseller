// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {FlashSeller} from "src/FlashSeller.sol";
import {IPegKeeper} from "interfaces/IPegKeeper.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ICurvePool} from "interfaces/ICurvePool.sol";

contract FlashSellerTest is Test {
    uint256 public constant AMOUNT_TO_FLASH = 118_000e18;
    uint256 public constant LOOPS = 29;
    FlashSeller public flashSeller = new FlashSeller();
    IPegKeeper public pegKeeper;
    IERC20 public crvUsd = IERC20(0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E);
    ICurvePool public immutable POOL = ICurvePool(0x30cE6E5A75586F0E83bCAc77C9135E980e6bc7A8);

    function setUp() public {
        flashSeller = new FlashSeller();
        pegKeeper = IPegKeeper(flashSeller.PEG_KEEPER());
        vm.prank(pegKeeper.admin());
        pegKeeper.set_new_action_delay(0);
    }

    function test_FlashLoan() public {
        uint256 pkDebtBefore = pegKeeper.debt();
        uint256 initialBalance = 50_000e18;
        deal(address(crvUsd), address(flashSeller), initialBalance);
        flashSeller.execute(LOOPS, AMOUNT_TO_FLASH);
        uint256 finalBalance = crvUsd.balanceOf(address(flashSeller));
        uint256 pkDebtAfter = pegKeeper.debt();
        uint256 diff = pkDebtBefore - pkDebtAfter;
        console.log("Reduction in pegkeeper debt", diff/1e18);
        console.log("Remaining pegkeeper debt", pkDebtAfter/1e18);
        console.log("Losses", (initialBalance - finalBalance)/1e18);
        assertGt(diff, 0);
    }
}
