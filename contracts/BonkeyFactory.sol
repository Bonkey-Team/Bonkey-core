// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

import './interfaces/IBonkeyFactory.sol';
import './Project.sol';

contract BonkeyFactory is IBonkeyFactory {
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(Project).creationCode));

    address public feeTo;
    address public feeToSetter;

    mapping(string => mapping(uint => address)) public getPair; // we allow same pair to exist multiple times
    mapping(string => uint) public pairNumber;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function setFeeToSetter() public {
        feeToSetter = msg.sender;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function bytes32ToStr(bytes32 _bytes32) public pure returns (string memory) {
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function getOnePair(address tokenA, address tokenB, uint idx) external view returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(tokenA, tokenB));
        string memory converted = bytes32ToStr(salt);
        return getPair[converted][idx];
    }

    function createProject(address tokenA,
                           address tokenB,
                           uint256 price,
                           uint256 min_rate_to_pass_proposal,
                           uint256 min_rate_to_withdraw,
                           uint256 commission_rate,
                           string  calldata project_meta) external override returns (address pair) {
        require(tokenA != tokenB, 'BonkeyFactory: IDENTICAL_ADDRESSES');
        require(tokenA != address(0), 'BonkeyFactory: ZERO_ADDRESS');
        require(tokenB != address(0), 'BonkeyFactory: ZERO_ADDRESS');
        bytes memory bytecode = type(Project).creationCode;
        bytes32 salt0 = keccak256(abi.encodePacked(tokenA, tokenB));
        string memory converted = bytes32ToStr(salt0);
        uint count = pairNumber[converted];
        bytes32 salt1 = keccak256(abi.encodePacked(tokenA, tokenB, count));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt1)
        }
        IProject(pair).initiate(tokenA, tokenB, price, min_rate_to_pass_proposal,
                                  min_rate_to_withdraw, commission_rate, project_meta);
        getPair[converted][count] = pair;
        allPairs.push(pair);
        pairNumber[converted] = pairNumber[converted] + 1;
        emit PairCreated(tokenA, tokenB, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, 'BonkeyFactory: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, 'BonkeyFactory: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}
