package actions;

import jason.asSemantics.DefaultInternalAction;
import jason.asSemantics.TransitionSystem;
import jason.asSemantics.Unifier;
import jason.asSyntax.NumberTermImpl;
import jason.asSyntax.Term;
import massim.scenario.city.data.Location;
import massim.scenario.city.data.Route;

import env.MapHelper;

public class route extends DefaultInternalAction {

	private static final long serialVersionUID = -5795941336220230870L;

	// There are three ways to call this function:
	//////// pucrs.agentcontest2016.actions.route(Role, Speed, FacilityId, RouteLen)
	// This returns the route length from current agent position to Facility indicated by FacilityId
	//////// pucrs.agentcontest2016.actions.route(Role, Speed, FacilityId1, FacilityId2, RouteLen)
	// This returns the route length from Facility indicated by FacilityId1 to FacilityId2
	//////// pucrs.agentcontest2016.actions.route(Role, Speed, Lat, Lon, FacilityId, RouteLen)
	// This returns the route length from location indicated by (Lat, Lon) to Facility (FacilityId)
	@Override
	public Object execute(TransitionSystem ts, Unifier un, Term[] args) throws Exception {

		// Define role (always first parameter)
		String role = args[0].toString();
		int speed 	= Integer.valueOf(args[1].toString());
		String type = "road";
		if (role.equals("drone")) {
			type = "air";
		}

		Route route = null;
		if (args.length == 4){
			String from = ts.getUserAgArch().getAgName();
			String to = args[2].toString();
//			route = MapHelper.getNewRoute(from, to, type);
			route = MapHelper.getInstance().getNewRoute(from, to, type);
		} else if (args.length == 5) {
			String from = args[2].toString();
			String to = args[3].toString();
//			route = MapHelper.getNewRoute(from, to, type);
			route = MapHelper.getInstance().getNewRoute(from, to, type);
		} else if (args.length == 6) {
			String from = args[2].toString();
			// Create a location with Lat (1) and Lon (2) parameter
			NumberTermImpl a1 = (NumberTermImpl) args[3];
			NumberTermImpl a2 = (NumberTermImpl) args[4];
			double locationLat = a1.solve();
			double locationLon = a2.solve();
			// Location is first LONGITUDE and then LATITUDE
			Location to = new Location(locationLon, locationLat);
//			route = MapHelper.getNewRoute(from, to, type);
			route = MapHelper.getInstance().getNewRoute(from, to, type);
		}
		else if (args.length == 7) {
			// Create a location with Lat (1) and Lon (2) parameter
			NumberTermImpl a1 = (NumberTermImpl) args[2];
			NumberTermImpl a2 = (NumberTermImpl) args[3];
			double locationLat = a1.solve();
			double locationLon = a2.solve();
			// Location is first LONGITUDE and then LATITUDE
			Location from = new Location(locationLon, locationLat);
			String to = args[4].toString();
//			route = MapHelper.getNewRoute(from, to, type);
			route = MapHelper.getInstance().getNewRoute(from, to, type);
		}
		else if (args.length == 8) {
			// Create a location with Lat (1) and Lon (2) parameter
			NumberTermImpl a1 = (NumberTermImpl) args[2];
			NumberTermImpl a2 = (NumberTermImpl) args[3];
			double locationLat = a1.solve();
			double locationLon = a2.solve();
			// Location is first LONGITUDE and then LATITUDE
			Location to = new Location(locationLon, locationLat);
			String from = ts.getUserAgArch().getAgName();
//			route = MapHelper.getNewRoute(from, to, type);
			route = MapHelper.getInstance().getNewRoute(from, to, type);
		}  else {
			return false;
		}

		boolean ret = true;
		// Return parameter (route length) is always the last parameter (args.length - 1)
		ret = ret & un.unifies(args[args.length - 1], new NumberTermImpl(route.getRouteDuration(speed)));
		return ret;
	}
}