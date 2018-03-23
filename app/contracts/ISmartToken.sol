pragma solidity ^0.4.18;
import './IOwned.sol';
import './ERC223_Interface.sol';

/*
    Smart Token interface
*/
contract ISmartToken is IOwned, ERC223 {
    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
}
