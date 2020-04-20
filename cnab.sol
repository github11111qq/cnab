pragma solidity ^0.5.7;


contract CNAB{


struct  Player {

    uint256 pID;       
    address payable addr;   
    uint256 affId;     
    uint256 totalBet;   

    uint256 curGen;    
    uint256 curAff;     
    string  inviteCode;
   
    uint256 lastBet;    
    uint256 lastReleaseTime;
    bool    isaffer;   
   
   
    uint256 createTime; 
   
    uint256 baseGen;    
    uint256 baseAff;    
    
    uint256 baseAffed; 
  
}



struct playerPot {
    uint256 jiechupot;
    uint256 luckpot;
    uint256 zhuoyuepot;
    
}


struct levelReward {    
    uint256 genRate; 
    uint256 deepAff;   

}


uint256 ethWei = 1 ether;

 uint256  private minbeteth_ = ethWei;           
 uint256 constant private getoutBeishu = 3;                 
 uint256 public nextId_ = 1;                               
 uint256  genReleTime_ = 1  days;                  
 bool public activated_ = true;     
 mapping (string   => uint256) public pIDInviteCode_;
 mapping (address => uint256)   public pIDxAddr_;          
 mapping (uint256 => Player)    public plyr_;              
 mapping (uint256 => playerReward) public plyrReward_;      


 uint256 public gBet_ = 0 ;
 uint256 public gWithDraw_ = 0;
 uint256 public gBetcc_ =0;


 address payable constant public cto = 0xa19A248BF2275A7f8275176eE2A3Cb94900856E6;
 address payable constant public bx = 0x9D993A189D627B4082b8A0aBB3D9667F8b15B8ca;
 address payable constant public bose = 0x1B865E52F41E554860c1F5870782BD792c39a29F;
 address payable constant public st = 0xECFa9C95A3E61513413c1096ce79752b8482b292;
 uint256[30] affRate = [300,200,100,80,50,50,50,50,50,50,30,30,30,30,30,10,10,10,10,10,5,5,5,5,5,5,5,5,5,5];
 
 bool public stopStatus_ = false; 
 uint256 public stopTime_ = 0;
 
 
 uint256 public insuranceStartTime_ = 0; 
 uint256 public insuranceTime_ = 72 hours;
 address public openInsurancer;


uint256 public luckyPot_ = 0;
uint256 public openLuckycc_ = 100;
uint256  public  luckyRound_ = 1;



uint256 public zhuoyuePot_ = 0;
uint256 public zuoyuePotDaoshuTime_ = 240 hours;
uint256 public zuoyuePotDaoshuStartTime_ = 0;
uint256  public  zhuoyueRound_ = 1;

uint256 public bxTotalCoin = 0; 
uint256 public stTotalCoin = 0;


modifier isActivated() {
    require(activated_ == true, "its not ready yet.  check ?eta in discord");
    _;
}

modifier isHuman() {
    address _addr = msg.sender;
    uint256 _codeLength;

    assembly {_codeLength := extcodesize(_addr)}
    require(_codeLength == 0, "sorry humans only");
    _;
}


modifier isWithinLimits(uint256 _eth) {
    require(_eth >= minbeteth_, "pocket lint: not a valid currency");
    require(_eth <= 100000000000000000000000, "no vitalik, no");
    _;
}

constructor()
public
{
    levelReward_[1] = levelReward(6,1);
    levelReward_[2] = levelReward(8,10);
    levelReward_[3] = levelReward(9,20);
    levelReward_[4] = levelReward(10,30);
    insuranceStartTime_ = now;
    zuoyuePotDaoshuStartTime_ = now;
}




 function ethcomein(string memory _inviteCode,string memory _referrer)
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
        
        determinePID(_inviteCode);
        
        // fetch player id
        uint256 _pID = pIDxAddr_[msg.sender];
        uint256 _affID = pIDInviteCode_[_referrer];
        
        require(checkInviteCode(_inviteCode) == _pID,"cannot to bet!");
        // manage affiliate residuals
        // if no affiliate code was given or player tried to use their own, lolz
        
       
        if(_affID != 0 && _affID != _pID && plyr_[_affID].isaffer && plyr_[_pID].affId ==0 && checkAffid(_pID,_affID))
        {
            plyr_[_pID].affId = _affID;
            //plyr_[_affID].invites++;
            
        }
    
        // buy core
        buyCore(_pID,msg.value);
    }





function buyCore(uint256 _pID,uint256 _eth)
    private
{
    
    
   uint256 _com = _eth.mul(2)/100;
    if(_com>0){
        bose.transfer(_com);
    }
        
   uint256 _st = _eth.mul(3)/100;
    if(_st>0){
        st.transfer(_st);
        stTotalCoin = stTotalCoin.add(_st);
    }
   
    uint256 _baoxian = _eth.mul(1)/100;
    if(_baoxian>0){
        
         if(now > insuranceStartTime_.add(insuranceTime_)){
            openInsurancer = msg.sender;
            bxTotalCoin = 0;
        }
        
        insuranceStartTime_ = now;
        bx.transfer(_baoxian);
        bxTotalCoin = bxTotalCoin.add(_baoxian);
    }
    
    gBet_ = gBet_.add(_eth);
    gBetcc_= gBetcc_ + 1; 
  
    dealwithluckyPot(_pID,_eth);
    dealwithZhuoyuePot(_eth);
    
    checkOut(_pID);
    
    plyr_[_pID].totalBet = _eth.add(plyr_[_pID].totalBet);
    plyr_[_pID].lastBet  = _eth;
    plyrReward_[_pID].reward = _eth.mul(getoutBeishu).add(plyrReward_[_pID].reward);

    if(!plyr_[_pID].isaffer){
        plyr_[_pID].isaffer = true;
    }
    
    plyrReward_[_pID].level = getLevel(plyr_[_pID].totalBet);
 
    plyr_[_pID].lastReleaseTime = now;
  


   
}


function checkInviteCode(string memory _code)  public view returns(uint256 _pID){
    
    _pID = pIDInviteCode_[_code];
    
}



function getLevel (uint256 _betEth) 
public
view
returns(uint8 level) 
{
    uint8 _level = 0;
     if(_betEth>=31 * ethWei){
        _level = 4;

    }else if(_betEth>=11 * ethWei){
        _level = 3;

    }else if(_betEth>=6 * ethWei){
        _level = 2;

    }else if(_betEth>=1 * ethWei){
        _level = 1;

    }
    return _level;
}


function getPlayerlaByAddr (address _addr)
public
view
returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)
{
    uint256 _pID = pIDxAddr_[_addr];
    
    (uint256 _gen,uint256 _aff,) = getUserRewardByBase(_pID);
    
    uint256 totalGenH =  plyrReward_[_pID].totalGen - plyrReward_[_pID].withDrawEdGen + _gen;
    uint256 totalAffH =  plyrReward_[_pID].totalAff - plyrReward_[_pID].withDrawEdAff + _aff;
    
    return(
        _pID,
        plyrReward_[_pID].reward.sub(plyr_[_pID].curGen + plyr_[_pID].curAff+_gen+_aff)>0?plyrReward_[_pID].reward.sub(plyr_[_pID].curGen + plyr_[_pID].curAff+_gen+_aff):0,
        plyrReward_[_pID].totalGen + _gen,
        plyrReward_[_pID].totalAff + _aff,
        totalGenH,
        totalAffH,
        withDrawSet_[_pID].shengyu,
        plyr_[_pID].baseGen,
        plyr_[_pID].baseAff,
        affBijiao_[zhuoyueRound_][_pID]
        
        );


}


function getPlayerlaById (uint256 _pID)
public
view
returns(uint256 affid,address addr,uint256 totalBet,uint256 level,uint256 withDrawEdGen,uint256 withDrawEdAff,string memory inviteCode,string memory affInviteCode)
{
   require(_pID>0 && _pID < nextId_, "Now cannot withDraw!");
   
    affid =  plyr_[_pID].affId;
    addr  = plyr_[_pID].addr;
    totalBet = plyr_[_pID].totalBet;
    level = plyrReward_[_pID].level;
    withDrawEdGen = plyrReward_[_pID].withDrawEdGen;
    withDrawEdAff = plyrReward_[_pID].withDrawEdAff;
    inviteCode = plyr_[_pID].inviteCode;
    affInviteCode =plyr_[plyr_[_pID].affId].inviteCode;
      


}


function getsystemMsg()
public
view
returns(uint256 _gbet,uint256 _gcc,uint256 _luckpot,uint256 _zypot,uint256 _zytime,uint256 _bxTotalCoin,uint256 _luckround,uint256 _zyround,uint256 _stcoin,uint256 _bxTime)
{
    return
    (
        gBet_,
        gBetcc_,
        luckyPot_,
        zhuoyuePot_,
        zuoyuePotDaoshuTime_+zuoyuePotDaoshuStartTime_,
        bxTotalCoin,
        luckyRound_,
        zhuoyueRound_,
        stTotalCoin,
        insuranceStartTime_ + insuranceTime_
        
        
    );
}

}
