// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {ERC721PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/contracts/token/ERC721/ERC721PausableUpgradeable.sol";
import {IPublicSharedMetadata} from "@zoralabs/nft-editions-contracts/contracts/IPublicSharedMetadata.sol";
import {ColorLib} from "./ColorLib.sol";

interface INFT {
    function ownerOf(uint256 tokenId) external view returns (address);
}

/// OrbNFT
/// Design and Project: tw: lily___digital
/// Solidity: tw: isiain, cyrusofeden
/// EDEN DAO LABS
contract OrbNFT is ERC721PausableUpgradeable {
    /// Mapping that stores known marketplace contracts (escrow/auction/staking etc)
    mapping(address => bool) private knownMarketplace;
    /// Last owner lookup to preserve last known zorb while NFT is escrowed
    mapping(uint256 => address) private lastOwner;

    /// Counter keeping track of last minted token id
    Counters.Counter currentTokenId;

    /// Metadata helper library
    IPublicSharedMetadata private immutable sharedMetadata;

    /// Checks if a contract interation is approved or by owner
    modifier onlyApproved(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Only approved");
        _;
    }

    /// Make the Zorb contract
    /// @param _sharedMetadata linked metadata contract
    function init(IPublicSharedMetadata _sharedMetadata) public initializer {
        __ERC721PausableUpgradeable_init("Eden Dao Orb", "ORB");
        sharedMetadata = _sharedMetadata;
        currentTokenId.increment();
    }

    /// Set known marketplace contracts
    /// @param marketPlaces list of addresses
    /// @param isKnown flag if the above marketplaces are known
    function setKnownMarketplaces(address[] calldata marketPlaces, bool isKnown)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < marketPlaces.length; i++) {
            knownMarketplace[marketPlaces[i]] = isKnown;
        }
    }

    /// Simple public mint function
    function mint() public payable whenNotPaused {
        _mint(msg.sender, currentTokenId.current());
        currentTokenId.increment();
    }

    function mintTo(address recipient) public onlyPauser whenNotPaused {
        _mint(recipient, currentTokenId.current());
        currentTokenId.increment();
    }

    /// Number of minted tokens.
    function totalSupply() public view returns (uint256) {
        // starts at 1 then goes to the next token id
        return currentTokenId.current() - 1;
    }

    function gradientForAddress(address user) public pure returns (bytes[5] memory) {
        return ColorLib.gradientForAddress(user);
    }

    /// Public getter for getting the given Zorb for an address
    /// @param user address to get Zorb SVG for
    function orbForAddress(address user) public view returns (string memory) {
        bytes[5] memory colors = gradientForAddress(user);
        string memory encoded = sharedMetadata.base64Encode(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 110 110"><defs>'
                // new gradient fix – test
                '<radialGradient id="gzr" gradientTransform="translate(66.4578 24.3575) scale(75.2908)" gradientUnits="userSpaceOnUse" r="1" cx="0" cy="0%">'
                // '<radialGradient fx="66.46%" fy="24.36%" id="grad">'
                '<stop offset="15.62%" stop-color="',
                colors[0],
                '" /><stop offset="39.58%" stop-color="',
                colors[1],
                '" /><stop offset="72.92%" stop-color="',
                colors[2],
                '" /><stop offset="90.63%" stop-color="',
                colors[3],
                '" /><stop offset="100%" stop-color="',
                colors[4],
                '" /></radialGradient></defs><g transform="translate(5,5)">'
                '<path d="M100 50C100 22.3858 77.6142 0 50 0C22.3858 0 0 22.3858 0 50C0 77.6142 22.3858 100 50 100C77.6142 100 100 77.6142 100 50Z" fill="url(#gzr)" /><path stroke="rgba(0,0,0,0.075)" fill="transparent" stroke-width="1" d="M50,0.5c27.3,0,49.5,22.2,49.5,49.5S77.3,99.5,50,99.5S0.5,77.3,0.5,50S22.7,0.5,50,0.5z" />'
                "</g></svg>"
            )
        );
        return string(abi.encodePacked("data:image/svg+xml;base64,", encoded));
    }

    /// Used to implement known marketplace functionality
    /// @param from token transfer from
    /// @param to token transfer to
    /// @param tokenId token being transferred
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        revert("Orbs are non-transferrable");
        if (knownMarketplace[to]) {
            lastOwner[tokenId] = from;
        }
    }

    /// Determines the actual rendering address instead of just owner address for given zorb id
    /// @param tokenId id of token to get render address for
    function getOrbRenderAddress(uint256 tokenId)
        public
        view
        returns (address)
    {
        address orbFor = INFT(address(this)).ownerOf(tokenId);
        if (knownMarketplace[orbFor] && lastOwner[tokenId] != address(0x0)) {
            orbFor = lastOwner[tokenId];
        }
        return orbFor;
    }

    /// TokenURI function returning on-chain encoded SVG for each Zorb
    /// @param tokenId token id to render
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "No token");

        string memory idString = sharedMetadata.numberToString(tokenId);

        return
            sharedMetadata.encodeMetadataJSON(
                abi.encodePacked(
                    '{"name": "Eden Dao Orb #',
                    idString,
                    unicode'", "description": "Eden Dao Orbs are your key to Eden Dao ecosystem.", "image": "',
                    orbForAddress(getOrbRenderAddress(tokenId)),
                    '"}'
                )
            );
    }
}
