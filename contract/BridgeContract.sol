pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract bridgeCustody is  ReentrancyGuard {

  event BridgeNFT(address from , uint Id , string uri); 
  event WithdrawnNFT(address from , address to , uint Id); 

  address private Owner ; 
  ERC721 private nft;
  uint256 public Contract_NFTs; 

  modifier onlyOwner {
    require(msg.sender == Owner); 
    _; 
  }

   constructor(ERC721 _nft) {
    Owner = msg.sender; 
    nft = _nft;
  }
  // this is the function that will be called while transferring the Tokens where 
  // the NFT will be burned by emiting an event from that even we are to mint another NFT
  // in a destinated chain with same Token iD 

  function BridgeToken(uint Token_Id) external nonReentrant{
    require(nft.ownerOf(Token_Id) == msg.sender, "you are not the owner of this NFT");
    string memory uri = nft.tokenURI(Token_Id); 
    nft.safeTransferFrom(msg.sender , address(this), Token_Id); 
    Contract_NFTs++; 
    emit BridgeNFT(msg.sender,Token_Id,uri); 
  }
  function WithDrawNFT(address _owner ,uint Token_ID) external nonReentrant {
    nft.safeTransferFrom(address(this),_owner,Token_ID); 
    Contract_NFTs--; 
    emit WithdrawnNFT(address(this),_owner,Token_ID); 
    
  }
  
  function GetTokenAddress() external view onlyOwner returns(address){
    return address(nft); 
  }

  function SetTokenAddress(ERC721 _nft) external onlyOwner {
    nft = _nft ; 
  }
  
}
