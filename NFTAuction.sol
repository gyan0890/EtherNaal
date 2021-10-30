// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract EtherNaal is ERC721URIStorage {

    using SafeMath for uint256;
    mapping(uint256 => uint256) private salePrice;
    mapping(address => bool) private creatorWhitelist;
    mapping(address => uint256[]) private ownedTokens;
    mapping(uint256 => uint256) private ownedTokensIndex;
    mapping(uint256 => address) private tokenOwner;
    mapping(uint256 => string) public tokenURIMap;
    mapping(uint256 => address) private tokenApprovals;
    mapping(uint256 => address) private tokenCreator;
    mapping(uint256 => bool) private tokenSold;
    //Holds a mapping between the tokenId and the bidding contract
    mapping(uint256 => Bidding) tokenBids;

    event SalePriceSet(uint256 indexed _tokenId, uint256 indexed _price);
    event Sold(address indexed _buyer, address indexed _seller, uint256 _amount, uint256 indexed _tokenId);
    event WhitelistCreator(address indexed _creator);

    address owner;
    uint256 company_fee;
    address payable ethernaal_org;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    string category;


    modifier onlyMinter() {
        require(creatorWhitelist[msg.sender] == true);
        _;
    }

    modifier notOwnerOf(uint256 _tokenId) {
        require(ownerOf(_tokenId) != msg.sender);
        _;
    }

    modifier onlyOwnerOf(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(string memory _name, 
        string memory _symbol,
        address payable org,
        string memory _category)
        ERC721(_name, _symbol)
    {
        owner = msg.sender;
        company_fee = 3;
        ethernaal_org = org;
        category = _category;
    }

    function getCategory() public view returns (string memory) {
        return category;
    }

    function clearApproval(address _owner, uint256 _tokenId) private {
        require(ownerOf(_tokenId) == _owner);
        tokenApprovals[_tokenId] = address(0);
        emit Approval(_owner, address(0), _tokenId);
    }

    function addToken(address _to, uint256 _tokenId) private {
        require(tokenOwner[_tokenId] == address(0));
        tokenOwner[_tokenId] = _to;
        uint256 length = balanceOf(_to);
        ownedTokens[_to].push(_tokenId);
        ownedTokensIndex[_tokenId] = length;
        _tokenIds.increment();
    }

    function approvedFor(uint256 _tokenId) public view returns (address) {
        return tokenApprovals[_tokenId];
    }

    function getArtistPercentage() public view returns (uint256) {
        uint256 artistPercentage = 100 - company_fee;
        return artistPercentage;
    }

    function setCompanyFee(uint256 _cfee) public onlyOwner returns (bool) {
        company_fee = _cfee;
        return true;
    }

    function getCompanyFee() public view returns (uint256) {
        return company_fee;
    }

    function setSale(uint256 _tokenId, uint256 price) public onlyOwnerOf(_tokenId) {
        address tOwner = ownerOf(_tokenId);
        require(tOwner != address(0), "setSale: nonexistent token");
        salePrice[_tokenId] = price;
        emit SalePriceSet(_tokenId, price);
    }
    
    //BIDDING TIME IS IN SECONDS
    function setAuction(uint256 _tokenId, uint256 reservePrice, uint _biddingTime) public onlyOwnerOf(_tokenId) {
        address tOwner = ownerOf(_tokenId);
        require(tOwner != address(0), "setSale: nonexistent token");
        salePrice[_tokenId] = reservePrice;

        uint256 artistPercentage = getArtistPercentage();
        uint256 companyPercentage = getCompanyFee();
        
        Bidding placeBids = new Bidding(_tokenId, _biddingTime, reservePrice, payable(tOwner), payable(ethernaal_org), artistPercentage, companyPercentage);
        tokenBids[_tokenId] = placeBids;
        emit SalePriceSet(_tokenId, reservePrice);
    }
    
    function transferNFT(uint256 _tokenId, address _nftAddress) public {
        require(msg.sender == ethernaal_org, "Only admin can call this function");
        ERC721 nftAddress = ERC721(_nftAddress);
        address tOwner = ownerOf(_tokenId);
        
        address receiver = tokenBids[_tokenId].highestBidder();
        nftAddress.safeTransferFrom(tOwner, receiver, _tokenId);
        
    }

    function getBidContractAddress(uint256 _tokenId) public view returns(address){
        return address(tokenBids[_tokenId]);
    }
    
    function buyTokenOnSale(uint256 tokenId, address _nftAddress)
        public
        payable
    {
        ERC721 nftAddress = ERC721(_nftAddress);

        uint256 price = salePrice[tokenId];
        require(price != 0, "buyToken: price equals 0");
        require(
            msg.value == price,
            "buyToken: price doesn't equal salePrice[tokenId]"
        );
        address tOwner = ownerOf(tokenId);

        salePrice[tokenId] = 0;

        nftAddress.transferFrom(tOwner, msg.sender, tokenId);

        ownedTokens[tOwner][ownedTokensIndex[tokenId]] = 0;
        ownedTokens[msg.sender].push(tokenId);
        uint256 artistPercentage = getArtistPercentage();
        uint256 artistBalance = (msg.value * artistPercentage * 1) / 100;

        payable(tOwner).transfer(artistBalance);
        uint256 companyBalance = (getCompanyFee() * msg.value * 1) / 100;
        ethernaal_org.transfer(companyBalance);
    }

    //function mintWithIndex(address to, string memory tokenURI) public {
    function mintWithIndex(address _creator, string memory _tokenURI)
        public onlyMinter
        returns (uint256 _tokenId)
    {
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        tokenOwner[tokenId] = _creator;
        uint256 length = balanceOf(_creator);
        ownedTokens[_creator].push(tokenId);
        ownedTokensIndex[tokenId] = length;
        tokenCreator[tokenId] = _creator;
        _mint(_creator, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        tokenURIMap[tokenId] = _tokenURI;
        tokenCreator[tokenId] = _creator;

        return tokenId;
    }

    function tokensOf(address _owner) public view returns (uint256[] memory) {
        return ownedTokens[_owner];
    }

    function whitelistCreator(address _creator) public onlyOwner {
        creatorWhitelist[_creator] = true;
        emit WhitelistCreator(_creator);
    }

    function getSalePrice(uint256 tokenId) public view returns (uint256) {
        return salePrice[tokenId];
    }

    function isWhitelisted(address _creator) external view returns (bool) {
        return creatorWhitelist[_creator];
    }

    function creatorOfToken(uint256 _tokenId) public view returns (address) {
        return tokenCreator[_tokenId];
    }

    function getTokenURI(uint256 _tokenId)
        external
        view
        returns (string memory)
    {
        return tokenURIMap[_tokenId];
    }

    function totalSupply() public view virtual returns (uint256) {
        return _tokenIds.current();
    }
}

contract Bidding {
    // Parameters of the auction. Times are either
    // absolute unix timestamps (seconds since 1970-01-01)
    // or time periods in seconds.

    uint public auctionEnd;
    uint public tokenId;
    uint public reservePrice;
    uint bidCounter;
    address public highestBidAddress;
    uint public highestBid;
    address public admin;
    address public nftOwner;
    uint256 sellerPercentage;
    uint256 platformPercentage;

    uint[] public sortedBids;
    address[] public sortedBidders;

    struct Bid {
        address payable bidder;
        uint bidAmount;
    }
   
    // Set to true at the end, disallows any change
    bool ended;
    
    // Recording all the bids
    mapping(uint => Bid) bids;


    // Events that  will be fired on changes.
    //event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    /*
    * Create a simple bidding contract
    * @param _tokenId: tokenId for which the bid is created
    * @param _biddingTime: Time period for the bidding to be kept open
    * @param _reservePrice: Minimum price set for the token
    */
    constructor(
       
        uint256 _tokenId,
        uint _biddingTime,
        uint _reservePrice,
        address payable _nftOwner,
        address payable _admin,
        uint256 _sellerPercentage,
        uint256 _platformPercentage
    ) {
        reservePrice = _reservePrice;
        tokenId = _tokenId;
        bidCounter = 0;
        auctionEnd = block.timestamp + _biddingTime;
        //Explicitly setting the owner to our address for now
        // msg.sender is coming as the address of the contract
        nftOwner = _nftOwner;
        admin = _admin;
        sellerPercentage = _sellerPercentage;
        platformPercentage = _platformPercentage;
        
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
    
    //ONLY FOR TESTING
    function getAdmin() public view returns(address){
      return admin;
    }   

    /// Bid on the auction with the value sent
    /// together with this transaction.
    /// The value will only be refunded if the
    /// auction is not won.
    function bid() public payable {
        // No arguments are necessary, all
        // information is already part of
        // the transaction. The keyword payable
        // is required for the function to
        // be able to receive Ether.

        // Revert the call if the bidding
        // period is over.
        require(
            block.timestamp <= auctionEnd,
            "Auction already ended."
        );

        // If the bid is not higher than the reservePrice, send the
        // money back.
        require(
            msg.value > 0,
            "You cannot bid 0 as the price."
        );

        if(sortedBids.length != 0) {
            require(msg.value > sortedBids[sortedBids.length -1], "Bid value should be greeater than current highest bid");
        }

       Bid storage newBid = bids[bidCounter+1];
       newBid.bidder = payable(msg.sender);
       newBid.bidAmount = msg.value;
       
       sortedBids.push(msg.value);
       sortedBidders.push(msg.sender);
       
       bidCounter = bidCounter+1;
    }
    
    /*
    * Get the address of the highest bidder
    */
    /*
    * Get the address of the highest bidder
    */
    function highestBidder() public view returns(address) {
        
        require(sortedBidders.length > 0, "No bids yet");
        return sortedBidders[sortedBidders.length - 1];
        
    }
    
    
    /*
    * Get the highest bid amount
    */
    function highestBidAmount() public view returns(uint)  {
        
        require(sortedBids.length > 0, "No bids yet");
        return sortedBids[sortedBids.length - 1];
    }

    
    
    /*
    * Withdraw bids that were not the winners.
    */
    function disperseFunds() onlyAdmin public returns (bool) {
        require(block.timestamp >= auctionEnd, "Auction not yet ended.");
        require(ended, "Auction end has not been called.");
        uint amount = 0;
        for(uint i = 0; i <= bidCounter; i ++){
            amount = bids[i].bidAmount;
            
            if(amount < 0){
                return false;
            }
          
            if(bids[i].bidder != highestBidAddress){
                
                bids[i].bidder.transfer(amount);
            }
            
        }
        return true;
    }
    
    /*
    * In case of an emergency, this function can be called to send all
    * the funds from the contract to the owner address.
    */
    function finalize() onlyAdmin public  {
        selfdestruct(payable(admin));
    }
    
    
    /* 
    * @param _charity - Address of the charity organisation chosen by the NFT Owner
    * End the auction and send the highest bid to the nftOwner.
    */
    function closeAuction() onlyAdmin public {

        // 1. Conditions
        require(block.timestamp >= auctionEnd, "Auction not yet ended.");
        require(!ended, "auctionEnd has already been called.");

        // 2. Effects
        ended = true;

        // 3. Get the highest bidder 
        highestBidAddress = highestBidder();
        
         //4. Send the money to the owner and the charity
        highestBid = highestBidAmount();

        uint sellerShare = highestBidAmount()*(sellerPercentage/100);
        uint platformShare = highestBidAmount()*(platformPercentage/100);
        
        payable(nftOwner).transfer(sellerShare);
        payable(admin).transfer(platformShare);
        
    }

    function geReservePrice() onlyAdmin  public view returns(uint){
      return reservePrice;
    }

    function getHighestBid() onlyAdmin public view returns(uint){
      require(ended, "Auction end has not been called.");
      return highestBid;
    }

}
