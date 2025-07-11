// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PromotiumSBT is ERC721, Ownable {
    /* @notice This is the SBT Contract for Promotium Platform, SBT is only provided to 
      valdiators for their social identificaton, It is revoked when they resign from their role*/

    string public tokenuri;

    uint tokenID;

    /// @notice error emitted when someone access disabled functions
    error NotAllowed();

    event SBTAllocated(address indexed validator, uint tokenId);

    event SBTRevoked(address indexed validator, uint tokenId);

    constructor() ERC721("Promotium Validator", "PV") Ownable(msg.sender) {
        tokenID = 0;
    }

    /// @notice set token Uri, Only Owner can call this.
    /// @param _uri string token Uri.
    function setTokenURI(string memory _uri) external onlyOwner {
        tokenuri = _uri;
    }

    /// @notice getter function for token Uri.
    /// @dev Every tokenId have same metadata
    /// @param tokenId is not used in the function, required by base contract to override
    function tokenURI(
        uint tokenId
    ) public view override returns (string memory) {
        return tokenuri;
    }

    /// @notice Allocates SBT to a Validator, only contract owner can call
    /// @param _validator is Validator address.
    function allocateSBT(address _validator) public onlyOwner {
        _mint(_validator, ++tokenID);
        emit SBTAllocated(_validator, tokenID);
    }

    /// @notice Revokes SBT from a Validator, only contract owner can call.
    /// @param _tokenId SBT token ID.
    /// @param _validator is Validator address, used for emiting event.
    function revokeSBT(uint _tokenId, address _validator) public onlyOwner {
        _burn(_tokenId);
        emit SBTRevoked(_validator, _tokenId);
    }

    ///@notice disabled overrided transferFrom function from base contract.
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        revert NotAllowed();
    }

    ///@notice disabled overrided safeTransferFrom function from base contract.
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override {
        revert NotAllowed();
    }

    ///@notice disabled overrided setApprovalForAll function from base contract.
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override {
        revert NotAllowed();
    }

    ///@notice disabled overrided approve function from base contract.
    function approve(address to, uint256 tokenId) public override {
        revert NotAllowed();
    }
}
