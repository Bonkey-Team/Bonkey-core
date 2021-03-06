pragma solidity =0.5.16;

import './interfaces/IBonkeyFactory.sol';
import './Project.sol';

contract BonkeyFactory is IBonkeyFactory {
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(Project).creationCode));

    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor() public {
        feeToSetter = msg.sender;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createProject(address tokenA,
                           address tokenB,
                           uint256 price,
                           uint256 min_rate_to_pass_proposal,
                           uint256 min_rate_to_withdraw,
                           uint256 commission_rate,
                           string  calldata project_meta) external returns (address pair) {
        require(tokenA != tokenB, 'BonkeyFactory: IDENTICAL_ADDRESSES');
        require(tokenA != address(0), 'BonkeyFactory: ZERO_ADDRESS');
        require(tokenB != address(0), 'BonkeyFactory: ZERO_ADDRESS');
        require(getPair[tokenA][tokenB] == address(0), 'BonkeyFactory: PAIR_EXISTS');
        bytes memory bytecode = type(Project).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(tokenA, tokenB));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IProject(pair).initiate(tokenA, tokenB, price, min_rate_to_pass_proposal,
                                  min_rate_to_withdraw, commission_rate, project_meta);
        getPair[tokenA][tokenB] = pair;
        allPairs.push(pair);
        emit PairCreated(tokenA, tokenB, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'BonkeyFactory: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'BonkeyFactory: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}
