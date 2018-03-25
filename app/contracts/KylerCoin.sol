pragma solidity ^0.4.9;

import "./Receiver_Interface.sol";
import "./ERC223_Interface.sol";
import "./Balances.sol";
import "./Utils.sol";
import "./Owned.sol";
import "TokenHolder.sol";

 /**
 * ERC223 token by Dexaran
 *
 * https://github.com/Dexaran/ERC223-token-standard
 */


 /* https://github.com/LykkeCity/EthereumApiDotNetCore/blob/master/src/ContractBuilder/contracts/token/SafeMath.sol */
contract SafeMath {
    uint256 constant public MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (x > MAX_UINT256 - y) revert();
        return x + y;
    }

    function safeSub(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (x < y) revert();
        return x - y;
    }

    function safeMul(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (y == 0) return 0;
        if (x > MAX_UINT256 / y) revert();
        return x * y;
    }
}

contract KylerCoin is Owned, ERC223, SafeMath, Balances, Utils, ISmartToken, TokenHolder {

    mapping(address => uint) balances;

  string public standard = '0.3';
  string public name = "KylerCoin";
  string public symbol = "KC";
  uint8 public decimals = 18;
  uint256 public totalSupply;

  bool public transfersEnabled = true;    // true if transfer/transferFrom are enabled, false if not

  // triggered when a smart token is deployed - the _token address is defined for forward compatibility, in case we want to trigger the event from a factory
  event NewSmartToken(address _token);
  // triggered when the total supply is increased
  event Issuance(uint256 _amount);
  // triggered when the total supply is decreased
  event Destruction(uint256 _amount);

  // Function to access name of token .
  function name() public view returns (string _name) {
      return name;
  }
  // Function to access symbol of token .
  function symbol() public view returns (string _symbol) {
      return symbol;
  }
  // Function to access decimals of token .
  function decimals() public view returns (uint8 _decimals) {
      return decimals;
  }
  // Function to access total supply of tokens .
  function totalSupply() public view returns (uint256 _totalSupply) {
      return totalSupply;
  }

  /**
   * Constructor function
   *
   * Initializes contract with initial supply tokens to the creator of the contract
   */

  function KylerCoin(uint256 initialSupply) public {
      totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
      balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
      NewSmartToken(address(this));
  }

  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success) {

    if(isContract(_to)) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
        Transfer(msg.sender, _to, _value, _data);
        return true;
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
}


  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes _data) public returns (bool success) {

    if(isContract(_to)) {
        return transferToContract(_to, _value, _data);
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
}

  // Standard function transfer similar to ERC20 transfer with no _data .
  // Added due to backwards compatibility reasons .
  function transfer(address _to, uint _value) public transfersAllowed returns (bool success) {

    //standard function transfer similar to ERC20 transfer with no _data
    //added due to backwards compatibility reasons
    bytes memory empty;
    if(isContract(_to)) {
        return transferToContract(_to, _value, empty);
    }
    else {
        return transferToAddress(_to, _value, empty);
    }
}

  //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
  function isContract(address _addr) private view returns (bool is_contract) {
      uint length;
      assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
      }
      return (length>0);
    }

  //function that is called when transaction target is an address
  function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) revert();
    balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
    balances[_to] = safeAdd(balanceOf(_to), _value);
    Transfer(msg.sender, _to, _value, _data);
    return true;
  }

  //function that is called when transaction target is a contract
  function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) revert();
    balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
    balances[_to] = safeAdd(balanceOf(_to), _value);
    ContractReceiver receiver = ContractReceiver(_to);
    receiver.tokenFallback(msg.sender, _value, _data);
    Transfer(msg.sender, _to, _value, _data);
    return true;
}


  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }

  /**
      @dev an account/contract attempts to get the coins
      throws on any error rather then return a false flag to minimize user errors
      in addition to the standard checks, the function throws if transfers are disabled

      @param _from    source address
      @param _to      target address
      @param _value   transfer amount

      @return true if the transfer was successful, false if it wasn't
  */
  function transferFrom(address _from, address _to, uint256 _value) public transfersAllowed returns (bool success) {
      assert(super.transferFrom(_from, _to, _value));
      return true;
  }

  // allows execution only when transfers aren't disabled
  modifier transfersAllowed {
      assert(transfersEnabled);
      _;
  }

  modifier ownerOnly {
      assert(msg.sender == owner);
      _;
  }

  /**
      @dev disables/enables transfers
      can only be called by the contract owner

      @param _disable    true to disable transfers, false to enable them
  */
  function disableTransfers(bool _disable) public ownerOnly {
      transfersEnabled = !_disable;
  }

  /**
      @dev increases the token supply and sends the new tokens to an account
      can only be called by the contract owner

      @param _to         account to receive the new amount
      @param _amount     amount to increase the supply by
  */
  function issue(address _to, uint256 _amount)
      public
      ownerOnly
      validAddress(_to)
      notThis(_to)
  {
      totalSupply = safeAdd(totalSupply, _amount);
      balanceOf[_to] = safeAdd(balanceOf[_to], _amount);

      Issuance(_amount);
      Transfer(this, _to, _amount);
  }

  /**
      @dev removes tokens from an account and decreases the token supply
      can be called by the contract owner to destroy tokens from any account or by any holder to destroy tokens from his/her own account

      @param _from       account to remove the amount from
      @param _amount     amount to decrease the supply by
  */
  function destroy(address _from, uint256 _amount) public {
      require(msg.sender == _from || msg.sender == owner); // validate input

      balanceOf[_from] = safeSub(balanceOf[_from], _amount);
      totalSupply = safeSub(totalSupply, _amount);

      Transfer(_from, this, _amount);
      Destruction(_amount);
  }

}
