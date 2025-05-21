// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "interfaces/IPegKeeper.sol";
import "interfaces/ICurvePool.sol";

interface IPSM {
    function swapExactInput(
        uint256 amountIn,
        uint256 minAmountOut,
        address tokenIn,
        address tokenOut,
        address recipient,
        uint256 deadline
    ) external returns (uint256);
}

interface IFlashLender {
    function flashLoan(
        address receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

contract FlashSeller {
    using SafeERC20 for IERC20;

    address public constant FLASH_LENDER = 0x26dE7861e213A5351F6ED767d00e0839930e9eE1;
    address public constant CRVUSD = 0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E;
    IPegKeeper public constant PEG_KEEPER = IPegKeeper(0x503E1Bf274e7a6c64152395aE8eB57ec391F91F8);
    address public constant USDM = 0x59D9356E565Ab3A36dD77763Fc0d87fEaf85508C;
    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
    ICurvePool public constant CRVUSD_POOL = ICurvePool(0x30cE6E5A75586F0E83bCAc77C9135E980e6bc7A8);
    ICurvePool public constant CRVUSD_USDC_POOL = ICurvePool(0x4DEcE678ceceb27446b35C672dC7d61F30bAD69E);
    IPSM public constant ANGLE_PSM = IPSM(0x222222fD79264BBE280b4986F6FEfBC3524d0137);
    address public constant AgUSD = 0x0000206329b97DB379d5E1Bf586BbDB969C63274;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    address public owner;
    mapping(address => bool) public authorized;

    event Authorized(address indexed account, bool authorized);

    modifier onlyAuthorized() {
        require(authorized[msg.sender], "!authorized");
        _;
    }

    constructor() {
        IERC20(CRVUSD).approve(FLASH_LENDER, type(uint256).max);
        IERC20(CRVUSD).approve(address(CRVUSD_POOL), type(uint256).max);
        IERC20(USDC).approve(address(CRVUSD_USDC_POOL), type(uint256).max);
        IERC20(USDM).approve(address(ANGLE_PSM), type(uint256).max);
        IERC20(AgUSD).approve(address(ANGLE_PSM), type(uint256).max);

        owner = msg.sender;
        authorized[msg.sender] = true;
        emit Authorized(msg.sender, true);
    }

    /**
     * @notice Execute a flash loan
     * @param loops The number of times to call update on the Peg Keeper
     * @param amount The amount of crvUSD to flash loan
     */
    function execute(uint256 loops, uint256 amount) external onlyAuthorized {
        require(amount > 0, "amount = 0");
        uint256 pkDebtBefore = PEG_KEEPER.debt();
        IFlashLender(FLASH_LENDER).flashLoan(
            address(this),
            CRVUSD,
            amount,
            abi.encode(loops)
        );
        require(PEG_KEEPER.debt() < pkDebtBefore, "peg keeper debt not reduced");
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        require(initiator == address(this), "!initiator");
        require(msg.sender == FLASH_LENDER, "!flashLender");
        (uint256 loops) = abi.decode(data, (uint256));

        // 1. sell crvUSD into the pool
        uint256 amtUsdm = CRVUSD_POOL.exchange(1, 0, amount, 0);
        // 2. call update on the peg keeper
        for (uint256 i = 0; i < loops; i++) {
            PEG_KEEPER.update();
        }
        // 3. convert assets back to crvUSD
        ANGLE_PSM.swapExactInput(amtUsdm, 0, USDM, AgUSD, address(this), block.timestamp);
        uint256 amtUsdc = ANGLE_PSM.swapExactInput(amtUsdm, 0, AgUSD, USDC, address(this), block.timestamp);
        uint256 amtCrvUsd = CRVUSD_USDC_POOL.exchange(0, 1, amtUsdc, 0);
        IERC20(CRVUSD).transfer(FLASH_LENDER, amount + fee);
        return CALLBACK_SUCCESS;
    }
    

    function setAuthorized(address _account, bool _authorized) external {
        require(msg.sender == owner, "!owner");
        authorized[_account] = _authorized;
        emit Authorized(_account, _authorized);
    }

    function recoverERC20(address token, uint256 amount) external {
        require(msg.sender == owner, "!owner");
        IERC20(token).transfer(owner, amount);
    }
}