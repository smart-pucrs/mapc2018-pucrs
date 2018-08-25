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
	.wait( default::actionID(Id2) & Id2 \== Id & not action::reasoning_about_belief(_)); 
	
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

+!forget_old_action(ActionId) <- !forget_old_action.	
@forgetAction[atomic]
+!forget_old_action
	: .desire(action::commit_action(Action))
<-
	.print("I Have a desire ",Action,", forgetting it");	
	.drop_desire(action::commit_action(Action)); // we don't want to follow these plans anymore
	if(action::action(ActionId,Action)){
		.drop_desire(action::wait_request_for_help(ActionId));
		-action::action(ActionId,Action);
	}
	!forget_old_action;
	.
+!forget_old_action.

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

