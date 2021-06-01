// SPDX-License-Identifier: EtherNaal

pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/AccessControl.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/ERC165.sol";



contract EtherNaalUpdated is ERC721URIStorage, AccessControl{
	//maps tokenIds to item indexes
	using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
	mapping(uint256 => uint256) private itemIndex;
	mapping(uint256 => uint256) private salePrice;
	
    //Setting the minter and admin role 
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
	constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        grantRole(ADMIN_ROLE, msg.sender);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    function setMinter(address minter) public {
        require(hasRole("ADMIN_ROLE", msg.sender) == true, "setMinter: Only admin can set the minter");
        grantRole(MINTER_ROLE, minter);
    }

	function setSale(uint256 tokenId, uint256 price) public {
		address owner = ownerOf(tokenId);
        require(owner != address(0), "setSale: nonexistent token");
        require(owner == msg.sender, "setSale: msg.sender is not the owner of the token");
		salePrice[tokenId] = price;
	}

	function buyTokenOnSale(uint256 tokenId) public payable {
		uint256 price = salePrice[tokenId];
        require(price != 0, "buyToken: price equals 0");
        require(msg.value == price, "buyTokenOnSale: price doesn't equal salePrice[tokenId]");
		address payable owner = payable((ownerOf(tokenId)));
		approve(address(this), tokenId);
		salePrice[tokenId] = 0;
		transferFrom(owner, msg.sender, tokenId);
        owner.transfer(msg.value);
	}

	function mintWithIndex(address to, uint256 index, string memory tokenURI) public  {
        require(hasRole(MINTER_ROLE, msg.sender) == true, "mintWithIndex: Only minters can mint new tokens");
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
		itemIndex[tokenId] = index;
        _mint(to, tokenId);
        
        //Here, we will set the metadata hash link of the token metadata from Pinata
        _setTokenURI(tokenId, tokenURI);
	}
	
	//Return the admin address
    function getAdminAddress() public view returns(bytes32) {
        return getRoleAdmin("ADMIN_ROLE");
    }
    
    //Return the index of a token ID
	function getItemIndex(uint256 tokenId) public view returns (uint256) {
		return itemIndex[tokenId];
	}

    //Return the salePrice
	function getSalePrice(uint256 tokenId) public view returns (uint256) {
		return salePrice[tokenId];
	}
}
