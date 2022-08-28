// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UnikbaseToken is ERC721URIStorage, Ownable {

    event BridgeAuthoritySet(uint indexed chainId,address indexed oldBridgeAuthority,address indexed newBridgeAuthority);

    // Optional mapping for token URIs
    mapping(uint256 => string[]) private _documents;

    // mapping for token owner during bridge
    mapping(uint256 => address) private _targetBridgeOwners; 

    uint[] private _brideChainIds;

    // bridge authorities
    mapping(uint => address) private _bridgeAuthorities;

    constructor() ERC721("SimpleNFT", "SFT") {
    }

    //when minted the token is vaulted until accepted by the recipient
    function mint(address to, uint256 tokenId, string[] memory documents) public onlyOwner {
         _safeMint(to, tokenId);
        _documents[tokenId] = documents;
    }

    //transfer token from another chain to liquichain
    //since token are only mint in liquichain it means this token has been previously transfered to that chain
    function transferFromBridge(uint _fromChainId,address to, uint256 tokenId, string[] memory documents) public {
         uint _chainId;
        assembly {
            _chainId := chainid()
        }
        require(_fromChainId != _chainId, "fromChainId cannot be the current one");
        require(isBridgeAuthority(_fromChainId,msg.sender));
        require(ownerOf(tokenId) == _bridgeAuthorities[_fromChainId],"The token is not in the bridge account.");
        require(_targetBridgeOwners[tokenId] == address(0), "The token is already destinated to an address");
        _targetBridgeOwners[tokenId] = to;
        //FIXME: we should not allow to rewrite the history of documents
        _documents[tokenId] = documents;
    }

    function acceptTransferFromBridge(uint _fromChainId,uint256 tokenId) public {
        require(_targetBridgeOwners[tokenId] == msg.sender,"Invalid transfer.");
        _targetBridgeOwners[tokenId] = address(0);
        _transfer(_bridgeAuthorities[_fromChainId],msg.sender,tokenId);
    }

    // Internal function to check whether specified address is a bridge authority for the given chainId
    // @param fromChainId address need to be checked
    // @param _authority address need to be checked
    // @return whether specified address is an authority
    function isBridgeAuthority(uint _fromChainId,address _authority) public view returns (bool) {
        require(_fromChainId != 0, "ChainId cannot be 0");
        require(_authority != address(0), "Authority address cannot be 0");
        return (_bridgeAuthorities[_fromChainId] == _authority);
    }

    /**
     * @dev Set ownership of the bridge to an account (`bridgeAuthority`) fr the given chainId.
     * Can only be called by the current owner.
     */
    function setBridgeAuthority(uint chainId,address bridgeAuthority) public virtual onlyOwner {
        uint _chainId;
        assembly {
            _chainId := chainid()
        }
        require(bridgeAuthority != address(0), "BridgeAuthority cannot be the zero address");
        require(chainId != _chainId, "ChainId cannot be current chain");
        address oldAuthority = _bridgeAuthorities[chainId];
        _bridgeAuthorities[chainId] = bridgeAuthority;
        emit BridgeAuthoritySet(chainId, oldAuthority,bridgeAuthority);
    }

}
