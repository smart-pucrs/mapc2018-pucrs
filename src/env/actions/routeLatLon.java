package actions;

import jason.asSemantics.DefaultInternalAction;
import jason.asSemantics.TransitionSystem;
import jason.asSemantics.Unifier;
import jason.asSyntax.NumberTermImpl;
import jason.asSyntax.NumberTerm;
import jason.asSyntax.Term;
import massim.scenario.city.data.Location;
import massim.scenario.city.data.Route;
import env.MapHelper;

public class routeLatLon extends DefaultInternalAction {

	private static final long serialVersionUID = 8449365070235228618L;

	@Override
	public Object execute(TransitionSystem ts, Unifier un, Term[] args) throws Exception {

		// Define role (always first parameter)
		String role = args[0].toString();
		int speed 	= (int) ((NumberTerm) args[1]).solve();
		String type = "road";
		if(role.equals("drone")){
			type = "air";
		}

		Route route = null;
		String from = ts.getUserAgArch().getAgName();
		// Create a location with Lat (1) and Lon (2) parameter
		NumberTerm a1 = (NumberTerm) args[2];
		NumberTerm a2 = (NumberTerm) args[3];
		double locationLat = a1.solve();
		double locationLon = a2.solve();
		// Location is first LONGITUDE and then LATITUDE
		Location to = new Location(locationLon, locationLat);
//		route = MapHelper.getNewRoute(from, to, type);
		route = MapHelper.getInstance().getNewRoute(from, to, type);

		boolean ret = true;
		ret = ret & un.unifies(args[4], new NumberTermImpl(route.getRouteDuration(speed)));
		return ret;
	}
}