// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./USDC.sol";
import "./VToken.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Vault{
    using SafeERC20 for USDC;
    using SafeERC20 for VToken;

    USDC usdc;
    VToken vtoken;

    struct Debt{
        uint startTime;
        uint endTime;
        uint amount;
        bool status;
    }

    uint constant WAIT_TIME = 30 * 24 * 60 * 60;
    uint fond;

    mapping(address => Debt[]) debts;

    mapping (address => uint) lenders;

    // setting up tokens
    constructor(address _usdc, address _vtoken){
        usdc = USDC(_usdc);
        vtoken = VToken(_vtoken);
    }


    // make a deposit
    function deposit(uint _amount) public{
        vtoken.safeTransferFrom(msg.sender, address(this), _amount);
        lenders[msg.sender] += _amount;
    }

    function borrow(uint _amount) public{
        // check for rule 80%
        Debt[] storage debt = debts[msg.sender];
        uint debtSum;
        for (uint i=0; i < debt.length; i++){
            if (debt[i].status == true){
                debtSum += debt[i].amount;
            }
        }
        require(_amount > 0, "amount cannot be equal to zero");
        require(_amount <= (lenders[msg.sender] - debtSum) * 800 / 1000, "Your deposit is too small");

        debt.push(Debt({
            startTime: block.timestamp,
            endTime: block.timestamp + WAIT_TIME,
            amount:_amount,
            status: true
        }));
        
        usdc.safeTransfer(msg.sender, _amount);
    }

    function liquidate(uint _id) public{
        Debt storage debt = debts[msg.sender][_id];

        require(debt.status == true, "debt does not exist");
        require(block.timestamp >= debt.endTime, "endTime has not come");

        usdc.safeTransferFrom(msg.sender, address(this), debt.amount);
        vtoken.transfer(msg.sender, debt.amount * 850 / 1000);
        fond += debt.amount * 100 / 1000;

        debt.status = false;
    }
}

/**
 Напишите контракт, в котором будут выполняться следующие условия:
 - Это Vault контракт;
 - Пользователи могут делать депозит своих токенов, записать их в маппинг lenders;
 - Другие пользователи могут брать обычные займы, записать их маппинг borrowers;
 - Пользователь может взять займ только в размере не более 80% от своего депозита;
 - Для удобства, любые токены приравнены 1:1 по цене;
 - Написать функцию ликвидации, при которой любой пользователь может закрыть займ, если прошло более 30 дней. 
 Он получит 85% от суммы займа, 5% пойдут вашему протоколу и 10% в фонд для распределения между всемы lenders;
*/