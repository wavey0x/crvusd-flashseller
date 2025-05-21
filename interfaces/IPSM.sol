pragma solidity 0.8.28;

interface IPSM {
    error InvalidChainlinkRate();
    error InvalidRate();
    error InvalidSwap();
    error InvalidTokens();
    error NotWhitelisted();
    error Paused();
    error ReentrantCall();
    error TooBigAmountIn();
    error TooLate();
    error TooSmallAmountOut();
    event Swap(
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        address indexed from,
        address to
    );

    function quoteIn(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256 amountOut);

    function quoteOut(
        uint256 amountOut,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256 amountIn);

    function swapExactInput(
        uint256 amountIn,
        uint256 amountOutMin,
        address tokenIn,
        address tokenOut,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactInputWithPermit(
        uint256 amountIn,
        uint256 amountOutMin,
        address tokenIn,
        address to,
        uint256 deadline,
        bytes memory permitData
    ) external returns (uint256 amountOut);

    function swapExactOutput(
        uint256 amountOut,
        uint256 amountInMax,
        address tokenIn,
        address tokenOut,
        address to,
        uint256 deadline
    ) external returns (uint256 amountIn);

    function swapExactOutputWithPermit(
        uint256 amountOut,
        uint256 amountInMax,
        address tokenIn,
        address to,
        uint256 deadline,
        bytes memory permitData
    ) external returns (uint256 amountIn);
}