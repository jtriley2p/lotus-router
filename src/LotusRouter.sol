// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

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
// | I ask only that you retain the license of freedom software.               |
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
contract LotusRouter {
    fallback() external payable {
        unchecked {
            Ptr ptr = findPtr();

            while (true) {
                Action action;

                (ptr, action) = ptr.nextAction();

                if (action == Action.Halt)
                    break;

                // TODO: draw the rest of the owl
                break;
            }
        }
    }

    // ## Receiver Function
    //
    // This triggers when this contract is called with no calldata. It takes no
    // action, it only returns gracefully.
    receive() external payable {}
}
