#pragma version ^0.3.10


# BEP-20 CONTRACT IMPLEMENTATION 


## Events declarations 

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256     

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256


## Variables declarations 

balanceOf: public(HashMap[address, uint256])
name: public(String[32])
symbol: public(String[32])
allowance: public(HashMap[address, HashMap[address, uint256]])
decimals: public(uint8)
supply: public(uint256)
owner: public(address)


## Interface declaration

interface IBEP20:

    def totalSupply() -> uint256: view

    def decimals() -> uint8: view

    def symbol() -> String[10]: view

    def name() -> String[10]: view

    def getOwner() -> address: view

    def balanceOf(account: address) -> uint256: view

    def transfer(recipient: address, amount: uint256) -> bool: payable

    def allowance(_owner: address, spender: address) -> uint256: view

    def approve(spender: address, amount: uint256) -> bool: payable

    def transferFrom(sender: address, recipient: address, amount: uint256) -> bool: payable


## Functions implementations

@external
def totalSupply() -> uint256:
    return self.supply

@external
def transfer(recipient: address, amount: uint256) -> bool:

    assert self.balanceOf[msg.sender] >= amount, "insufficient value"

    self.balanceOf[msg.sender] -= amount
    self.balanceOf[recipient] += amount

    log Transfer(msg.sender, recipient, amount)

    return True

@external
def transferFrom(_from: address, _to: address, _value: uint256) -> bool:
    
    assert self.balanceOf[_from] >= _value, "insufficient value"

    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value

    self.allowance[_from][msg.sender] -= _value

    log Transfer(_from, _to, _value)

    return True

@external
def approve(_spender : address, _value : uint256) -> bool:

    self.allowance[msg.sender][_spender] = _value

    log Approval(msg.sender, _spender, _value)

    return True


# BET IMPLEMENTATION

## Events declarations 

event EventCreate:
    validator: indexed(address)
    eventCode: indexed(bytes32)
    eventName: String[100]

event Bet:
    person: indexed(address)
    eventCode: indexed(bytes32)
    decision: indexed(String[1])
    amount: uint256

event EventDecision:
    eventCode: bytes32
    decision: String[1]
    losers: uint256


## Variables declaraions

#Amount of reserved tokens 
teamLockedTokens: public(uint256)
marketingLockedTokens: public(uint256)
presaleLockedTokens: public(uint256)
airdropLockedTokens: public(uint256)
otherLockedTokens: public(uint256)

#Established addresses for unlocking
teamAddress: public(address)
marketingAddress: public(address) 

#Date of last unlocks
lastUnlockDate_Team: public(uint256)
lastUnlockDate_Marketing: public(uint256)

#Time period required for unlocking
unlockTime_Team: constant(uint256) = 5270400
unlockTime_Marketing: constant(uint256) = 2592000

#Count of unlocks
unlocksCount_Team: public(uint256)
unlocksCount_Marketing: public(uint256)

contractCreateTime: public(uint256)

airdropReceived: public(HashMap[address, bool])
airDropMembersLimit: constant(uint256) = 1000000
airdropMembersCount: public(uint256)


## Functions declarations

@external
def unlock() -> bool:

    assert (self.unlocksCount_Team < 10) or (self.unlocksCount_Marketing < 10), "All unlocks achieved"  
             
    currentTime: uint256 = self.getTime()

    teamTokens: uint256 = convert(convert(self.teamLockedTokens,decimal) * 0.1, uint256)
    marketingTokens: uint256 = convert(convert(self.marketingLockedTokens, decimal) * 0.1, uint256)
    
    if  self.unlocksCount_Team < 10 and (self.lastUnlockDate_Team + unlockTime_Team) < currentTime:
        self.unlocksCount_Team += 1
        self.lastUnlockDate_Team = currentTime

        self.balanceOf[self.teamAddress] += teamTokens

        log Transfer(empty(address), self.teamAddress, teamTokens)         

    if  self.unlocksCount_Marketing < 10 and (self.lastUnlockDate_Marketing + unlockTime_Marketing) < currentTime:

        self.unlocksCount_Marketing += 1
        self.lastUnlockDate_Marketing = currentTime

        self.balanceOf[self.marketingAddress] += marketingTokens
        
        log Transfer(empty(address), self.marketingAddress, marketingTokens)         

    return True 


@external
def sendOther(_receiver: address, _amount: uint256) -> bool:

    assert msg.sender == self.owner, "Ownership error"
    assert _amount <= self.otherLockedTokens, "insufficient_value"

    self.otherLockedTokens -= _amount
    self.balanceOf[_receiver] += _amount

    log Transfer(empty(address), _receiver, _amount)

    return True


@external
def sendPresale(_receiver: address, _amount: uint256) -> bool:
    assert msg.sender == self.owner, "Ownership error"
    assert _amount <= self.presaleLockedTokens, "insufficient_value"

    self.presaleLockedTokens -= _amount
    self.balanceOf[_receiver] += _amount

    log Transfer(empty(address), _receiver, _amount)

    return True

@external
def getAirdrop() -> bool:
    currentTime: uint256 = self.getTime()
    month: uint256 = 2592000 


    assert self.airdropReceived[msg.sender] != True, "Airdop has already been received"
    assert self.airdropMembersCount < airDropMembersLimit, "Airdrop members limit"
    assert (self.contractCreateTime + month) >= currentTime, "Time to receive airdrop has expired"
    
    amount: uint256 = 2000

    if self.betOfCount[msg.sender] >=30:
        self.balanceOf[msg.sender] += amount
        self.airdropMembersCount+=1
        self.airdropLockedTokens -= amount
        self.airdropReceived[msg.sender] = True
        log Transfer(empty(address), msg.sender, amount)
    else:
        raise "You haven't placed enough bets"

    return True


## Variables Declarations 

# The maximum number of events possible at the moment for the user 
# The number of bets on the side of the event
MAX_COUNT: constant(uint256) =  10000

A_range: constant(uint256[2]) = [0,200]
B_range: constant(uint256[2]) = [200,400]
C_range: constant(uint256[2]) = [400,600]

eventsList: public(HashMap[bytes32, BetEvent])
eventOf: public(HashMap[address, DynArray[bytes32, MAX_COUNT]])
eventOfCount: public(HashMap[address, uint256])


betList: public(HashMap[bytes32, HashMap[uint256, DynArray[Bid, MAX_COUNT]]])
betOf: public(HashMap[address, HashMap[bytes32, HashMap[String[1], Bid]]])
betOfCount: public(HashMap[address, uint256])

biggestEvents: public(DynArray[bytes32, 5])

feeAddress_1: constant(address) = 0xa9a4e9C1fDCd2bcE5D22EFB5F23054B651C7d0aC
feeAddress_2: constant(address) = 0x022c174f080BFbF0c008E477e34f7436e25c2A8B

struct Bid:
    participant: address
    amount: uint256

struct BetEvent:
    eventCode: bytes32
    auditAddress: address
    name: String[100]
    createTime: uint256
    betTime: uint256
    endTime: uint256
    decision: String[1]
    A_weight: uint256
    B_weight: uint256
    C_weight: uint256
    A_name: String[50]
    B_name: String[50]
    C_name: String[50]
    A_count: uint256
    B_count: uint256
    C_count: uint256
    ended: bool
    weight: uint256


## Functions implementations

@internal
@view
def getTime() -> uint256:
    return block.timestamp  

@external
def eventCreate(_name: String[100], _bTime: uint256, _endTime: uint256, _aName: String[50], _bName: String[50], _cName: String[50] ) -> bool: 
   
    currentTime: uint256 = self.getTime() 

    assert _bTime > currentTime, "Bet time must be more than current time"
    assert _endTime > _bTime, "End time must be more than bet time"
    assert (_aName != _bName) and (_aName != _cName) and (_bName != _cName), "Events names must be different from each other"
    
    # If the number of user events has reached the limit
    if len(self.eventOf[msg.sender]) == MAX_COUNT:
        self.eventOf[msg.sender] = self.rebuildEventOf(msg.sender, 0)
    else:
        self.eventOfCount[msg.sender] += 1

    # Generate event code
    _eventCode: bytes32 = keccak256(concat(convert(currentTime, bytes32), convert(msg.sender, bytes32)))
    temp_decision: String[1] = ""

    new_event: BetEvent = BetEvent({
                                    eventCode: _eventCode,

                                    auditAddress: msg.sender,
                                    name: _name,

                                    createTime: currentTime, 
                                    betTime: _bTime, 
                                    endTime: _endTime,

                                    decision: temp_decision,
                                   
                                    A_weight: 0,
                                    B_weight: 0, 
                                    C_weight: 0,
                                    A_name: _aName,
                                    B_name: _bName,
                                    C_name: _cName,
                                    A_count: 0,
                                    B_count: 0,
                                    C_count: 0,
                                    ended: False,
                                    weight: 0,
                                    })

    self.eventsList[_eventCode] = new_event
    self.eventOf[msg.sender].append(_eventCode) 
    
    log EventCreate(msg.sender, _eventCode, _name)

    return True


@external
def bet(_eventCode: bytes32, _decision: String[1], _amount: uint256) -> bool:

    currentTime: uint256 = self.getTime()  
    assert currentTime  <= self.eventsList[_eventCode].betTime, "The_time_to_bid_has_passed"

    assert self.eventsList[_eventCode].createTime != 0, "Event_doesnt_exist"
    assert (_decision == 'A') or (_decision == 'B') or (_decision == 'C'), "Decision must be called either A or B or C"
    
    assert not self.eventsList[_eventCode].ended, "Event is over"
    assert _amount != 0, "Amount_cannot_be_zero"
    assert self.balanceOf[msg.sender] >= _amount, "insufficient_value"
    
    if self.betOf[msg.sender][_eventCode][_decision].amount == 0:
        if _decision == 'A':
            assert self.eventsList[_eventCode].A_count < (A_range[1] - A_range[0]) * MAX_COUNT, "Bet limit has been reached"
        if _decision == 'B':
            assert self.eventsList[_eventCode].B_count < (B_range[1] - B_range[0]) * MAX_COUNT, "Bet limit has been reached "
        if _decision == 'C':
            assert self.eventsList[_eventCode].C_count < (C_range[1] - C_range[0]) * MAX_COUNT, "Bet limit has been reached"
   
    
    self.balanceOf[msg.sender] -= _amount 
    self.supply -= _amount
    
    if self.betOf[msg.sender][_eventCode][_decision].amount != 0:
        self.betOf[msg.sender][_eventCode][_decision].amount += _amount

        if _decision == 'A': 
            found: bool = False

            for i in range(A_range[0],A_range[1]):
                if found: break

                if  len(self.betList[_eventCode][i]) == 0: continue

                for j in range(MAX_COUNT):
                    if j >= len(self.betList[_eventCode][i]):  break

                    if self.betList[_eventCode][i][j].participant == msg.sender:
                        self.betList[_eventCode][i][j].amount += _amount
                        self.eventsList[_eventCode].A_weight += _amount

                        found = True

                        break


        if _decision == 'B': 
            found: bool = False

            for i in range(B_range[0],B_range[1]):
                if found: break

                if  len(self.betList[_eventCode][i]) == 0: continue

                for j in range(MAX_COUNT):
                    if j >= len(self.betList[_eventCode][i]): break

                    if self.betList[_eventCode][i][j].participant == msg.sender:
                        self.betList[_eventCode][i][j].amount += _amount
                        self.eventsList[_eventCode].B_weight += _amount

                        found = True

                        break

        if _decision == 'C': 
            found: bool = False

            for i in range(C_range[0],C_range[1]):
                if found: break

                if  len(self.betList[_eventCode][i]) == 0: continue

                for j in range(MAX_COUNT):
                    if j >= len(self.betList[_eventCode][i]): break

                    if self.betList[_eventCode][i][j].participant == msg.sender:
                        self.betList[_eventCode][i][j].amount += _amount
                        self.eventsList[_eventCode].C_weight += _amount

                        found = True

                        break
    else:

        self.betOf[msg.sender][_eventCode][_decision].participant = msg.sender
        self.betOf[msg.sender][_eventCode][_decision].amount = _amount
        self.betOfCount[msg.sender] += 1

        if len(self.eventOf[msg.sender]) == MAX_COUNT:
            self.eventOf[msg.sender] = self.rebuildEventOf(msg.sender, 0)
        else:
            self.eventOfCount[msg.sender] += 1

        self.eventOf[msg.sender].append(_eventCode)

        temp_Bid: Bid = Bid({participant: msg.sender, amount: _amount})
        
        if _decision == 'A':
            for i in range(A_range[0],A_range[1]):
                if len(self.betList[_eventCode][i]) != MAX_COUNT:
                    self.betList[_eventCode][i].append(temp_Bid)
                    self.eventsList[_eventCode].A_count += 1
                    self.eventsList[_eventCode].A_weight += _amount

                    break

        if _decision == 'B':
            for i in range(B_range[0],B_range[1]):
                if len(self.betList[_eventCode][i]) != MAX_COUNT:
                    self.betList[_eventCode][i].append(temp_Bid)
                    self.eventsList[_eventCode].B_count += 1
                    self.eventsList[_eventCode].B_weight += _amount

                    break

        if _decision == 'C':
            for i in range(C_range[0],C_range[1]):
                if len(self.betList[_eventCode][i]) != MAX_COUNT:
                    self.betList[_eventCode][i].append(temp_Bid)
                    self.eventsList[_eventCode].C_count += 1
                    self.eventsList[_eventCode].C_weight += _amount

                    break

    self.eventsList[_eventCode].weight += _amount

    if len(self.biggestEvents) < 5:
        exist: bool = False

        for i in range(5):
            if i>= len(self.biggestEvents): break

            if self.biggestEvents[i] == _eventCode:
                exist = True

        if exist:
            self.biggestEvents = self.sortByWeight(self.biggestEvents)
        else:
            self.biggestEvents.append(_eventCode)
            self.biggestEvents = self.sortByWeight(self.biggestEvents)
    else:
        if (self.eventsList[self.biggestEvents[0]].weight < self.eventsList[_eventCode].weight):
            self.biggestEvents[0] = _eventCode
            self.biggestEvents = self.sortByWeight(self.biggestEvents)

    log Bet(msg.sender, _eventCode, _decision, _amount)
    log Transfer(msg.sender,empty(address), _amount)

    return True

@internal
def sortByWeight(arr: DynArray[bytes32, 5]) -> DynArray[bytes32, 5]:
    
    for i in range(5):
        if i>= len(arr): break

        for j in range(5):
            if j>= len(arr): break

            if j<i: continue

            if  self.eventsList[arr[i]].weight > self.eventsList[arr[j]].weight:
                temp: bytes32 = arr[i]

                arr[i] = arr[j]
                arr[j] = temp

    return arr

@internal
def rebuildEventOf(_from: address, index: uint256) -> DynArray[bytes32, MAX_COUNT]:
    arr: DynArray[bytes32, MAX_COUNT] = []

    for i in range(MAX_COUNT):
        if i>= len(self.eventOf[_from]): break
        if i != index:
            arr.append(self.eventOf[_from][i])

    return arr

@external 
def eventDecision(_eventCode: bytes32, _decision: String[1]) -> bool:     
    currentTime: uint256 = self.getTime()

    assert  self.eventsList[_eventCode].auditAddress == msg.sender, "Ownership error" 
    assert not self.eventsList[_eventCode].ended, "Event is over" 
    assert self.eventsList[_eventCode].betTime < currentTime, " Betting time is not over yet"
    assert (_decision == 'A') or (_decision == 'B') or (_decision == 'C'), "Decision must be called either A or B or C"
    
    self.eventsList[_eventCode].ended = True 
    self.eventsList[_eventCode].decision = _decision 
 
    winnersBetsAmount: uint256 = 0 
    losersBetsAmount: uint256 = 0 
    
    feePercent: decimal = 0.025
    validatorPercent: decimal = 0.1

    if _decision == 'A':
        for i in range(A_range[0],A_range[1]):
            if len(self.betList[_eventCode][i]) == 0: continue

            for j in range(MAX_COUNT):
                if j >= len(self.betList[_eventCode][i]): break

                winnersBetsAmount += self.betList[_eventCode][i][j].amount

        for i in range(B_range[0], B_range[1]):   
            if len(self.betList[_eventCode][i]) == 0: continue

            for j in range(MAX_COUNT):
                if j >= len(self.betList[_eventCode][i]): break

                losersBetsAmount += self.betList[_eventCode][i][j].amount

        for i in range(C_range[0],C_range[1]):
            if len(self.betList[_eventCode][i]) == 0: continue

            for j in range(MAX_COUNT):
                if j >= len(self.betList[_eventCode][i]): break

                losersBetsAmount += self.betList[_eventCode][i][j].amount
        

        feeBonus: uint256 = convert(convert(losersBetsAmount, decimal)* feePercent, uint256)
        validatorBonus: uint256 = convert(convert(losersBetsAmount, decimal) * validatorPercent, uint256)
        
        self.supply += (losersBetsAmount + winnersBetsAmount)
        
        self.balanceOf[feeAddress_1] += feeBonus
        self.balanceOf[msg.sender] += validatorBonus
        self.balanceOf[feeAddress_2] += feeBonus

        losersBetsAmount = convert(convert(losersBetsAmount, decimal) * 0.85, uint256)
        sumWinAmount: uint256 = 0
                
        rate: decimal = (1.0 + (convert(losersBetsAmount, decimal) / convert(winnersBetsAmount, decimal)))

        for i in range(A_range[0],A_range[1]):
            if len(self.betList[_eventCode][i]) == 0: continue

            for j in range(MAX_COUNT):
                if j >= len(self.betList[_eventCode][i]): break
                
                betAmount: uint256 = self.betList[_eventCode][i][j].amount
                rateOfBets: decimal = convert(betAmount, decimal) / convert(winnersBetsAmount, decimal)

                winAmount: uint256 = convert(convert(betAmount, decimal) * rate, uint256)
                sumWinAmount += convert(convert(betAmount, decimal) * (rate - 1.0), uint256)
                
                self.balanceOf[self.betList[_eventCode][i][j].participant] += winAmount 

                log Transfer(empty(address), self.betList[_eventCode][i][j].participant, winAmount)
        
        if sumWinAmount < losersBetsAmount:
            self.balanceOf[msg.sender] += (losersBetsAmount - sumWinAmount)
            
            log Transfer(empty(address), msg.sender, losersBetsAmount - sumWinAmount)
        
        log Transfer(empty(address), feeAddress_2, feeBonus)
        log Transfer(empty(address), feeAddress_1, feeBonus)
        log Transfer(empty(address), msg.sender, validatorBonus)


    if _decision == 'B':
        for i in range(B_range[0], B_range[1]):
            if len(self.betList[_eventCode][i]) == 0: continue

            for j in range(MAX_COUNT):
                if j >= len(self.betList[_eventCode][i]): break

                winnersBetsAmount += self.betList[_eventCode][i][j].amount
                
        for i in range(A_range[0],A_range[1]):
            if len(self.betList[_eventCode][i]) == 0: continue

            for j in range(MAX_COUNT):
                if j >= len(self.betList[_eventCode][i]): break

                losersBetsAmount += self.betList[_eventCode][i][j].amount

        for i in range(C_range[0],C_range[1]):
            if len(self.betList[_eventCode][i]) == 0: continue

            for j in range(MAX_COUNT):
                if j >= len(self.betList[_eventCode][i]): break

                losersBetsAmount += self.betList[_eventCode][i][j].amount
        

        feeBonus: uint256 = convert(convert(losersBetsAmount, decimal)* feePercent, uint256)
        validatorBonus: uint256 = convert(convert(losersBetsAmount, decimal)* validatorPercent, uint256)
        
        self.supply += (losersBetsAmount + winnersBetsAmount)

        self.balanceOf[feeAddress_1] += feeBonus
        self.balanceOf[feeAddress_2] += feeBonus
        self.balanceOf[msg.sender] += validatorBonus

        losersBetsAmount = convert(convert(losersBetsAmount, decimal) * 0.85, uint256)
        sumWinAmount: uint256 = 0

        rate: decimal = (1.0 + (convert(losersBetsAmount, decimal) / convert(winnersBetsAmount, decimal)))

        for i in range(B_range[0], B_range[1]):
            if len(self.betList[_eventCode][i]) == 0: continue

            for j in range(MAX_COUNT):
                if j >= len(self.betList[_eventCode][i]): break

                betAmount: uint256 = self.betList[_eventCode][i][j].amount

                winAmount: uint256 = convert(convert(betAmount, decimal) * rate, uint256)
                sumWinAmount += convert(convert(betAmount, decimal) * (rate - 1.0), uint256)

                self.balanceOf[self.betList[_eventCode][i][j].participant] += winAmount
                
                log Transfer(empty(address), self.betList[_eventCode][i][j].participant, winAmount)

        if sumWinAmount < losersBetsAmount:
            self.balanceOf[msg.sender] += (losersBetsAmount - sumWinAmount)
            
            log Transfer(empty(address), msg.sender, losersBetsAmount - sumWinAmount)

        log Transfer(empty(address), feeAddress_1, feeBonus)
        log Transfer(empty(address), feeAddress_2, feeBonus)
        log Transfer(empty(address), msg.sender, validatorBonus)


    if _decision == 'C':
        for i in range(C_range[0],C_range[1]):
            if len(self.betList[_eventCode][i]) == 0: continue

            for j in range(MAX_COUNT):
                if j >= len(self.betList[_eventCode][i]): break

                winnersBetsAmount += self.betList[_eventCode][i][j].amount

        for i in range(A_range[0],A_range[1]):
            if len(self.betList[_eventCode][i]) == 0: continue

            for j in range(MAX_COUNT):
                if j >= len(self.betList[_eventCode][i]): break

                losersBetsAmount += self.betList[_eventCode][i][j].amount

        for i in range(B_range[0], B_range[1]):
            if len(self.betList[_eventCode][i]) == 0: continue

            for j in range(MAX_COUNT):
                if j >= len(self.betList[_eventCode][i]): break

                losersBetsAmount += self.betList[_eventCode][i][j].amount
           
        feeBonus: uint256 = convert(convert(losersBetsAmount, decimal)* feePercent, uint256)
        validatorBonus: uint256 = convert(convert(losersBetsAmount, decimal)* validatorPercent, uint256)
        
        self.supply += (losersBetsAmount + winnersBetsAmount)

        self.balanceOf[feeAddress_1] += feeBonus
        self.balanceOf[feeAddress_2] += feeBonus
        self.balanceOf[msg.sender] += validatorBonus
            
        losersBetsAmount = convert(convert(losersBetsAmount, decimal) * 0.85, uint256)
        sumWinAmount: uint256 = 0

        rate: decimal = (1.0 + (convert(losersBetsAmount, decimal) / convert(winnersBetsAmount, decimal)))

        for i in range(C_range[0],C_range[1]):
            if len(self.betList[_eventCode][i]) == 0: continue
            for j in range(MAX_COUNT):
                if j >= len(self.betList[_eventCode][i]): break

                betAmount: uint256 = self.betList[_eventCode][i][j].amount
                rateOfBets: decimal = convert(betAmount, decimal) / convert(winnersBetsAmount, decimal)

                winAmount: uint256 = convert(convert(betAmount, decimal) * rate, uint256)
                sumWinAmount += convert(convert(betAmount, decimal) * (rate - 1.0), uint256)

                self.balanceOf[self.betList[_eventCode][i][j].participant] += winAmount
                
                log Transfer(empty(address), self.betList[_eventCode][i][j].participant, winAmount)
                
        if sumWinAmount < losersBetsAmount:
            self.balanceOf[msg.sender] += (losersBetsAmount - sumWinAmount)
            
            log Transfer(empty(address), msg.sender, losersBetsAmount - sumWinAmount)

        log Transfer(empty(address), feeAddress_1, feeBonus)        
        log Transfer(empty(address), feeAddress_2, feeBonus)
        log Transfer(empty(address), msg.sender, validatorBonus)

    log EventDecision(_eventCode, _decision, losersBetsAmount) 
 
    return True 

@external
def cancelBid(_eventCode: bytes32, _decision: String[1]) -> bool:

    currentTime: uint256 = self.getTime()

    assert not self.eventsList[_eventCode].ended, "Event is over"
    assert self.eventsList[_eventCode].createTime != 0, "Event_doesnt_exist"
    assert (self.eventsList[_eventCode].endTime < currentTime) or (self.eventsList[_eventCode].betTime >= currentTime), "The event is not over yet or the time for betting has already passed"
    assert self.betOf[msg.sender][_eventCode][_decision].amount != 0, "You did not bet on this event"
    

    if _decision == 'A':
        self.eventsList[_eventCode].A_count -= 1
        self.eventsList[_eventCode].A_weight -= self.betOf[msg.sender][_eventCode][_decision].amount
        self.eventsList[_eventCode].weight -= self.betOf[msg.sender][_eventCode][_decision].amount

        find: bool = False
        for i in range(A_range[0], A_range[1]):
            if find: break

            if len(self.betList[_eventCode][i]) == 0: continue

            for j in range(MAX_COUNT):
                if j >= len(self.betList[_eventCode][i]): break

                if msg.sender == self.betList[_eventCode][i][j].participant:
                    temp: Bid = self.betList[_eventCode][i][len(self.betList[_eventCode][i]) - 1]

                    if len(self.betList[_eventCode][i]) != 0:
                        self.betList[_eventCode][i][j] = temp

                    self.betList[_eventCode][i].pop()

                    find = True

                    break

    if _decision == 'B':
        self.eventsList[_eventCode].B_count -= 1
        self.eventsList[_eventCode].B_weight -= self.betOf[msg.sender][_eventCode][_decision].amount
        self.eventsList[_eventCode].weight -= self.betOf[msg.sender][_eventCode][_decision].amount
        
        find: bool = False

        for i in range(B_range[0], B_range[1]):
            if find: break
            if len(self.betList[_eventCode][i]) == 0: continue

            for j in range(MAX_COUNT):
                if j >= len(self.betList[_eventCode][i]): break

                if msg.sender == self.betList[_eventCode][i][j].participant:
                    temp: Bid = self.betList[_eventCode][i][len(self.betList[_eventCode][i]) - 1]

                    if len(self.betList[_eventCode][i]) != 0:
                        self.betList[_eventCode][i][j] = temp

                    self.betList[_eventCode][i].pop()

                    find = True

                    break
   
    if _decision == 'C':
        self.eventsList[_eventCode].C_count -= 1
        self.eventsList[_eventCode].C_weight -= self.betOf[msg.sender][_eventCode][_decision].amount
        self.eventsList[_eventCode].weight -= self.betOf[msg.sender][_eventCode][_decision].amount
        
        find: bool = False
        for i in range(C_range[0], C_range[1]):
            if find: break

            if len(self.betList[_eventCode][i]) == 0: continue

            for j in range(MAX_COUNT):
                if j >= len(self.betList[_eventCode][i]): break

                if msg.sender == self.betList[_eventCode][i][j].participant:
                    temp: Bid = self.betList[_eventCode][i][len(self.betList[_eventCode][i]) - 1]

                    if len(self.betList[_eventCode][i]) != 0:
                        self.betList[_eventCode][i][j] = temp

                    self.betList[_eventCode][i].pop()

                    find = True

                    break

    findEvent: bool = False

    for i in range(MAX_COUNT):
        if findEvent: break

        if self.eventOf[msg.sender][i] == _eventCode:
            self.eventOf[msg.sender] = self.rebuildEventOf(msg.sender, i)
            findEvent = True

    self.eventOfCount[msg.sender] -= 1
    self.balanceOf[msg.sender] += self.betOf[msg.sender][_eventCode][_decision].amount
    self.supply += self.betOf[msg.sender][_eventCode][_decision].amount

    self.betOf[msg.sender][_eventCode][_decision].amount = 0
    self.betOfCount[msg.sender] -= 1

    if len(self.biggestEvents) > 1:
        self.biggestEvents = self.sortByWeight(self.biggestEvents)

    log Transfer(empty(address), msg.sender, self.betOf[msg.sender][_eventCode][_decision].amount)

    return True


@external
def __init__(_name: String[32],  _symbol: String[32], _decimals: uint8, _supply: uint256, _teamAddress: address, _marketingAddress: address):
    init_supply: uint256 = _supply * 10 ** convert(_decimals, uint256)
    
    self.owner = msg.sender
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals
    self.supply = init_supply
    self.balanceOf[msg.sender] = convert(convert(init_supply, decimal) * 0.3, uint256)

    self.teamAddress = _teamAddress
    self.marketingAddress = _marketingAddress

    self.teamLockedTokens = convert(convert(init_supply, decimal) * 0.2, uint256)
    self.marketingLockedTokens = convert(convert(init_supply, decimal) * 0.05, uint256)

    self.otherLockedTokens = convert(convert(init_supply, decimal) * 0.28, uint256)
    self.presaleLockedTokens  = convert(convert(init_supply, decimal) * 0.15, uint256)
    self.airdropLockedTokens = convert(convert(init_supply, decimal) * 0.02, uint256)

    self.lastUnlockDate_Marketing = 0 
    self.lastUnlockDate_Team = 0

    self.unlocksCount_Team = 0
    self.unlocksCount_Marketing = 0

    self.contractCreateTime = self.getTime()

    log Transfer(empty(address), msg.sender, convert(convert(init_supply, decimal) * 0.3, uint256))