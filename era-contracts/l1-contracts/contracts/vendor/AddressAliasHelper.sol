// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2019-2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
// We use a floating point pragma here so it can be used within other projects that interact with the ZKsync ecosystem without using our exact pragma version.
pragma solidity ^0.8.21;

library AddressAliasHelper {
    uint160 private constant offset = uint160(0x1111000000000000000000000000000000001111);

    /// @notice Utility function converts the address that submitted a tx
    /// to the inbox on L1 to the msg.sender viewed on L2
    /// @param l1Address the address in the L1 that triggered the tx to L2
    /// @return l2Address L2 address as viewed in msg.sender
    function applyL1ToL2Alias(address l1Address) internal pure returns (address l2Address) {
        unchecked {
            l2Address = address(uint160(l1Address) + offset);
        }
    }

    /// @notice Utility function that converts the msg.sender viewed on L2 to the
    /// address that submitted a tx to the inbox on L1
    /// @param l2Address L2 address as viewed in msg.sender
    /// @return l1Address the address in the L1 that triggered the tx to L2
    function undoL1ToL2Alias(address l2Address) internal pure returns (address l1Address) {
        unchecked {
            l1Address = address(uint160(l2Address) - offset);
        }
    }

    /// @notice Utility function used to calculate the correct refund recipient
    /// @param _refundRecipient the address that should receive the refund
    /// @param _originalCaller the address that triggered the tx to L2
    /// @return _recipient the corrected address that should receive the refund
    function actualRefundRecipient(
        address _refundRecipient,
        address _originalCaller
    ) internal view returns (address _recipient) {
        if (_refundRecipient == address(0)) {
            // If the `_refundRecipient` is not provided, we use the `_originalCaller` as the recipient.
            // solhint-disable avoid-tx-origin
            // slither-disable-next-line tx-origin
            _recipient = _originalCaller == tx.origin
                ? _originalCaller
                : AddressAliasHelper.applyL1ToL2Alias(_originalCaller);
            // solhint-enable avoid-tx-origin
        } else if (_refundRecipient.code.length > 0) {
            // If the `_refundRecipient` is a smart contract, we apply the L1 to L2 alias to prevent foot guns.
            _recipient = AddressAliasHelper.applyL1ToL2Alias(_refundRecipient);
        } else {
            _recipient = _refundRecipient;
        }
    }
}