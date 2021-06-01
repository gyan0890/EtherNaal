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
	mapping(uint256 => uint256) private salePrice;
	uint256 company_fee;
	address payable ethernaal_org;
	
    //Setting the minter and admin role 
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
	constructor(string memory _name, string memory _symbol, address payable org) ERC721(_name, _symbol) {
        grantRole(ADMIN_ROLE, msg.sender);
        company_fee = 3;
        ethernaal_org = org;
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
	    require(ethernaal_org != address(0), "buyTokenOnSale: Organisation address cannot be empty");
		uint256 price = salePrice[tokenId];
        require(price != 0, "buyToken: price equals 0");
        require(msg.value == price, "buyTokenOnSale: price doesn't equal salePrice[tokenId]");
		address payable owner = payable((ownerOf(tokenId)));
		approve(address(this), tokenId);
		salePrice[tokenId] = 0;
		transferFrom(owner, msg.sender, tokenId);
		uint256 artistPercentage = 100-company_fee;
		uint256 artistBalance = (1 ether * 0.01) * msg.value* artistPercentage;
        owner.transfer(artistBalance);
        
        uint256 companyBalance = (1 ether*0.01)*company_fee*msg.value;
        ethernaal_org.transfer(companyBalance);
        
        
	}
    
    function setFees(uint256 fees) public {
        require(hasRole(MINTER_ROLE, msg.sender) == true, "setFees: Only admin can set the fees");
        require(fees < 100, "setFees: Company fees is in percentage, cannot be greater than 100");
        company_fee = fees;
    }
    
	function mintWithIndex(address to, string memory tokenURI) public  {
        require(hasRole(MINTER_ROLE, msg.sender) == true, "mintWithIndex: Only minters can mint new tokens");
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        _mint(to, tokenId);
        
        //Here, we will set the metadata hash link of the token metadata from Pinata
        _setTokenURI(tokenId, tokenURI);
	}
	
	//Return the admin address
    function getAdminAddress() public view returns(bytes32) {
        return getRoleAdmin("ADMIN_ROLE");
    }
    

    //Return the salePrice
	function getSalePrice(uint256 tokenId) public view returns (uint256) {
		return salePrice[tokenId];
	}
}
