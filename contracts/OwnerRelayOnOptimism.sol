pragma solidity ^0.5.16;

// Inheritance
import "./interfaces/IOwnerRelay.sol";
import "./MixinResolver.sol";

// Internal references
import "@eth-optimism/contracts/iOVM/bridge/messaging/iAbs_BaseCrossDomainMessenger.sol";

contract OwnerRelayOnOptimism is IOwnerRelay, MixinResolver {
    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */

    bytes32 private constant CONTRACT_EXT_MESSENGER = "ext:Messenger";
    bytes32 private constant CONTRACT_BASE_OWNER_RELAYER_ON_ETHEREUM = "base:OwnerRelayerOnEthereum";

    /* ========== CONSTRUCTOR ============ */

    constructor(address _resolver) internal {
        resolver = AddressResolver(_resolver);
    }

    /* ========== INTERNALS ============ */

    function messenger() internal view returns (iAbs_BaseCrossDomainMessenger) {
        return iAbs_BaseCrossDomainMessenger(requireAndGetAddress(CONTRACT_EXT_MESSENGER));
    }

    function ownerRelayOnEthereum() private view returns (address) {
        return requireAndGetAddress(CONTRACT_BASE_OWNER_RELAYER_ON_ETHEREUM);
    }

    /* ========== VIEWS ========== */

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        addresses = new bytes32[](2);
        addresses[0] = CONTRACT_EXT_MESSENGER;
        addresses[1] = CONTRACT_BASE_OWNER_RELAYER_ON_ETHEREUM;
    }

    /* ========== EXTERNAL ========== */

    function relay(address target, bytes calldata data) external {
        iAbs_BaseCrossDomainMessenger messenger = messenger();

        require(msg.sender == address(messenger), "Sender is not the messenger");
        require(messenger.xDomainMessageSender() == ownerRelayOnEthereum(), "L1 sender is not the owner relayer");

        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory result) = target.call(data);

        require(success, string(abi.encode("xChain call failed:", result)));
    }
}