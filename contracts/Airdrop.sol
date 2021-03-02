pragma solidity =0.5.16;

import './interfaces/IBEP20.sol';

contract AirDrop {

    function do_air_drop(address token, address[] recipients) {
        for (uint i=0; i<recipients.length; i++) {
            IBEP20(token).transferFrom(msg.sender, recipients[i], amount);
        }
    }
}
