package actions;

import jason.asSemantics.DefaultInternalAction;
import jason.asSemantics.TransitionSystem;
import jason.asSemantics.Unifier;
import jason.asSyntax.NumberTermImpl;
import jason.asSyntax.Term;

public class getAgentNumber extends DefaultInternalAction {

	private static final long serialVersionUID = 1L;

	@Override
	@SuppressWarnings("deprecation")
	public Object execute(TransitionSystem ts, Unifier un, Term[] args) throws Exception {
		String agent  = args[0].toString();
		un.unifies(args[1], new NumberTermImpl(agent.substring(7)));
		return true;
	}
}
