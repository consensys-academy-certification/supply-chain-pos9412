pragma solidity ^0.5.0;

contract SupplyChain {

  address payable owner;
  constructor() public {

    owner= msg.sender;

  }

  // Create a variable named 'itemIdCount' to store the number of items and also be used as reference for the next itemId.
  uint itemIdCount;

  // Create an enumerated type variable named 'State' to list the possible states of an item (in this order): 'ForSale', 'Sold', 'Shipped' and 'Received'.
  enum State {ForSale, Sold, Shipped, Received}

  // Create a struct named 'Item' containing the following members (in this order): 'name', 'price', 'state', 'seller' and 'buyer'.
  struct Item {
    string name;
    uint price;
    State state;
    address payable seller;
    address payable buyer;
  }

  // Create a variable named 'items' to map itemIds to Items.
  mapping(uint=>Item) items;

  // Create an event to log all state changes for each item.
  event StateChange(
    uint itemId,
    string itemName,
    State itemState
  );

  // Create a modifier named 'onlyOwner' where only the contract owner can proceed with the execution.
  modifier onlyOwner() {
    require(owner == msg.sender);
    _;
  }

  // Create a modifier named 'checkState' where the execution can only proceed if the respective Item of a given itemId is in a specific state.
  modifier checkState(uint _itemId, State _state) {
    require(items[_itemId].state == _state);
    _;
  }

  // Create a modifier named 'checkCaller' where only the buyer or the seller (depends on the function) of an Item can proceed with the execution.
  modifier checkCaller(address _caller) {
    require(msg.sender == _caller);
    _;
  }

  // Create a modifier named 'checkValue' where the execution can only proceed if the caller sent enough Ether to pay for a specific Item or fee.
  modifier checkValue(uint _checkedmoney) {
    require(msg.value >= _checkedmoney);
    _;
  }

  // Create a function named 'addItem' that allows anyone to add a new Item by paying a fee of 1 finney. Any overpayment amount should be returned to the caller. All struct members should be mandatory except the buyer.
    function addItem(string memory _name, uint _price) public payable checkValue(1 finney)  returns(uint) {
      uint itemId = itemIdCount++;
      uint money = msg.value - (1 finney);
      items[itemId].name = _name;
      items[itemId].price = _price;
      items[itemId].state = State.ForSale;
      items[itemId].seller = msg.sender;
    
      emit StateChange(itemId, items[itemId].name, items[itemId].state);
    
      msg.sender.send(money);
    return itemId;
 
  }


  // Create a function named 'buyItem' that allows anyone to buy a specific Item by paying its price. The price amount should be transferred to the seller and any overpayment amount should be returned to the buyer.
  function buyItem(uint _itemId) public payable checkState(_itemId, State.ForSale) checkValue(items[_itemId].price)  {
    uint itemprice = items[_itemId].price;
    uint money = msg.value - itemprice;
    address payable seller = items[_itemId].seller;
  
    items[_itemId].state = State.Sold;
    items[_itemId].buyer = msg.sender;

    emit StateChange(_itemId, items[_itemId].name, items[_itemId].state);

    seller.send(items[_itemId].price);
    msg.sender.send(money);
  }

  // Create a function named 'shipItem' that allows the seller of a specific Item to record that it has been shipped.
  function shipItem(uint _itemId) public checkState(_itemId, State.Sold) checkCaller(items[_itemId].seller)  {
    items[_itemId].state = State.Shipped;
    emit StateChange(_itemId, items[_itemId].name, items[_itemId].state);
  }

  // Create a function named 'receiveItem' that allows the buyer of a specific Item to record that it has been received.
  function receiveItem(uint _itemId) public checkState(_itemId, State.Shipped) checkCaller(items[_itemId].buyer)  {
    items[_itemId].state = State.Received;
    emit StateChange(_itemId, items[_itemId].name, items[_itemId].state);
  }

  // Create a function named 'getItem' that allows anyone to get all the information of a specific Item in the same order of the struct Item.
  function getItem(uint _itemId) public view returns (string memory, uint256, State, address, address) {
    string memory _getName = items[_itemId].name;
    uint _getPrice = items[_itemId].price;
    State _getStates = items[_itemId].state;
    address _getSeller = items[_itemId].seller;
    address _getBuyer = items[_itemId].buyer;
    return (_getName, _getPrice, _getStates, _getSeller, _getBuyer);
}

  // Create a function named 'withdrawFunds' that allows the contract owner to withdraw all the available funds.
  function withdrawFunds() public onlyOwner() {
    owner.transfer(address(this).balance);
  }
}