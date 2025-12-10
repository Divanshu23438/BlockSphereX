// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title ChainHarbor
 * @notice A secure digital-asset docking protocol for deposits and withdrawals
 * @dev Supports ETH + ERC20 tokens, logs all movements, and ensures safe custody
 */

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract ChainHarbor {
    address public owner;

    enum AssetType { ETH, ERC20 }

    struct Movement {
        address user;
        AssetType assetType;
        address tokenAddress;
        uint256 amount;
        bool isDeposit;      // true = deposit, false = withdrawal
        uint256 timestamp;
        bytes32 movementHash;
    }

    Movement[] public movementLog;

    event AssetDeposited(address indexed user, uint256 amount, AssetType assetType, address token, bytes32 movementHash);
    event AssetWithdrawn(address indexed user, uint256 amount, AssetType assetType, address token, bytes32 movementHash);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // ─────────────────────────────────────────────
    // ⭐ DEPOSIT ETH
    // ─────────────────────────────────────────────
    function depositETH() external payable {
        require(msg.value > 0, "No ETH sent");

        bytes32 movementHash = _generateHash(msg.sender, address(0), msg.value, true);

        movementLog.push(
            Movement(msg.sender, AssetType.ETH, address(0), msg.value, true, block.timestamp, movementHash)
        );

        emit AssetDeposited(msg.sender, msg.value, AssetType.ETH, address(0), movementHash);
    }

    // ─────────────────────────────────────────────
    // ⭐ WITHDRAW ETH
    // ─────────────────────────────────────────────
    function withdrawETH(uint256 amount) external {
        require(amount > 0, "Invalid amount");
        require(address(this).balance >= amount, "Insufficient contract ETH");

        payable(msg.sender).transfer(amount);

        bytes32 movementHash = _generateHash(msg.sender, address(0), amount, false);

        movementLog.push(
            Movement(msg.sender, AssetType.ETH, address(0), amount, false, block.timestamp, movementHash)
        );

        emit AssetWithdrawn(msg.sender, amount, AssetType.ETH, address(0), movementHash);
    }

    // ─────────────────────────────────────────────
    // ⭐ DEPOSIT ERC20 TOKENS
    // ─────────────────────────────────────────────
    function depositERC20(address token, uint256 amount) external {
        require(token != address(0), "Token required");
        require(amount > 0, "Invalid amount");

        IERC20(token).transferFrom(msg.sender, address(this), amount);

        bytes32 movementHash = _generateHash(msg.sender, token, amount, true);

        movementLog.push(
            Movement(msg.sender, AssetType.ERC20, token, amount, true, block.timestamp, movementHash)
        );

        emit AssetDeposited(msg.sender, amount, AssetType.ERC20, token, movementHash);
    }

    // ─────────────────────────────────────────────
    // ⭐ WITHDRAW ERC20 TOKENS
    // ─────────────────────────────────────────────
    function withdrawERC20(address token, uint256 amount) external onlyOwner {
        require(token != address(0), "Token required");
        require(amount > 0, "Invalid amount");

        IERC20(token).transfer(msg.sender, amount);

        bytes32 movementHash = _generateHash(msg.sender, token, amount, false);

        movementLog.push(
            Movement(msg.sender, AssetType.ERC20, token, amount, false, block.timestamp, movementHash)
        );

        emit AssetWithdrawn(msg.sender, amount, AssetType.ERC20, token, movementHash);
    }

    // ─────────────────────────────────────────────
    // ⭐ INTERNAL HELPER
    // ─────────────────────────────────────────────
    function _generateHash(
        address user,
        address token,
        uint256 amount,
        bool isDeposit
    ) internal view returns (bytes32) {
        return keccak256(
            abi.encodePacked(user, token, amount, isDeposit, block.timestamp, block.number)
        );
    }

    // ─────────────────────────────────────────────
    // ⭐ VIEW FUNCTIONS
    // ─────────────────────────────────────────────
    function getMovement(uint256 index) external view returns (Movement memory) {
        return movementLog[index];
    }

    function getTotalMovements() external view returns (uint256) {
        return movementLog.length;
    }

    function getAllMovements() external view returns (Movement[] memory) {
        return movementLog;
    }
}
