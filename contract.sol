// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract PacemakerContract {

    // State Variables
    address public ownerID;
    address public requestedBuyerID;
    address public requestedSurgeonID;
    address public manufacturerID;
    

    string internal IPFShash;

    struct Pacemaker{
        uint id;
        uint price;
        uint status;  // 0:not constructed 1:Manufacture  2: Hospital 3:Surgoen 4 Patient Body
        string name;

    }

    Pacemaker public pm;
    
    //Constructors
    constructor() {
        _transfer(address(0),msg.sender);
        manufacturerID = msg.sender;
        pm.status = 0;
    }
    //Events
    event imageuploaded(address manufacturerId);
    event ownerChanged(address oldAdd, address newAdd);

    //Buying pacemakers events
    event PacemakerConstructed(uint id, uint price, string name);
    event pacemakerIsRequested(address ManuID,address hospId,uint id, uint price, string name);
    event pacemakerIsPurchased(address hospID,uint id, string name);
    event pacemakerIsRejected(address ManuID,address hospID,uint id, string name);
    
    //Surgeon pacemaker requesting event
    event SuregonRequestedPacemaker(address surID, address hospID,uint id, string name);
    event pacemakerIsAcquiredBySurgoen(address surID,uint id, string name);
    event pacemakerSurgoenRejected(address surID,address hospID,uint id, string name);


    event pacemakerHasBeenImplanted(address surID, address patId,uint id, string name);

    //Modifiers
    modifier onlyOwner(){
        require(msg.sender == ownerID, "you are not owner");
        _;
    }

    modifier onlyManufacurer(){
        require(msg.sender == manufacturerID, "You are not manufacture");
        _;
    }

    modifier pendingBuyer(){
        require(requestedBuyerID != address(0), "no existing buyer request");
        _;
    }

    modifier pendingSurgoen(){
        require(requestedSurgeonID != address(0), "No request exist from surgoen ");
        _;
    }


   

    // private functions 
     function _transfer(address oldA, address newA) private {
        ownerID = newA;
        emit ownerChanged(oldA, newA);
     }

    //Functions 
    function  uploadPacemakerImage (string calldata _ipfsHash) external onlyManufacurer()   returns (bool _success)  {
            
        require(bytes(_ipfsHash).length == 46);
        IPFShash=_ipfsHash;
        _success = true;

        
        emit imageuploaded(msg.sender);
        
    }


    function registerManufactured(uint _id, uint _price, string memory _name) external onlyOwner() onlyManufacurer{

        pm.id = _id;
        pm.price = _price;
        pm.name = _name;
        pm.status = 1;
        
        emit PacemakerConstructed(_id,_price,_name);
    }


    function requestPurchasePacemaker(uint _amount) external {
        if(msg.sender!=ownerID && ownerID==manufacturerID && _amount == pm.price && pm.status==1){
            requestedBuyerID = msg.sender;
            emit pacemakerIsRequested(ownerID,msg.sender, pm.id, pm.price, pm.name);
        }
    }

    function approvePurchasePacemaker() external onlyOwner() onlyManufacurer() pendingBuyer() {
        _transfer(ownerID, requestedBuyerID);
        emit pacemakerIsPurchased(requestedBuyerID, pm.id, pm.name);
        pm.status = 2;
        //reset buyer
        requestedBuyerID= address(0);
    }
    function rejectPurchasePacemaker() external onlyOwner() onlyManufacurer() pendingBuyer() {
        emit pacemakerIsRejected(ownerID, requestedBuyerID, pm.id, pm.name);
        //reset buyer
        requestedBuyerID= address(0);
    }

    function requestPacemakerForOperation() external onlyOwner pendingSurgoen{
        if(ownerID!=manufacturerID && pm.status==2){
            requestedSurgeonID =  msg.sender;
            emit SuregonRequestedPacemaker(msg.sender, ownerID, pm.id, pm.name);
        }
    }

    function approveSurgoenRequest() external onlyOwner() pendingSurgoen() {
        _transfer(ownerID, requestedSurgeonID);
        emit pacemakerIsAcquiredBySurgoen(requestedSurgeonID, pm.id, pm.name);

        pm.status = 3;
        //reset Surgoen
        requestedSurgeonID= address(0);
    }
    function rejectSurgoenRequest() external onlyOwner() pendingSurgoen() {
        emit pacemakerSurgoenRejected(requestedSurgeonID,ownerID, pm.id, pm.name);
        //reset Surgoen
        requestedSurgeonID= address(0);
    }


    function recordImplanted(address _patientId) external onlyOwner() {
        if (ownerID!=manufacturerID && pm.status==3){
            _transfer(ownerID,_patientId);
            emit pacemakerHasBeenImplanted(ownerID,_patientId, pm.id, pm.name);
            pm.status = 4;//set to 5 as the pm has been implanted
        }
        
    }


}

