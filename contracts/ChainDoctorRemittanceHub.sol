pragma solidity ^0.4.18;

import "./ChainDoctorRemittance.sol";
import "./Stoppable.sol";

contract ChainDoctorHub is Stoppable{
    
    address[] public chainDoctorRemittances;
    mapping(address => bool) public chainDoctorRemittanceExists;
    
    event LogNewChainDoctorRemittance(address owner, address remittanceOwner, address chainDoctorRemittance, uint value);
    event LogChainDoctorRemittanceStopped(address sender, address chainDoctorRemittance);
    event LogChainDoctorRemittanceStarted(address sender, address chainDoctorRemittance);
    event LogChainDoctorRemittanceNewOwner(address sender, address chainDoctorRemittance, address newOwner);
    
    modifier onlyIfChainDoctorRemittance(address chainDoctorRemittance) {
        require(chainDoctorRemittanceExists[chainDoctorRemittance] == true);
        _;
    }

    function getChainDoctorRemittanceCount()
        public
        constant
        returns(uint chainDoctorRemittanceCount)
    {
        return chainDoctorRemittances.length;
    }
    
    function createChainDoctorRemittance(address remittanceOWner, uint deadlineInSeconds)
        public
        returns(address chainDoctorRemittance)
    {
        ChainDoctorRemittance trustedChainDoctorRemittance;  //trusted because we know the developer

        trustedChainDoctorRemittance = new ChainDoctorRemittance( remittanceOWner, deadlineInSeconds);
        chainDoctorRemittances.push(trustedChainDoctorRemittance);
        chainDoctorRemittanceExists[trustedChainDoctorRemittance] = true;

        //Hub contract is the owner and admin is who sent the msg
        LogNewChainDoctorRemittance(msg.sender, remittanceOWner, trustedChainDoctorRemittance, deadlineInSeconds);
        return trustedChainDoctorRemittance;
    }
    
    function stopChainDoctorRemittance(address chainDoctorRemittance)
        onlyOwner
        onlyIfChainDoctorRemittance(chainDoctorRemittance)
        returns(bool success) 
    {
        ChainDoctorRemittance trustedChainDoctorRemittance = ChainDoctorRemittance(chainDoctorRemittance);
        LogChainDoctorRemittanceStopped(msg.sender, chainDoctorRemittance);
        return (trustedChainDoctorRemittance.runSwitch(false));
    }
    
    function startChainDoctorRemittance(address chainDoctorRemittance)
        onlyOwner
        onlyIfChainDoctorRemittance(chainDoctorRemittance)
        returns(bool success)
    {
        ChainDoctorRemittance trustedChainDoctorRemittance = ChainDoctorRemittance(chainDoctorRemittance);
        LogChainDoctorRemittanceStarted(msg.sender, chainDoctorRemittance);
        return (trustedChainDoctorRemittance.runSwitch(true));
    }
    
    function changeChainDoctorRemittanceOwner(address chainDoctorRemittance, address newOwner)
        onlyOwner
        onlyIfChainDoctorRemittance(chainDoctorRemittance)
        returns(bool success)
    {
        ChainDoctorRemittance trustedChainDoctorRemittance = ChainDoctorRemittance(chainDoctorRemittance);
        LogChainDoctorRemittanceNewOwner(msg.sender, chainDoctorRemittance , newOwner);
        return (trustedChainDoctorRemittance.changeOwner(newOwner));
    }
    
    
}