::current_token(0).
+!commit_action(Action)
	: .current_intention(intention(IntentionId,_)) & not ::access_token(IntentionId,_) & ::current_token(Token)
<-
	.print("It's my first access, receiving a token ",Token," ",Action," ",IntentionId);
	+::access_token(IntentionId,Token);
	!commit_action(Action);
	.
+!commit_action(Action)
	: .current_intention(intention(IntentionId,_)) & ::access_token(IntentionId,IntentionToken) & ::current_token(Token) & IntentionToken < Token
<-
	.print("My access was revogated, my ",IntentionToken," current ",Token,", shutting down!");
	-::access_token(IntentionId,_);
	.drop_intention;
	.
+!commit_action(Action)
	: default::actionID(Id) & action::action_sent(Id) & metrics::next_actions(C) & default::step(Step)
<-
	.print("I've already sent an action at step ",Step,", I cannot send a new one ", Action);
	-+metrics::next_actions(C+1); 
	.wait({+default::actionID(_)}); 
	!commit_action(Action);
	.
+!commit_action(Action)
	: default::actionID(Id) & not action::action(Id,_) & .current_intention(intention(IntentionId,_))
<-
	.abolish(action::action(_,_)); // removes all the possible last actions
	+action::action(Id,Action);
	.print("Doing action ",Action, " for ",IntentionId," at step ",Id," . Waiting for step ",Id+1);
//	if ( Action \== recharge & Action \== continue) {
//		.print("Doing action ",Action, " at step ",S," . Waiting for step ",S+1);
//	}
	
	!!wait_request_for_help(Id);
	chosenAction(Id);
//	.wait( default::actionID(Id2) & Id2 \== Id & not action::reasoning_about_belief(_)); 
	.wait({+default::actionID(_)}); 
	.wait(not action::reasoning_about_belief(_)); 
	
	-::action(Id,Action);
	-::action_sent(Id);
	-::committedToAction(Id);
	
	?default::lastActionResult(Result);
	.print("Last action result ",IntentionId," was: ",Result);
	
	?default::lastAction(LastAction);
	if (LastAction == noAction | LastAction == randomFail){
		.print("My action was replaced by ",LastAction,", sending true action again");
		!commit_action(Action); // repeat the previous action
	}else{
		if (Result \== successful & Result \== successful_partial){
			if (Action \== recharge & Action \== continue & not .substring("assist_assemble",Action) & Result == failed){
				.print("Failed to execute action ",Action," with actionId ",Id,". Executing it again.");
				!commit_action(Action);
			} else{
				.print("Failing action ",Action," because ",Result);
				.fail(action(Action),result(Result));
			}
		}
	}
	
//	if (Action \== recharge & Action \== continue & not .substring("deliver",Action) & not .substring("assist_assemble",Action) & not .substring("buy",Action) & not .substring("bid_for_job",Action) & Result \== successful) {
//		.print("Failed to execute action ",Action," with actionId ",Id,". Executing it again.");
////		!commit_action(Action);
//		.fail(action(Action),result(Result));
//	}
//	else {
//		if (.substring("deliver",Action) & Result == failed ) { !commit_action(Action); }
//		if (.substring("deliver",Action) & Result \== failed_job_status & default::winner(_, assemble(_, JobId, _))) { +strategies::jobDone(JobId); }
//		if (strategies::free) { !!action::recharge_is_new_skip; }
//	}
	.
//+!commit_action(Action) : Action == recharge <- .wait({+default::actionID(_)});.
+!commit_action(Action) : Action == recharge <- .suspend;.
//+!commit_action(Action) : .print(">>>>>>>>>>>>>>>>>>> Plano nao encontrado ",Action) & False.
+!commit_action(Action)
	: default::actionID(Id) & action::action(Id,ChosenAction) & ChosenAction \== recharge & .current_intention(intention(IntentionId,_))
<-
	.print("I've already picked an action ",ChosenAction," for ",Id," trying ",Action," next. I am ",IntentionId);
	.drop_all_intentions;
	.print("WE HAVE A BUG");
	.drop_intention;
	.
+!commit_action(Action)
	: default::actionID(Id) & action::action(Id,ChosenAction) 
<-
	.print("I've already picked an action ",ChosenAction," for ",Id," trying ",Action," next");
	.wait({+default::actionID(_)}); 
	!commit_action(Action);
	.

+!update_percepts
	: ::action_sent(Id)
<-
	.print("An action has been sent to the Server, I have to wait for the perceptions to be updated");
//	.wait(default::actionID(Id2) & Id2 \== Id);
	.wait({-::action_sent(_)});
	. 
+!update_percepts.
@forgetParticularGoal[atomic]
+!forget_old_action(Module,Goal) 
	: not ::action_sent(_) & default::actionID(ActionId)
<- 
	.print("I Have a desire ",Module,"::",Goal,", forgetting it");
	
	.drop_desire(Module::Goal); // we don't want to follow these plans anymore
	.drop_intention(Module::Goal);
	
	if(::action(ActionId,Action)){
		.drop_desire(::wait_request_for_help(ActionId));
		-::action(ActionId,Action);
	}
	
	+::committedToAction(ActionId);
	.	
+!forget_old_action(Module,Goal) 
<-	
	!update_percepts;
	!forget_old_action(Module,Goal) ;
	.
	
+!forget_old_action
	: ::action_sent(_)
<-
	!revogate_tokens;
	!update_percepts;
	.
@forgetCommitAction[atomic]
+!forget_old_action
	: default::actionID(ActionId)
<-
	!revogate_tokens;
	.print("Dropping all intentions that aim to send an action to the Server");
	.drop_desire(::commit_action(_));
	.drop_future_intention(::commit_action(_)); // we don't want to follow these plans anymore
	if(::action(ActionId,Action)){
		.drop_desire(::wait_request_for_help(ActionId));
		-::action(ActionId,Action);
	}
	+::committedToAction(ActionId);
	.print("Finished dropping all intentions");
	.
+!forget_old_action
<-	
	!update_percepts;
	!forget_old_action;
	.
@revogate[atomic]
+!revogate_tokens
	: ::current_token(Token)
<-
	.print("Revogating older tokens...");
	-+::current_token(Token+1);
	.

@helprequest[atomic]
+default::chosenActions(ActionId, Agents) // all the agents have chosen their actions
	: .length(Agents) == 34 & not ::committedToAction(ActionId) & not ::action_sent(ActionId)
<-
	.print("All agents have chosen their action on ",ActionId,", dropping wait_request_for_help");
	.drop_desire(::wait_request_for_help(ActionId));
	.drop_intention(::wait_request_for_help(ActionId));
	!send_action_to_server(ActionId);
	.
+!wait_request_for_help(ActionId)
	: ::committedToAction(ActionId)
<-
	.print("I'm strong commited to help someone else on ",ActionId);
	!send_action_to_server(ActionId);
	.abolish(::committedToAction(_));
	.	
+!wait_request_for_help(ActionId)
<-
	.print("Waiting for help request on ",ActionId);
	.wait(1000);
	.print("Time has gone on ",ActionId);
	!send_action_to_server(ActionId);
	.	
	
@sendAction[atomic]
+!send_action_to_server(ActionId)
	: not action::action_sent(ActionId) & action::action(ActionId,Action) & default::step(Step)
<-
	.print("Sending ",Step," ",Action);
	action(Action);
	+action::action_sent(ActionId);
	.
+!send_action_to_server(ActionId)
<-
	.print("SHOULDN'T PASS HERE ON ",ActionId);
	. // action already sent to the server

