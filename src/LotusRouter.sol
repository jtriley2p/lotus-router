// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.28;

import { Action } from "src/types/Action.sol";
import { Error } from "src/types/Error.sol";
import { Ptr, findPtr } from "src/types/PayloadPointer.sol";

// +---------------------------------------------------------------------------+
// | ## The Lotus Router Manifesto                                             |
// |                                                                           |
// | I am the Lotus Router.                                                    |
// |                                                                           |
// | I exist for the individual.                                               |
// | I exist for the collective.                                               |
// | I exist for the developers.                                               |
// | I exist for the users.                                                    |
// |                                                                           |
// | I exist, above all else, to empower.                                      |
// |                                                                           |
// | I do not to extract value.                                                |
// | I do not to capture rent.                                                 |
// | I am a political statement, as all software is.                           |
// |                                                                           |
// | I subscribe to no -ism.                                                   |
// | I wave no banner.                                                         |
// | I am an act of defiance against hoarders of technology and capital.       |
// |                                                                           |
// | I bear the license of free, as in cost AND freedom, software.             |
// | I am free for distribution.                                               |
// | I am free for study.                                                      |
// | I am free for modification.                                               |
// | I am free for redistribution.                                             |
// |                                                                           |
// | I ask only that redistributions of me bear the same license.              |
// |                                                                           |
// |                                ___                                        |
// |                          ___  / | \  ___                                  |
// |                         / / \/  |  \/ \ \                                 |
// |                        / /   \ ___ /   \ \                                |
// |                        \ \    / | \    / /                                |
// |                      ,-----,/   |   \,-----,                              |
// |                      \ \    \   |   /    / /                              |
// |                       \ \    \  |  /    / /                               |
// |                     __-\_\____\ | /____/_/-__                             |
// |                    '--___      '-'      ___--'                            |
// |                          '----_____----'                                  |
// +---------------------------------------------------------------------------+

/// @title Lotus Router
/// @author Nameless Researchers and Developers of Ethereum
contract LotusRouter {
    // ## Fallback Function
    //
    // This contains all of the Lotus Router's execution logic.
    //
    // We use the fallback function to eschew Solidity's cannonical encoding
    // scheme. Documentation will be provided for interfacing with this safely.
    //
    // > TODO: Provide documentation for interfacing with this safely.
    fallback() external payable {
        Ptr ptr = findPtr();
        bool success = true;

        while (success) {
            Action action;

            (ptr, action) = ptr.nextAction();

            if (action == Action.Halt) break;

            (ptr, success) = action.execute(ptr);
        }

        if (!success) revert Error.CallFailure();
    }

    // ## Receiver Function
    //
    // This triggers when this contract is called with no calldata. It takes no
    // action, it only returns gracefully.
    receive() external payable { }
}
