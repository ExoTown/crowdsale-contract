pragma solidity ^0.4.11;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
contract SafeMath {

    uint constant DAY_IN_SECONDS = 86400;
    uint constant BASE = 1000000000000000000;

    function mul(uint256 a, uint256 b) constant internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) constant internal returns (uint256) {
        assert(b != 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) constant internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) constant internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function mulByFraction(uint256 number, uint256 numerator, uint256 denominator) constant internal returns (uint256) {
        return div(mul(number, numerator), denominator);
    }

    // Volume bonus calculation
    function volumeBonus(uint256 etherValue) constant internal returns (uint256) {

        if(etherValue >= 1000000000000000000000) return 15; // 1000 ETH +15% tokens
        if(etherValue >=  500000000000000000000) return 10; // 500 ETH +10% tokens
        if(etherValue >=  300000000000000000000) return 7;  // 300 ETH +7% tokens
        if(etherValue >=  100000000000000000000) return 5;  // 100 ETH +5% tokens
        if(etherValue >=   50000000000000000000) return 3;  // 50 ETH +3% tokens
        if(etherValue >=   20000000000000000000) return 2;  // 20 ETH +2% tokens

        return 0;
    }

}


/// Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
/// @title Abstract token contract - Functions to be implemented by token contracts.

contract AbstractToken {
    // This is not an abstract function, because solc won't recognize generated getter functions for public variables as functions
    function totalSupply() constant returns (uint256) {}
    function balanceOf(address owner) constant returns (uint256 balance);
    function transfer(address to, uint256 value) returns (bool success);
    function transferFrom(address from, address to, uint256 value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);
    function allowance(address owner, address spender) constant returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Issuance(address indexed to, uint256 value);
}

contract IcoLimits {
    uint constant privateSaleStart = 1510876800;
    uint constant privateSaleEnd   = 1512086399;

    uint constant presaleStart     = 1512086400;
    uint constant presaleEnd       = 1513900799;

    uint constant publicSaleStart  = 1516320000;
    uint constant publicSaleEnd    = 1521158399;

    uint constant maintenanceStart = 1521158400;
    uint constant maintenanceEnd   = 1535759999;

    modifier afterPublicSale() {
        // only ICO contract is allowed to proceed
        require(now > publicSaleEnd);
        _;
    }
}

contract StandardToken is AbstractToken, IcoLimits {
    /*
     *  Data structures
     */
    mapping (address => uint256) balances;
    mapping (address => bool) ownerAppended;
    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;

    address[] public owners;
    
    /*
     *  Read and write storage functions
     */
    /// @dev Transfers sender's tokens to a given address. Returns success.
    /// @param _to Address of token receiver.
    /// @param _value Number of tokens to transfer.
    function transfer(address _to, uint256 _value) afterPublicSale returns (bool success) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            if(!ownerAppended[_to]) {
                ownerAppended[_to] = true;
                owners.push(_to);
            }
            Transfer(msg.sender, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

    /// @dev Allows allowed third party to transfer tokens from one address to another. Returns success.
    /// @param _from Address from where tokens are withdrawn.
    /// @param _to Address to where tokens are sent.
    /// @param _value Number of tokens to transfer.
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            if(!ownerAppended[_to]) {
                ownerAppended[_to] = true;
                owners.push(_to);
            }
            Transfer(_from, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

    /// @dev Returns number of tokens owned by given address.
    /// @param _owner Address of token owner.
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    /// @dev Sets approved amount of tokens for spender. Returns success.
    /// @param _spender Address of allowed account.
    /// @param _value Number of approved tokens.
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /*
     * Read storage functions
     */
    /// @dev Returns number of allowed tokens for given address.
    /// @param _owner Address of token owner.
    /// @param _spender Address of token spender.
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}


contract ExoTownToken is StandardToken, SafeMath {
    /*
     * Token meta data
     */
    string public constant name = "ExoTown token";
    string public constant symbol = "SNEK";
    uint public constant decimals = 18;

    address public icoContract = 0x0;
    /*
     * Modifiers
     */

    modifier onlyIcoContract() {
        // only ICO contract is allowed to proceed
        require(msg.sender == icoContract);
        _;
    }

    /*
     * Contract functions
     */

    /// @dev Contract is needed in icoContract address
    /// @param _icoContract Address of account which will be mint tokens
    function ExoTownToken(address _icoContract) {
        assert(_icoContract != 0x0);
        icoContract = _icoContract;
    }

    /// @dev Burns tokens from address. It can be applied by account with address this.icoContract
    /// @param _from Address of account, from which will be burned tokens
    /// @param _value Amount of tokens, that will be burned
    function burnTokens(address _from, uint _value) onlyIcoContract {
        assert(_from != 0x0);
        require(_value > 0);
        require(totalSupply >= _value);

        balances[_from] = sub(balances[_from], _value);
        totalSupply -= _value;
    }

    /// @dev Adds tokens to address. It can be applied by account with address this.icoContract
    /// @param _to Address of account to which the tokens will pass
    /// @param _value Amount of tokens
    function emitTokens(address _to, uint _value) onlyIcoContract {
        assert(_to != 0x0);
        require(_value > 0);
        require(totalSupply + _value > totalSupply);

        balances[_to] = add(balances[_to], _value);
        totalSupply += _value;

        if(!ownerAppended[_to]) {
            ownerAppended[_to] = true;
            owners.push(_to);
        }

    }

    function getOwner(uint index) constant returns (address, uint) {
        return (owners[index], balances[owners[index]]);
    }

    function getOwnerCount() constant returns (uint) {
        return owners.length;
    }

}


contract ExoTownIco is SafeMath, IcoLimits {

    /*
     * ICO meta data
     */
    ExoTownToken public exotownToken;

    enum State {
        Pause,
        Init,
        Running,
        Stopped
    }

    State public currentState = State.Pause;


    uint constant privateSalePrice = 4000;
    uint constant preSalePrice     = 3000;
    uint constant publicSalePrice  = 2500;
    uint constant maintenancePrice = 2000;

    



    uint public privateSaleSoldTokens = 0;
    uint public preSaleSoldTokens     = 0;
    uint public publicSaleSoldTokens  = 0;
    uint public maintenanceSoldTokens = 0;

    uint public privateSaleEtherRaised = 0;
    uint public preSaleEtherRaised     = 0;
    uint public publicSaleEtherRaised  = 0;
    uint public maintenanceEtherRaised = 0;

    // Address of manager
    address public icoManager;
    address public founderWallet;

    // Purpose
    address public developmentWallet;
    address public marketingWallet;
    address public teamWallet;

    address public bountyOwner;

    bool public sentTokensToBountyOwner = false;
    bool public sentTokensToFounders = false;

    

    /*
     * Modifiers
     */

    modifier whenInitialized() {
        // only when contract is initialized
        require(currentState >= State.Init);
        _;
    }

    modifier onlyManager() {
        // only ICO manager can do this action
        require(msg.sender == icoManager);
        _;
    }

    modifier onIcoStopped() {
        // Checks if ICO was stopped
        require(currentState == State.Stopped);
        _;
    }

    modifier onIco() {
        require(now >= privateSaleStart && now <= maintenanceEnd);
        require( isPrivateSale() || isPreSale() || isPublicSale() || isMaintenance() );
        _;
    }

    modifier hasBountyCampaign() {
        require(bountyOwner != 0x0);
        _;
    }

    function isPrivateSale() constant internal returns (bool) {
        return now >= privateSaleStart && now <= privateSaleEnd;
    }

    function isPreSale() constant internal returns (bool) {
        return now >= presaleStart && now <= presaleEnd;
    }

    function isPublicSale() constant internal returns (bool) {
        return now >= publicSaleStart && now <= publicSaleEnd;
    }

    function isMaintenance() constant internal returns (bool) {
        return now >= maintenanceStart && now <= maintenanceEnd;
    }












    function getPrice() constant internal returns (uint) {
        if (isPrivateSale()) return privateSalePrice;
        if (isPreSale()) return preSalePrice;
        if (isPublicSale()) return publicSalePrice;
        if (isMaintenance()) return maintenancePrice;

        return maintenancePrice;
    }

    function getStageSupplyLimit() constant internal returns (uint) {
        if (isPrivateSale()) return 4000000 * BASE;
        if (isPreSale()) return 7500000 * BASE;
        if (isPublicSale()) return 30000000 * BASE;
        if (isMaintenance()) return 60000000 * BASE;

        return 0;
    }

    function getStageSoldTokens() constant internal returns (uint) {
        if (isPrivateSale()) return privateSaleSoldTokens;
        if (isPreSale()) return preSaleSoldTokens;
        if (isPublicSale()) return publicSaleSoldTokens;
        if (isMaintenance()) return maintenanceSoldTokens;

        return 0;
    }

    function addStageTokensSold(uint _amount) internal {
        if (isPrivateSale()) privateSaleSoldTokens = add(privateSaleSoldTokens, _amount);
        if (isPreSale())     preSaleSoldTokens = add(preSaleSoldTokens, _amount);
        if (isPublicSale())  publicSaleSoldTokens = add(publicSaleSoldTokens, _amount);
        if (isMaintenance()) maintenanceSoldTokens = add(maintenanceSoldTokens, _amount);
    } 

    function addStageEtherRaised(uint _amount) internal {
        if (isPrivateSale()) privateSaleEtherRaised = add(privateSaleEtherRaised, _amount);
        if (isPreSale())     preSaleEtherRaised = add(preSaleEtherRaised, _amount);
        if (isPublicSale())  publicSaleEtherRaised = add(publicSaleEtherRaised, _amount);
        if (isMaintenance()) maintenanceEtherRaised = add(maintenanceEtherRaised, _amount);
    } 

    function getTokensSold() constant returns (uint) {
        uint tokensSold = 0;
        tokensSold = add(tokensSold, privateSaleSoldTokens);
        tokensSold = add(tokensSold, preSaleSoldTokens);
        tokensSold = add(tokensSold, publicSaleSoldTokens);
        tokensSold = add(tokensSold, maintenanceSoldTokens);
        return tokensSold;
    }















    /// @dev Constructor of ICO. Requires address of icoManager,
    /// @param _icoManager Address of ICO manager
    function ExoTownIco(address _icoManager) {
        assert(_icoManager != 0x0);

        exotownToken = new ExoTownToken(this);
        icoManager = _icoManager;
    }

    /// Initialises addresses of founder, target wallets
    /// @param _founder Address of Founder
    /// @param _dev Address of Development wallet
    /// @param _pr Address of Marketing wallet
    /// @param _team Address of Team wallet

    function init(address _founder, address _dev, address _pr, address _team) onlyManager {
        assert(currentState < State.Init);
        assert(_founder != 0x0);
        assert(_dev != 0x0);
        assert(_pr != 0x0);
        assert(_team != 0x0);

        founderWallet = _founder;
        developmentWallet = _dev;
        marketingWallet = _pr;
        teamWallet = _team;
                
        currentState = State.Init;
    }

    /// @dev Sets new state
    /// @param _newState Value of new state
    function setState(State _newState) public onlyManager {
        currentState = _newState;
    }

    /// @dev Sets new manager. Only manager can do it
    /// @param _newIcoManager Address of new ICO manager
    function setNewManager(address _newIcoManager) onlyManager {
        assert(_newIcoManager != 0x0);
        icoManager = _newIcoManager;
    }

    /// @dev Sets bounty owner. Only manager can do it
    /// @param _bountyOwner Address of Bounty owner
    function setBountyCampaign(address _bountyOwner) onlyManager {
        assert(_bountyOwner != 0x0);
        bountyOwner = _bountyOwner;
    }


    /// @dev Buy quantity of tokens depending on the amount of sent ethers.
    /// @param _buyer Address of account which will receive tokens
    function buyTokens(address _buyer) private {
        assert(_buyer != 0x0);
        require(msg.value > 0);

        uint tokensToEmit = msg.value * getPrice();
        uint volumeBonusPercent = volumeBonus(msg.value);

        if (volumeBonusPercent > 0){
            tokensToEmit = add(tokensToEmit, mulByFraction(tokensToEmit, volumeBonusPercent, 100));
        }

        uint stageSupplyLimit = getStageSupplyLimit();
        uint stageSoldTokens = getStageSoldTokens();

        require(add(stageSoldTokens, tokensToEmit) <= stageSupplyLimit);
        
        //emit tokens to token holder
        exotownToken.emitTokens(_buyer, tokensToEmit);
        
        addStageTokensSold(tokensToEmit);
        addStageEtherRaised(msg.value);

        distributeEtherByStage();
        
    }

    /// @dev Fall back function
    function () payable onIco {
        buyTokens(msg.sender);
    }

    function distributeEtherByStage() private {
        uint _devAmount = 0;
        uint _prAmount = 0;
        uint _teamAmount = 0;
        if (isPrivateSale()) {
            _devAmount = mulByFraction(this.balance, 45, 100);
            _prAmount = mulByFraction(this.balance, 50, 100);
            _teamAmount = mulByFraction(this.balance, 5, 100);
        }
        if (isPreSale()) {
            _devAmount = mulByFraction(this.balance, 60, 100);
            _prAmount = mulByFraction(this.balance, 30, 100);
            _teamAmount = mulByFraction(this.balance, 10, 100);
        }
        if (isPublicSale()) {
            _devAmount = mulByFraction(this.balance, 70, 100);
            _prAmount = mulByFraction(this.balance, 20, 100);
            _teamAmount = mulByFraction(this.balance, 10, 100);
        }
        if (isMaintenance()) {
            _devAmount = mulByFraction(this.balance, 90, 100);
            _prAmount = mulByFraction(this.balance, 5, 100);
            _teamAmount = mulByFraction(this.balance, 5, 100);
        }
        uint total = 0;
        total = add(total, _devAmount);
        total = add(total, _prAmount);
        total = add(total, _teamAmount);
        if (_devAmount > 0 && _prAmount > 0 && _teamAmount > 0 && total <= this.balance) {
            developmentWallet.transfer(_devAmount);
            marketingWallet.transfer(_prAmount);
            teamWallet.transfer(_teamAmount);
        }
    }


    /// @dev Partial withdraw. Only manager can do it
    function withdrawEther(uint _value) onlyManager {
        require(_value > 0);
        assert(_value <= this.balance);
        // send 1234 to get 1.234
        icoManager.transfer(_value * 1000000000000000); // 10^15
    }

    ///@dev Send tokens to bountyOwner depending on crowdsale results. Can be send only after ICO.
    function sendTokensToBountyOwner() onlyManager whenInitialized hasBountyCampaign {
        require(now > publicSaleEnd);
        require(!sentTokensToBountyOwner);

        uint tokensSold = getTokensSold();

        //Calculate bounty tokens depending on total tokens sold
        uint bountyTokens = mulByFraction(tokensSold, 25, 1000); // 2.5%

        exotownToken.emitTokens(bountyOwner, bountyTokens);

        sentTokensToBountyOwner = true;
    }

    /// @dev Send tokens to founders.
    function sendTokensToFounders() onlyManager whenInitialized {
        require(now > maintenanceEnd);
        require(!sentTokensToFounders);

        //Calculate founder reward depending on total tokens sold
        uint tokensSold = getTokensSold();

        uint founderReward = mulByFraction(tokensSold, 10, 100); // 10%

        //send every founder 25% of total founder reward
        exotownToken.emitTokens(founderWallet, founderReward);

        sentTokensToFounders = true;
    }
}