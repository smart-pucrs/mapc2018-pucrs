
+!commit_action(Action)
	: default::actionID(S) & not action::action(S,_)
<-
	.abolish(action::action(_,_)); // removes all the possible last actions
	+action::action(S,Action);
	actionChoosed(S);
//	.print("Doing action ",Action, " at step ",S," . Waiting for step ",S+1);
//	if ( Action \== recharge & Action \== continue) {
//		.print("Doing action ",Action, " at step ",S," . Waiting for step ",S+1);
//	}
	
	!!wait_request_for_help(S)
	.wait( default::actionID(S2) & S2 \== S & not action::reasoning_about_belief(_)); 
	
	-action::action(S,Action);
	
	?default::lastActionResult(Result);
	.print("Last action result was: ",Result);
		
	if (Action \== recharge & Action \== continue & not .substring("deliver",Action) & not .substring("assist_assemble",Action) & not .substring("buy",Action) & not .substring("bid_for_job",Action) & Result \== successful) {
		.print("Failed to execute action ",Action," at step ",S,". Executing it again.");
		!commit_action(Action);
	}
	else {
		if (.substring("deliver",Action) & Result == failed ) { !commit_action(Action); }
		if (.substring("deliver",Action) & Result \== failed_job_status & default::winner(_, assemble(_, JobId, _))) { +strategies::jobDone(JobId); }
		if (action::next_action(Action2)) {
			-action::next_action(Action2);
//			.print("Removing next action ",Action2);
		}
		else { 
			if (strategies::free) { !!action::recharge_is_new_skip; }
		}
	}
	.
+!commit_action(Action) : Action == recharge.
+!commit_action(Action) 
	: Action \== recharge & metrics::next_actions(C) & not action::next_action(_)
<- 
	+action::next_action(Action); 
	-+metrics::next_actions(C+1); 
	.print("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< Next action ",Action); 
	.wait( {-action::next_action(Action) }); 
	!commit_action(Action);
	.
	
@forgetAction[atomic]
+!forget_old_action(Step)
	: action::action(Step,Action)
<-
	.drop_intention(action::wait_request_for_help(Step));
	.drop_intention(action::commit_action(Action)); // we don't want to follow these plans anymore
	-action::action(Step,Action);
	!forget_old_action(Step);
	.
+!forget_old_action(Step).

+default::chosenActions(Step, Agents) // all the agents have chosen their actions
	: .length(Agents) == 34
<-
	.drop_intention(action::wait_request_for_help(Step));
	!send_action_to_server(Step);
	.
+!wait_request_for_help(Step)
<-
	.wait(1000);
	!send_action_to_server(Step);
	.	
	
@sendAction[atomic]
+!send_action_to_server(Step)
	: action::action(Step,Action)
<-
	.print("Sending ",Step," ",Action);
	action(Action);
	.
+!send_action_to_server(Step). // action already sent to the server

