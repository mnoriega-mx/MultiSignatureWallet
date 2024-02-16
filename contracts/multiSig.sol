pragma solidity 0.8.22;

contract MultiSignatureWallet {

    address contractHolder = msg.sender;
    uint approvalLimit;
    uint balance;

    mapping(address => bool) isOwner;
    address[] owners;

    struct TransferRequest {
        address payable recipient;
        uint amount;
        uint approvals;
    }

    TransferRequest[] withrawals;

    TransferRequest request;
    bool requestActive = false;

    function addOwners(address newOwner) public{
        require(msg.sender == contractHolder, "You are not the contract holder, therefore, you cannot add owners to this contract");
        require(isOwner[newOwner] == false, "This address is already an owner");

        owners.push(newOwner);
        isOwner[newOwner] = true;
    }

    function getOwners() public view returns(address[] memory){
        return(owners);
    }

    function setApprovalLimit(uint newLimit) public {
        approvalLimit = newLimit;
    }

    function getApprovalLimit() public view returns(uint) {
        return(approvalLimit);
    }

    function getWalletBalance() public view returns(uint) {
        return(balance);
    }

    function deposit() public payable {
        balance += msg.value;
    }

    function withdraw(address payable recipient, uint amount) public payable {
        require(isOwner[msg.sender] == true, "You are not an owner of this wallet");
        require(amount <= balance, "Insuficient funds in wallet");
        require(msg.sender != recipient, "You cannot transfer money to your own wallet");
        require(requestActive == false, "Transfer approval still pending");

        if (approvalLimit == 0) {
            recipient.transfer(amount);
            TransferRequest memory newWithdrawal = TransferRequest(recipient, amount, 0);
            withrawals.push(newWithdrawal);
            balance -= amount;
        } else {
            TransferRequest memory newRequest = TransferRequest(recipient, amount, 0);
            requestActive = true;
            request = newRequest;
        }
    }

    function approveWithdrawal() public payable{
        require(requestActive == true, "No transfer request active");
        require(isOwner[msg.sender] == true, "You are not an owner of this wallet");

        request.approvals += 1;
        if (request.approvals >= approvalLimit) {
            request.recipient.transfer(request.amount);
            withrawals.push(request);
            requestActive = false;
            balance -= request.amount;
        }
    }

    function withrawalStatus() public view returns(string memory) {
        require(withrawals.length > 0, "No withrawals yet");
        if (requestActive == true) {
            return("Transaction waiting for approval");
        } else {
            return("Transaction succesful");
        }
    }

}