pragma solidity ^0.4.18;
import './IOwned.sol';
import './ERC223_Interface.sol';

/*
    Token Holder interface
*/
contract ITokenHolder is IOwned, ERC223 {
    function withdrawTokens(ERC223 _token, address _to, uint256 _amount) public;
}
