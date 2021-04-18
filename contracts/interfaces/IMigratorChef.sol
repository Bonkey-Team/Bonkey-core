// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

import './IBEP20.sol';

interface IMigratorChef {
    function migrate(IBEP20 token) external returns (IBEP20);
}
