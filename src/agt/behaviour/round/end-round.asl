{begin namespace(lEndRound, local)}

+!end_round
	: .my_name(Me)
<-
	.print("---------------- END OF THE ROUND ----------------");
	!print_metrics;	
	?default::focused(vehicleart,team_artifact,Id1);
	.concat("eis_art_",Me,ArtMeS);
	.term2string(ArtMe,ArtMeS);
	?default::focused(vehicleart,ArtMe,Id2);
	?default::joined(vehicleart,Id3);
	?default::joined(main,Id4);
	?default::joined(org,Id5);
	if (Me == vehicle1) { ?initiator::task_id(TaskId); }
	.abolish(_::_[source(_)]);
	+default::focused(vehicleart,team_artifact,Id1);
	+default::focused(vehicleart,ArtMe,Id2);
	+default::joined(vehicleart,Id3);
	+default::joined(main,Id4);
	+default::joined(org,Id5);
	if (Me == vehicle1) { +initiator::task_id(TaskId); }
    .drop_all_intentions;
    .drop_all_desires;
    .drop_all_events;	
	.

@change[atomic]
+!change_round
	: .my_name(Me)
<-
	if (Me == vehicle1) { clearMaps; }
	!end_round;
	resetMap;
	!new::new_round;
	.	

@metrics[atomic]
+!print_metrics
	: .my_name(vehicle1) 
<-
	.print("--- Some Metrics ---");
	?metrics::money(Money); // Ok
	.print("Total amount of money: ",Money);
	?metrics::completedJobs(JobsCompleted); // Ok
	.print("Number of completed jobs: ",JobsCompleted); 
	?metrics::failedJobs(JobsFailed); // Ok
	.print("Number of failed jobs: ",JobsFailed);
	?metrics::failedEvalJobs(JobsEvalFailed); // Ok
	.print("Number of jobs that failed eval: ",JobsEvalFailed);
    ?metrics::failedFreeJobs(JobsFreeFailed); // Ok
    .print("Number of jobs that we ignored (not enough free agents): ",JobsFreeFailed);
	?metrics::completedAuctions(AuctionsCompleted); // Ok
	.print("Number of completed auctions: ",AuctionsCompleted); 
	?metrics::lostAuctions(AuctionsLost); // Ok
	.print("Number of lost auctions: ",AuctionsLost); 
	?metrics::failedAuctions(AuctionsFailed); // Ok
	.print("Number of failed auctions: ",AuctionsFailed); 	
	?metrics::completedMissions(MissionsCompleted); // Ok
	.print("Number of completed missions: ",MissionsCompleted); 
	?metrics::failedMissions(MissionsFailed); // Ok
	.print("Number of failed missions: ",MissionsFailed); 
	?metrics::finePaid(Fine); // Ok
	.print("Fine paid: ",Fine);
	?metrics::noBids(NoBids); // Ok
	.print("Number of no bids: ",NoBids);
	?metrics::missBidAuction(MissBids); // Ok
	.print("Number of missed bids for auctions: ",MissBids);
	!print_common_metrics;
	.print("--------------------");
	.	
+!print_metrics
<-
	.print("--- Some Metrics ---");
	!print_common_metrics;
	.print("--------------------");
	.
+!print_common_metrics
<-
	?metrics::noAction(NoActions); // Ok
	.print("Number of no actions: ",NoActions);
	?metrics::next_actions(DoubleActions); // Ok
	.print("Number of double actions: ",DoubleActions);
	?metrics::jobHaveWorked(Jobs); // Ok
	.print("Jobs I have worked: ",Jobs); // Ok
	?metrics::jobHaveFailed(JobsFail); // Ok
	.print("Jobs I have failed: ",JobsFail);
	?metrics::auctionHaveFailed(AuctionFail);  // Ok
	.print("Auctions I have failed: ",AuctionFail);
	?metrics::missionHaveFailed(MissionsFail);  // Ok
	.print("Missions I have failed: ",MissionsFail);
	.

{end}

+default::simEnd 
<- 
	unsetReady;
	!lEndRound::change_round;
	.