// SPDX-License-Identifier: EtherNaal

pragma solidity >=0.6.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract EtherNaal is ERC721URIStorage{
		mapping(uint256 => uint256) private salePrice;
	    mapping(address => bool) private creatorWhitelist;
	    mapping (address => uint256[]) private ownedTokens;
        mapping(uint256 => uint256) private ownedTokensIndex;
        mapping (uint256 => address) private tokenOwner;
        mapping(uint256 => string) public tokenURIMap;
         
	    address owner;
	    uint256 company_fee;
	    address payable ethernaal_org;
	    using Counters for Counters.Counter;
        Counters.Counter private _tokenIds;
        string category;

    event WhitelistCreator(address indexed _creator);

	modifier onlyMinter() {
        require(creatorWhitelist[msg.sender] == true);
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
	
  //Setting the MINTER_ROLE as onlyMinter is deprecated 
  //in the recent Solidity releases
  //bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

	constructor(string memory _name, string memory _symbol, address payable org, string memory _category) ERC721(_name, _symbol) {
    owner = msg.sender;
    company_fee = 3;
    ethernaal_org = org;
    category = _category;
    //Upwards of 0.8.0 - setBaseURI needs to be overridden, so removing this.
    // _setBaseURI("https://gateway.pinata.cloud/ipfs/");
    }

    function getCategory() public view returns(string memory) {
        return category;    
    }
    
	function setSale(uint256 tokenId, uint256 price) public {
		address tOwner = ownerOf(tokenId);
        require(tOwner != address(0), "setSale: nonexistent token");
        require(tOwner == msg.sender, "setSale: msg.sender is not the owner of the token");
		salePrice[tokenId] = price;
	}

	function buyTokenOnSale(uint256 tokenId) public payable {
		uint256 price = salePrice[tokenId];
        require(price != 0, "buyToken: price equals 0");
        require(msg.value == price, "buyToken: price doesn't equal salePrice[tokenId]");
		address tOwner = ownerOf(tokenId);
		approve(address(this), tokenId);
		salePrice[tokenId] = 0;
		
		transferFrom(tOwner, msg.sender, tokenId);
		uint256 artistPercentage = 100-company_fee;
		uint256 artistBalance = (1 ether * 0.01) * msg.value* artistPercentage;
        payable(tOwner).transfer(artistBalance);
        
        uint256 companyBalance = (1 ether*0.01)*company_fee*msg.value;
        ethernaal_org.transfer(companyBalance);
	}
	
	// This line is only for my localtest
	//function mintWithIndex(address to, string memory tokenURI) public { 
	function mintWithIndex(address to, string memory _tokenURI) public onlyMinter returns(uint256 _tokenId) {
	    _tokenIds.increment();
		uint256 tokenId = _tokenIds.current();
		tokenOwner[tokenId] = to;
        uint256 length = balanceOf(to);
        ownedTokens[to].push(tokenId);
        ownedTokensIndex[tokenId] = length;
        _mint(to, tokenId);     
        _setTokenURI(tokenId, _tokenURI);
        tokenURIMap[tokenId] = _tokenURI;
        
        return tokenId;
	}

    function tokensOf(address _owner) public view returns (uint256[] memory) {
        return ownedTokens[_owner];
    }
    
	function whitelistCreator(address _creator) public onlyOwner {
      creatorWhitelist[_creator] = true;
      WhitelistCreator(_creator);
    }
	
	function getSalePrice(uint256 tokenId) public view returns (uint256) {
		return salePrice[tokenId];
	}

    function isWhitelisted(address _creator) external view returns (bool) {
      return creatorWhitelist[_creator];
    }
    
     function getTokenURI(uint256 _tokenId) external view returns (string memory) {
        return tokenURIMap[_tokenId];
    }
}
