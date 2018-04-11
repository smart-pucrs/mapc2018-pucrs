package actions;

import jason.asSemantics.DefaultInternalAction;
import jason.asSemantics.TransitionSystem;
import jason.asSemantics.Unifier;
import jason.asSyntax.NumberTermImpl;
import jason.asSyntax.Term;
import env.TeamArtifact;

public class getItemQty extends DefaultInternalAction {

	private static final long serialVersionUID = 1348794053015642399L;

	@Override
	public Object execute(TransitionSystem ts, Unifier un, Term[] args) throws Exception {
		String item = args[0].toString();
		un.unifies(args[1], new NumberTermImpl(TeamArtifact.getItemQty(item)));
		return true;
	}
}
