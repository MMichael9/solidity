pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Staking {
    address public owner;
    uint public currentTokenId = 1;

    struct Token {
        uint tokenId;
        string name;
        string symbol;
        address tokenAddress;
        uint usdPrice;
        uint ethPrice;
        uint apy;
    }

    struct Position {
        uint positionId;
        address wallet;
        string name;
        string symbol;
        uint createdDate;
        uint apy;
        uint tokenQuantity;
        uint usdValue;
        uint ethValue;
        bool open;
    }

    uint public ethUsdPrice;
    string[] public tokenSymbols;
    mapping(string => Token) public tokens;

    uint public currentPositionId = 1;
    mapping(uint => Position) public positions;

    mapping(address => uint[]) public positionIdsByAddress;

    mapping(string => uint) public stakedTokens;

    constructor(uint currentEthPrice) payable {
        owner = msg.sender;
        ethUsdPrice = currentEthPrice;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner!");
        _;
    }

    function addToken(
        string calldata _name, 
        string calldata _symbol, 
        address _tokenAddress,
        uint _usdPrice,
        uint _apy
        ) external onlyOwner {

            tokenSymbols.push(_symbol);

            tokens[_symbol] = Token(
                currentTokenId,
                _name,
                _symbol,
                _tokenAddress,
                _usdPrice,
                _usdPrice / ethUsdPrice,
                _apy
            );

            currentTokenId++;
    }

    function getTokenSymbols() public view returns(string[] memory) {
        return tokenSymbols;
    }

    function getToken(string calldata _tokenSymbol) public view returns(Token memory) {
        return tokens[_tokenSymbol];
    }

    function stake(string calldata _tokenSymbol, uint _tokenQuantity) external {
        require(tokens[_tokenSymbol].tokenId != 0, "This token is not supported!");

        IERC20(tokens[_tokenSymbol].tokenAddress).transferFrom(msg.sender, address(this), _tokenQuantity);

        positions[currentPositionId] = Position(
            currentPositionId,
            msg.sender, 
            tokens[_tokenSymbol].name,
            _tokenSymbol,
            block.timestamp,
            tokens[_tokenSymbol].apy,
            _tokenQuantity,
            tokens[_tokenSymbol].usdPrice * _tokenQuantity,
            (tokens[_tokenSymbol].usdPrice * _tokenQuantity) / ethUsdPrice,
            true

        );

        positionIdsByAddress[msg.sender].push(currentPositionId);
        currentPositionId+=1;
        stakedTokens[_tokenSymbol] += _tokenQuantity;
    }

    function getPositionIdsByAddress() external view returns (uint[] memory) {
        return positionIdsByAddress[msg.sender];
    }

    function getPositionById(uint _positionId) external view returns(Position memory) {
        return positions[_positionId];
    }

    function calculateInterest(uint _apy, uint _value, uint _numdays) public pure returns(uint) {
        return _apy * _value * _numdays / 10000 / 365;
    }

    function closePosition(uint _positionId) external {
        require(positions[_positionId].wallet == msg.sender, "You do not own this position!");
        require(positions[_positionId].open == true, "You already closed this position!");

        positions[_positionId].open = false;
        
        IERC20(tokens[positions[_positionId].symbol].tokenAddress).transfer(msg.sender, positions[_positionId].tokenQuantity);

        uint daysPassed = calculateNumberOfDays(positions[_positionId].createdDate);

        uint weiAmount = calculateInterest(
            positions[_positionId].apy,
            positions[_positionId].ethValue,
            daysPassed
        );

        payable(msg.sender).call{value: weiAmount}("");
    }

    function calculateNumberOfDays(uint _createdDate) public view returns(uint) {
        return (block.timestamp - _createdDate) / 60 / 60 / 24;
    }

    // Helper function for testing (this would not be good in production :(
    function modifyCreatedDate(uint _positionId, uint _newCreatedDate) public onlyOwner {
        positions[_positionId].createdDate = _newCreatedDate;
    }
}