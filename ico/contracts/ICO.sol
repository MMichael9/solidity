//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;
// ----------------------------------------------------------------------------
// EIP-20: ERC-20 Token Standard
// https://eips.ethereum.org/EIPS/eip-20
// -----------------------------------------

interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);
    
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract Cryptos is ERC20Interface{
    string public name = "Cryptos";
    string public symbol = "CRPT";
    uint public decimals = 0; //18 is very common
    uint public override totalSupply;
    
    address public founder;
    mapping(address => uint) public balances;
    // balances[0x1111...] = 100;
    
    mapping(address => mapping(address => uint)) allowed;
    // allowed[0x111][0x222] = 100;
    
    
    constructor(){
        totalSupply = 1000000;
        founder = msg.sender;
        balances[founder] = totalSupply;
    }
    
    
    function balanceOf(address tokenOwner) public view override returns (uint balance){
        return balances[tokenOwner];
    }
    
    
    function transfer(address to, uint tokens) public override returns(bool success){
        require(balances[msg.sender] >= tokens);
        
        balances[to] += tokens;
        balances[msg.sender] -= tokens;
        emit Transfer(msg.sender, to, tokens);
        
        return true;
    }
    
    
    function allowance(address tokenOwner, address spender) view public override returns(uint){
        return allowed[tokenOwner][spender];
    }
    
    
    function approve(address spender, uint tokens) public override returns (bool success){
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);
        
        allowed[msg.sender][spender] = tokens;
        
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    
    function transferFrom(address from, address to, uint tokens) public override returns (bool success){
         require(allowed[from][msg.sender] >= tokens);
         require(balances[from] >= tokens);
         
         balances[from] -= tokens;
         allowed[from][msg.sender] -= tokens;
         balances[to] += tokens;
 
         emit Transfer(from, to, tokens);
         
         return true;
     }
}



contract CryptosICO is Cryptos {
    address public admin;
    address payable public deposit;
    uint tokenPrice = 0.001 ether;
    uint public hardcap = 300 ether;
    uint public raisedAmount;
    uint public saleStart = block.timestamp + 3600;
    uint public saleEnd = block.timestamp + 604800;
    uint public tokenTradeStart = saleEnd + 604800;
    uint public maxInvestment = 5 ether;
    uint public minInvestment = 0.001 ether;

    enum State {BeforeStart, Running, AfterEnd, Halted}
    State public icoState;

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    constructor(address payable _deposit) {
        admin = msg.sender;
        deposit = _deposit;
        icoState = State.BeforeStart;
    }

    function halt() public onlyAdmin {
        icoState = State.Halted;
    }

    function resume() public onlyAdmin {
        icoState = State.Running;
    }

    function changeDepositAddress(address payable _deposit) public onlyAdmin {
        deposit = _deposit;
    }

    function getCurrentState() public view returns(State) {
        if(icoState == State.Halted) {
            return State.Halted;
        } else if (block.timestamp < saleStart) {
            return State.BeforeStart;
        } else if (block.timestamp > saleStart && block.timestamp < saleEnd) {
            return State.Running
        } else {
            return State.AfterEnd;
        }
    }

    event Invest(address investor, uint value, uint tokens);

    function invest() payable public returns(bool) {
        icoState = getCurrentState();
        require(icoState == State.Running);
        require(msg.value >= minInvestment && msg.value <= maxInvestment);
        raisedAmount+=msg.value;
        require(raisedAmount <= hardcap);

        uint tokens = msg.value / tokenPrice;

        balances[msg.sender] += tokens;
        balances[founder] -= tokens;

        deposit.transfer(msg.value);
        emit Invest(msg.sender, msg.value, tokens)

        return true;
    }

    receive() external payable {
        invest();
    }

}