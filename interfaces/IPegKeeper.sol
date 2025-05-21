pragma solidity 0.8.28;

interface IPegKeeper {
    // Events
    event Provide(uint256 amount);
    event Withdraw(uint256 amount);
    event Profit(uint256 lp_amount);
    event CommitNewAdmin(address admin);
    event ApplyNewAdmin(address admin);
    event SetNewActionDelay(uint256 action_delay);
    event SetNewCallerShare(uint256 caller_share);
    event SetNewRegulator(address regulator);

    // View functions
    function factory() external pure returns (address);
    function pegged() external pure returns (address);
    function pool() external pure returns (address);
    function calc_profit() external view returns (uint256);
    function estimate_caller_profit() external view returns (uint256);
    function IS_INVERSE() external view returns (bool);
    function IS_NG() external view returns (bool);
    function regulator() external view returns (address);
    function last_change() external view returns (uint256);
    function debt() external view returns (uint256);
    function caller_share() external view returns (uint256);
    function admin() external view returns (address);
    function future_admin() external view returns (address);
    function new_admin_deadline() external view returns (uint256);
    function receiver() external view returns (address);

    // State changing functions
    function update() external returns (uint256);
    function update(address _beneficiary) external returns (uint256);
    function withdraw_profit() external returns (uint256);
    function set_new_action_delay(uint256 _new_action_delay) external;
    function set_new_caller_share(uint256 _new_caller_share) external;
    function set_new_regulator(address _new_regulator) external;
    function commit_new_admin(address _new_admin) external;
    function apply_new_admin() external;
}
