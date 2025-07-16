// SPDX-License-Identifier: MIT
pragma solidity  0.8.30;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract PromotiumPostA is Ownable{ 

     //State Variables
     address immutable PROMO;  
     uint public  PLATFORM_FEE;
     uint public  accumulatedFee;
     uint postIdCount;
     
     ///Events
     event POSTCREATED(address advertisor,uint postID, bytes32 hash);
     event POSTDELETED(address advertisor,uint postID, bytes32 hash);
     event POSTINTERACTION(address promoter, uint postID);

     constructor(
     address _promo
     ) Ownable(msg.sender){
       PROMO  = _promo;
       accumulatedFee = 0;
       PLATFORM_FEE = 1e16; //Setting Platform fee to 1%
       postIdCount = 1;
     }

    /// @notice Ordinary Post Metadata
     struct POSTA {
        bytes32 hash;
        address advertisor;
        uint rewardPerInteraction;
        uint maxInteraction;
        uint interactionCount;
     }
     ///@notice mapping of ID to its Post 
     mapping(uint=>POSTA) public posts;
    
    /// @notice mapping to keep track of interactions for each post
     mapping(uint=>mapping(address=>bool)) public hasInteracted;
     

     /// @notice allows advertisors to create post, only post's metadata is stored onchain.
     /// @dev a user needs to allowcate rewards + fee in promo tokens to this contract before calling this function. 
     
   /// @param _rewardPerInteraction  Reward for each promoters interaction in wei.
   /// @param _maxInteraction Max number of interaction allowed.

   /// @param _hash is calculated offchain and includes post metadata + post content(head + body), 
   /// at any  time a user can verify offchain and onchain stored data by comparing the hashes 
   
     function createPost(
        uint _rewardPerInteraction, 
        uint _maxInteraction, 
        bytes32 _hash
     ) public returns (uint) { 
        uint totalAmount  =  _rewardPerInteraction * _maxInteraction;
        uint fee = (totalAmount*PLATFORM_FEE)/1e18;
        totalAmount += fee;
        accumulatedFee += fee;
        IERC20 erc = IERC20(PROMO);
        require(erc.allowance(msg.sender, address(this)) >= totalAmount, "Not Enough Reward Tokens Approved");
        erc.transferFrom(msg.sender, address(this), totalAmount);
        posts[postIdCount]  = POSTA(_hash,msg.sender,_rewardPerInteraction,_maxInteraction,0);
        emit  POSTCREATED(msg.sender, postIdCount, _hash);
        return  postIdCount++;
     }


   /// @notice Interact Post can only be called by owner that verifies that a promoter have 
   /// successfully compeleted the interaction requirements offchain. This function automatically send
   /// rewards the promoter


   ///@param _postID id for the post
   ///@param _promoter address of the promoter that have compeleted the post requirements.

     function interactPost(
        uint _postID, 
        address _promoter
        ) onlyOwner public returns(bool) {
       require(!hasInteracted[_postID][_promoter], "Already interacted with this post");
       require(posts[_postID].maxInteraction > posts[_postID].interactionCount, "Posts Exhausts");
       hasInteracted[_postID][_promoter] = true; 
       posts[_postID].interactionCount++;
       IERC20 erc = IERC20(PROMO);
       erc.transfer(_promoter, posts[_postID].rewardPerInteraction);
       emit POSTINTERACTION(_promoter, _postID);
       return  true;
     } 


     ///@notice function to delete a post, can only be called the post creater (advertisor), sends remaining used reward tokens.
     ///@param _postID id of the post.
     function deletePost(
        uint _postID
       ) public returns(bool){
      POSTA storage post = posts[_postID];
      require(msg.sender == post.advertisor,"Not Authorized");
      uint remainingTokens = (post.maxInteraction - post.interactionCount)*post.rewardPerInteraction;
      if(remainingTokens!=0)
            IERC20(PROMO).transfer(msg.sender,remainingTokens);
      emit POSTDELETED(post.advertisor, _postID, post.hash);      
      delete posts[_postID];
      return  true;
     }


     ///@notice extractPlatformfee can ony be called the owner, sends the fee collected from advertisors
     ///@param _target address which will receive the tokens.
     function extractPlatformFee(
      address _target
     ) onlyOwner public  { 
      IERC20(PROMO).transfer(_target,accumulatedFee);
      accumulatedFee  = 0;
     }

  
}