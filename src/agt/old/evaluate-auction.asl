evaluateBid(Reward,0,BaseBid,MyBid) 			:- MyBid = Reward-(BaseBid+6).
evaluateBid(Reward,CurrentBid,BaseBid,MyBid) 	:- MyBid = CurrentBid-(BaseBid+6).

checkPossibleBid(Reward,CurrentBid,BaseBid,Limit) 		:- ::evaluateBid(Reward,Bid,BaseBid,NewBid) & (Limit <= NewBid).
checkLimit(Reward,0,Limit) 								:- (Limit < Reward).
checkLimit(Reward,CurrentBid,Limit) 					:- (Limit < Reward) & (Limit < CurrentBid).
checkStillGoodAuction(Reward,CurrentBid,BaseBid,Limit) 	:- checkLimit(Reward,CurrentBid,Limit) & checkPossibleBid(Reward,CurrentBid,BaseBid,Limit).

//!triggerFuturePlan.

+!triggerFuturePlan
	: default::step(Step) & ::futurePlans(Event,StepFuture) & (StepFuture <= Step) 
<-
//	.print("Triggering plan ",Event," at step ",Step);
    !!Event;
    -::futurePlans(Event,StepFuture);
    !triggerFuturePlan;
	.
+!triggerFuturePlan
<-
	.wait({+default::step(Step)});
	!triggerFuturePlan;
	.

+!first_analysis(Id)	
	: default::auction(Id,_,Reward,Start,_,_,0,Time,Items)
<-
	.print("First analysis auction ",Id);	
	!initiator::decompose(Items,ListItems,ListToolsNew,Id);

	?default::check_price(ListToolsNew,ListItems,0,ResultP);
	Limit = math.ceil(ResultP*1.1);	
	
	+::bidding(Id,0,0,Limit);
	+::futurePlans(free_for_next_auction(Id),Start+Time);	
	
	if (Limit < Reward) {
		!::choose_between_auctions_at_same_step(Id,Start+Time-1);		
	}
	else{
		.print("Expected limit to bid ",Limit," is greater than the reward ",Reward);
	}
	.
	
+!choose_between_auctions_at_same_step(AuctionId,StartTime)
	: ::futurePlans(further_analysis(Id),StartTime)
<- 
	.print("There is other auction ",Id," at the same future step ",StartTime);
	
	?default::auction(Id,_,RewardOld,_,_,_,_,_,_);
	?default::auction(AuctionId,_,RewardCurrent,_,_,_,_,_,_);
	
	if (RewardCurrent > RewardOld){
		-::futurePlans(further_analysis(Id),StartTime);
		+::futurePlans(further_analysis(AuctionId),StartTime);
	}
	.
+!choose_between_auctions_at_same_step(AuctionId,StartTime)
<- 
	+::futurePlans(further_analysis(AuctionId),StartTime);
	.

@further[atomic]
+!further_analysis(Id)
	: not initiator::cnp(_)
<- 
	+action::hold_action(Id);
	!strategies::not_free;	
	+::hasSetFree;
	!check_further_analysis(Id);
	.
+!further_analysis(Id).	
+!check_further_analysis(Id)	
	: action::actionID(S) & action::action(S) & metrics::missBidAuction(M)
<-	
	-action::hold_action(Id);
	!::has_set_to_free;
		
	.print("¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬ We lost the action at step ",S," we cannot bid for ",Id," anymore");	
	-+metrics::missBidAuction(M+1);
	.
+!check_further_analysis(Id)	
	: default::auction(Id,Storage,Reward,Start,End,Fine,Bid,Time,Items)	& ::bidding(Id,_,BaseBid,Limit) & ::checkStillGoodAuction(Reward,Bid,BaseBid,Limit) & default::step(S)
<-
	.print("Final analysis for ",Id," at step ",S);	
	
	!initiator::evaluate_job(Items, End, Storage, Id, Reward);
	.
+!check_further_analysis(Id)	
<-
	-action::hold_action(Id);
	!::has_set_to_free;
	.print(Id," is not a good auctionJob anymore");	
	.
	
+!has_set_to_free
	: (not default::winner(_,_) | strategies::waiting ) & ::hasSetFree 
<-
	-::hasSetFree;
	!!strategies::free;
	.
+!has_set_to_free
	: ::hasSetFree 
<-
	-::hasSetFree;
	.
+!has_set_to_free.
	
+!analyse_bid_posted(Id)
	: ::bidding(Id,0,_,Limit) & default::auction(Id,_,Reward,_,_,_,Bid,_,_)
<-
	.print("Someone post a initial bid ",Bid," for ",Id,", it decreases in ",Reward-Bid);
	-::bidding(Id,0,_,Limit);
	+::bidding(Id,Bid,Reward-Bid,Limit);
	.
+!analyse_bid_posted(Id)
	: ::bidding(Id,LastBestBid,IncreaseBid,Limit) & default::auction(Id,_,_,_,_,_,Bid,_,_)
<-
	-::bidding(Id,LastBestBid,IncreaseBid,Limit);
	.print("Someone post bid ",Bid," for ",Id,", it decreases in ",LastBestBid-Bid);
	if ((LastBestBid-Bid) > IncreaseBid){		
		+::bidding(Id,Bid,LastBestBid-Bid,Limit);
	}
	else{
		.print("Other team has posted a better bid");
		+::bidding(Id,Bid,IncreaseBid,Limit);
	}
	.

+!send_a_bid(Id)
	: default::auction(Id,_,Reward,Start,_,_,Bid,Time,_) & ::bidding(Id,_,BaseBid,Limit)	
<-
	?::evaluateBid(Reward,Bid,BaseBid,NewBid);
	
	+::futurePlans(figure_out_auction_winning(Id),Start+Time);
	
	.print("Posting bid of ",NewBid);
	?default::actionID(S);
	action(bid_for_job(Id,NewBid));
	.wait( default::actionID(S2) & S2 \== S );
	.
-!send_a_bid(Id).

+!free_for_next_auction(AuctionId) 
	: ::bidding(AuctionId,_,_,_) 
<- 
	-::bidding(AuctionId,_,_,_);
	. 
	
+!figure_out_auction_winning(JobId)
	: default::auction(JobId,_,_,_,_,_,_,_,_) & default::joined(org,OrgId)
<-
	.print("We win auction ",JobId);
	
	if (not initiator::awarded(_,_,_,JobId,_)) {
		!initiator::create_scheme(JobId, oneagent, SchArtId,OrgId);
	}
	else { !initiator::create_scheme(JobId, st, SchArtId,OrgId); }
	?initiator::awarded_assemble(AgentA,Items,Storage,AssTaskList,JobId,AssTaskCount);
	-initiator::awarded_assemble(AgentA,Items,Storage,AssTaskList,JobId,AssTaskCount);
	
	-initiator::free_trucks_auction(JobId,_);
	-initiator::free_agents_auction(JobId,_);
	
	for ( initiator::awarded(Agent,Shop,List,JobId,TaskCount) ) {
		.send(Agent,tell,winner(List,assist(Storage,AgentA,JobId)));
		-initiator::awarded(Agent,Shop,List,JobId,TaskCount);	
//		.print(Agent," ",AgentA," ",List);
	}
	.send(AgentA,tell,winner(Items,assemble(Storage,JobId,AssTaskList)));
//	.print(AgentA," ",Items);
	.
@loseAuction[atomic]
+!figure_out_auction_winning(JobId) 
	: metrics::lostAuctions(L)
<- 
	.print("We lost auction ",JobId);
	
	-+metrics::lostAuctions(L+1);
	
	?initiator::free_trucks_auction(JobId,FreeTrucksAuction);
	-initiator::free_trucks_auction(JobId,FreeTrucksAuction);
	?initiator::free_trucks(FreeTrucksA);			
	.concat(FreeTrucksAuction,FreeTrucksA,FreeTrucksNewA);			
	-+initiator::free_trucks(FreeTrucksNewA);
	
	?initiator::free_agents_auction(JobId,FreeAgentsAuction);
	-initiator::free_agents_auction(JobId,FreeAgentsAuction);
	?initiator::free_agents(FreeAgents);
	.concat(FreeAgentsAuction,FreeAgents,FreeAgentsNew);
	-+initiator::free_agents(FreeAgentsNew);
	
	-job(JobId,_);
	-awarded_assemble(_,_,_,_,JobId,_);
	-eval(JobId);
	.abolish(initiator::bids(_,_,JobId));
	.abolish(initiator::awarded(_,_,_,JobId,_));
	.