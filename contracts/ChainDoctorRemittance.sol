pragma solidity ^0.4.18;

import "./Stoppable.sol";

/**
 * @title ChainDoctorRemittance contract. 
 * World Virtual Hackathon
 * 
 */
contract ChainDoctorRemittance is Stoppable {
    
    address public owner; //city hall address
    mapping (bytes32 => bool) public QRcodesMapping; //QR codes that has already being paid. Must be unique
    
    uint public deadlineInSeconds;  //remittance max period of time. after that, owner can claim funds
    
    //each doctor will be beneficary of a remittance struct.
    //removed withdraw dealine time to make it simpler - at first, doctor would only withdrawn once a week, but to make 
    //it simpler, I removed it.
    struct ChainDoctorRemittanceStruct {
	    uint remittanceBallance;       //value Doctor will receive from city hall
	    uint accountBalance;           //value that city hall deposits to guarantee payment to the doctor
        uint appointmentValueInWei;    //value of each time doctor sees a patient
    }
    
    // key is beneficiaryAddress who is the doctor to permit withdrawn
    mapping (address => ChainDoctorRemittanceStruct) public ChainDoctorRemittanceMapping;
    
    //Log events
    event LogRemittanceProcessStarted(address  sender, address  beneficiary, uint amountReceived);
    event LogTransferred(address beneficiary, uint amount);
    event LogDoctorPaid(address beneficiary, bytes32 qrcode);
    
    //Constructor
    //_deadlineLimitInSeconds
    //_owner - city hall address
    function ChainDoctorRemittance(address _owner , uint _deadlineInSeconds) {
        owner = _owner;
        deadlineInSeconds = _deadlineInSeconds;
    }
    
    //Start a remittance process
    //for each contract, a new address is necessary - this logic maybe improved in the future
    //and we may add deadlineInSeconds - 6 months = 16000000 - a 6 months deadline is now + 16000000
    function createNewChainDoctorRemittanceProcess(address doctorAddress , uint _appointmentValueInWei) 
        public
        payable  
        returns(bool success) 
    {
        //if deadline is greater than the deadlimit, if msg.value is zero,
        //if doctorAddress address is zero and if password was already used in the past, revert
        require(doctorAddress > 0);  //must be a valid address
        require(msg.value > 0);  //must have a positive ammount  to be able to pay doctors
        require(ChainDoctorRemittanceMapping[doctorAddress].remittanceBallance == 0); //must be new process
        require(ChainDoctorRemittanceMapping[doctorAddress].accountBalance == 0); //must be new process
        require(msg.sender == owner); //only owner can create remittance process
        
        ChainDoctorRemittanceStruct memory newRemittance;
        newRemittance.accountBalance = msg.value;  // for each appointment, a defaultAppointmentValueInWei is going to be subtracted from this value.
        newRemittance.appointmentValueInWei = _appointmentValueInWei;
        
        ChainDoctorRemittanceMapping[doctorAddress] = newRemittance;

        LogRemittanceProcessStarted(msg.sender , doctorAddress, newRemittance.remittanceBallance);
        
        return true;
    }
    
    function payDoctor(address beneficiary, bytes32 qrcode) 
        public
        returns(bool success) 
    {
        require(msg.sender == owner);
        require(QRcodesMapping[qrcode]==false); //must be unique
        require(ChainDoctorRemittanceMapping[beneficiary].accountBalance > 0); //must have funds to pay doctor
        
        //mark QR code as read and done to avoid paying twice
        QRcodesMapping[qrcode] = true;
        
        //add defaultAppointmentValueInWei to the doctor balance
        ChainDoctorRemittanceMapping[beneficiary].remittanceBallance = ChainDoctorRemittanceMapping[beneficiary].remittanceBallance + ChainDoctorRemittanceMapping[beneficiary].appointmentValueInWei;
        ChainDoctorRemittanceMapping[beneficiary].accountBalance = ChainDoctorRemittanceMapping[beneficiary].accountBalance - ChainDoctorRemittanceMapping[beneficiary].appointmentValueInWei;
        
        //add log event
        
        return true;
    }
    
    //beneficary will call this function to receive ethers
    function releaseRemittance() 
        public
        returns(bool success)
    {
        //only beneficiary can call this function and it should have funds
        //and must have a positive balance
        require(ChainDoctorRemittanceMapping[msg.sender].remittanceBallance > 0);
        
        uint amount = ChainDoctorRemittanceMapping[msg.sender].remittanceBallance;

        //msg.sender is the beneficary and it was checked in the first line of this function
        ChainDoctorRemittanceMapping[msg.sender].remittanceBallance = 0;
        
        msg.sender.transfer(amount);
        
        LogTransferred(msg.sender, amount);
        
        return true;
    }
    
    //kill the contract and return all remain funds to the contract owner
    //after expire date
    function killMe() 
        public
        returns (bool success)
    {
        require(msg.sender == owner);
        require(now > deadlineInSeconds); //now is equal to block.timestamp
        
        uint amount = this.balance;
        
        selfdestruct(owner);
        
        LogTransferred(msg.sender, amount);
        return true;
    }
    
    function () {
    }
}
