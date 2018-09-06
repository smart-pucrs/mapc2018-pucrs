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
	: default::actionID(Id) & not action::action(Id,_) 
<-
	.abolish(action::action(_,_)); // removes all the possible last actions
	+action::action(Id,Action);
	chosenAction(Id);
	.print("Doing action ",Action, " at step ",Id," . Waiting for step ",Id+1);
//	if ( Action \== recharge & Action \== continue) {
//		.print("Doing action ",Action, " at step ",S," . Waiting for step ",S+1);
//	}
	
	!!wait_request_for_help(Id)
//	.wait( default::actionID(Id2) & Id2 \== Id & not action::reasoning_about_belief(_)); 
	.wait({+default::actionID(_)}); 
	.wait(not action::reasoning_about_belief(_)); 
	
	-action::action(Id,Action);
	-action::action_sent(Id);
	
	?default::lastActionResult(Result);
	.print("Last action result was: ",Result);
		
	if (Result \== successful & Result \== successful_partial){
		if (Action \== recharge & Action \== continue & not .substring("assist_assemble",Action) & Result == failed){
			//		.print("Failed to execute action ",Action," with actionId ",Id,". Executing it again.");
			!commit_action(Action);
		} else{
			.print("Failing action ",Action," because ",Result);
			.fail(action(Action),result(Result));
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
//@forgetParticularGoal[atomic]
+!forget_old_action(Module,Goal) 
	: not ::action_sent(_)
<- 
	.print("I Have a desire ",Module,"::",Goal,", forgetting it");
	
	.drop_desire(Module::Goal); // we don't want to follow these plans anymore
	.wait(200);
	.drop_desire(Module::Goal);
	
	if(action::action(ActionId,Action)){
		.drop_desire(action::wait_request_for_help(ActionId));
		-action::action(ActionId,Action);
	}
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
<-
	!revogate_tokens;
	.print("Dropping all intentions that aim to send an action to the Server");
	.drop_future_intention(action::commit_action(_)); // we don't want to follow these plans anymore
	if(action::action(ActionId,Action)){
		.drop_desire(action::wait_request_for_help(ActionId));
		-action::action(ActionId,Action);
	}
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


+default::chosenActions(ActionId, Agents) // all the agents have chosen their actions
	: .length(Agents) == 34
<-
	.drop_desire(action::wait_request_for_help(ActionId));
	!send_action_to_server(ActionId);
	.
+!wait_request_for_help(ActionId)
	: action::committedToAction(ActionId)
<-
	!send_action_to_server(ActionId);
	.abolish(action::committedToAction(_));
	.	
+!wait_request_for_help(ActionId)
<-
	.wait(1000);
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
+!send_action_to_server(ActionId). // action already sent to the server

