// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library TestLibrary1 {
    function libDo(uint256 n) internal pure returns (uint256) {
        return n * 2;
    }
}

library SafeMath1 {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract TestContractLib1 {
    using TestLibrary1 for uint256;
    using SafeMath1 for uint256;

    function printNumber(uint256 amount) public pure returns (uint256) {
        uint result = amount.libDo();
        uint sub = amount.sub(1);
        uint add = amount.add(1);
        uint div = amount.div(1);
        uint mod = amount.mod(1);
        uint mul = amount.mul(1);
        return result.add(sub).add(add).add(div).add(mod).add(mul);
    }
}

