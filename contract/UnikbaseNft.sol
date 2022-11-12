// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UnikbaseNFT is ERC721Enumerable, Ownable {

    struct DocumentHash {
        uint256 date;
        string zipHash;
        string jsonHash;
    }
    address private _signer = 0xe89B173880E947A66523112130dA8AaD0eA34424;  

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // mapping for document hashes (by date)
    mapping(uint256 => mapping(uint256 => DocumentHash)) private _documents;
    mapping(uint256 => uint256) private _documentCounts;


    // bridge authorities
    mapping(address => bool) private _bridgeAuthorities;

    constructor() ERC721("UnikBase", "UNB") {
    }

    //when minted the token is vaulted until accepted by the recipient
    function mint(address to,
        uint256 tokenId,
        address _to,
        uint _amount,
        string memory _message,
        uint _nonce,
        bytes memory signature
            ) public {
        require(verify(_signer,_to,_amount,_message,_nonce,signature)); 
         _safeMint(to, tokenId);
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];

        // If  token URI is set, return it.
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }
        // else return the default one
        return super.tokenURI(tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
        require(_exists(tokenId), "Unikbase: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function getDocumentHashes(uint256 tokenId) public view returns (DocumentHash[] memory){
        DocumentHash[] memory ret = new DocumentHash[](_documentCounts[tokenId]);
        for (uint i = 0; i < _documentCounts[tokenId]; i++) {
            ret[i] = _documents[tokenId][i];
        }
        return ret;
    }

    //add a document to the token's document and return its date
    function addDocumentHash(uint256 tokenId,string memory zipHash, string memory jsonHash) public returns(uint256) {
        _requireMinted(tokenId);
        require(bytes(zipHash).length>0,"Unikbase: document zipHash cannot be empty");
        require(bytes(jsonHash).length>0,"Unikbase: document jsonHash cannot be empty");
        require(ERC721.ownerOf(tokenId) == msg.sender, "Unikbase: cannot add document hash form other than token owner");
        uint256 date = block.timestamp;
        //if there are already documents we check that the last one as a date strictly inferior to the current one
        if(_documentCounts[tokenId] > 0){
            require(_documents[tokenId][_documentCounts[tokenId]-1].date < date,"Unikbase: you cannot set document hash twice in the same block, retry later.");
            require(keccak256(bytes(_documents[tokenId][_documentCounts[tokenId]-1].zipHash)) != keccak256(bytes(zipHash)),"Unikbase: the zipHash is the same as the previous zipHash.");
        }
        uint256 index = _documentCounts[tokenId]++;
        _documents[tokenId][index]=DocumentHash(date,zipHash,jsonHash);
        return date;
    }

        /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
     function Burn(address owner, uint id) public {
        require(ownerOf(id) == owner, "you are not the owner of this token"); 
        _burn(id); 
    }
    function _burn(uint256 tokenId) internal virtual override {
        //TODO: make sure the token has not been bridged
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        if ( _documentCounts[tokenId] > 0){
            for (uint i = 0; i < _documentCounts[tokenId]; i++) {
                delete _documents[tokenId][i];
            }
            delete _documentCounts[tokenId];
        }
    }

    /**
     * @dev Set ownership of the bridge to an account (`bridgeAuthority`) fr the given chainId.
     * Can only be called by the current owner.
     */
    function setBridgeAuthority(address bridgeAuthority) public virtual onlyOwner {
        _bridgeAuthorities[bridgeAuthority] = true ; 
    }
    

    function Ishavingpermission(address Authority) public virtual onlyOwner{
        if(_bridgeAuthorities[Authority]!= true){
            revert("you are not having the permisson to bridge"); 
        }
    }
     function getMessageHash(
        address _to,
        uint _amount,
        string memory _message,
        uint _nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _amount, _message, _nonce));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }

    function verify(
        address signer,
        address _to,
        uint _amount,
        string memory _message,
        uint _nonce,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_to, _amount, _message, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == signer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

}
