package env;

import java.io.File;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.logging.Logger;

import com.graphhopper.GHRequest;
import com.graphhopper.GHResponse;
import com.graphhopper.GraphHopper;
import com.graphhopper.routing.util.EncodingManager;
import com.graphhopper.util.PointList;
import com.graphhopper.util.shapes.GHPoint;
import com.graphhopper.util.shapes.GHPoint3D;

import massim.protocol.scenario.city.util.LocationUtil;
import massim.scenario.city.data.Location;
import massim.scenario.city.data.Route;

public class MapHelper {
	private static MapHelper instance;
	
	private Logger logger = Logger.getLogger(MapHelper.class.getName());
	
	private String mapName = null;
	private GraphHopper hopper = null;
	private Map<String, Location> locations = null;
	private double cellSize;
	private int proximity;

	public synchronized static MapHelper getInstance(){
		if (instance == null)
			instance = new MapHelper();
		return instance;
	}
	
	public void init(String newMapName, double cellSize, int proximity) {
		initCellSetting(cellSize, proximity);
		initMap(newMapName);
	}
	
	private void initCellSetting(double cellSize, int proximity){
		this.cellSize 	= cellSize;
		this.proximity 	= proximity;
	}
	
	private void initMap(String newMapName){
		if (newMapName.equals(this.mapName)) 
			return;
		this.mapName = newMapName;
		
		if (this.hopper != null)
			clean();
		
//		logger.info("Iniciando troca mapa");
		Location.setProximity(this.proximity);		
		this.locations = new HashMap<String, Location>();
		this.hopper = new GraphHopper().forDesktop();
		this.hopper.setOSMFile("osm" + File.separator + this.mapName + ".osm.pbf");
		this.hopper.setCHEnabled(false); // CH does not work with shortest weighting (at the moment)
		this.hopper.setGraphHopperLocation("graphsMapHelper" + File.separator + this.mapName);
		this.hopper.setEncodingManager(new EncodingManager("car"));
		this.hopper.importOrLoad();
//		logger.info("FInalizado troca mapa");
	}
	
	private void clean(){
		this.hopper.close();
		this.hopper = null;
		this.locations = null;
	}

	public GraphHopper getHopper() {
		return hopper;
	}

	public Location getLocation(String id) {
		return locations.get(id);
	}
	
	public Route getNewRoute(String from, String to, String type) {
		return getNewRoute(getLocation(from), getLocation(to), type);
	}
	
	public Route getNewRoute(Location from, String to, String type) {
		return getNewRoute(from, getLocation(to), type);
	}
	
	public Route getNewRoute(String from, Location to, String type) {
		return getNewRoute(getLocation(from), to, type);
	}

	public Route getNewRoute(Location from, Location to, String type) {
		if (from == null || to == null) {
			return null;
		}
		if (type.equals("air")) {
			return getNewAirRoute(from, to);
		} else if (type.equals("road")) {
			return getNewCarRoute(from, to);
		}
		logger.info("Cannot find a route with those permissions");
		return null;
	}

	private Route getNewAirRoute(Location from, Location to) {
		Route route = new Route();
		double fractions = getLength(from, to) / this.cellSize;
		Location loc = null;
		for (long i = 1; i <= fractions; i++) {
			loc = getIntermediateLoc(from, to, fractions, i);
			route.addPoint(loc);
		}
		if (!to.equals(loc)) {
			route.addPoint(to);
		}
		return route;
	}
	
	private Route getNewCarRoute(Location from, Location to) {

//		GHResponse rsp = queryGH(from, to);
		GHRequest req = new GHRequest(from.getLat(), from.getLon(), to.getLat(), to.getLon()).setWeighting("shortest").setVehicle("car");
		GHResponse rsp = getHopper().route(req);

		if (rsp.hasErrors()) {
			return null;
		}

		Route route = new Route();
		PointList pointList = rsp.getBest().getPoints();
		Iterator<GHPoint3D> pIterator = pointList.iterator();
		if (!pIterator.hasNext())
			return null;
		GHPoint prevPoint = pIterator.next();

		double remainder = 0;
		Location loc = null;
		while (pIterator.hasNext()) {
			GHPoint nextPoint = pIterator.next();
			double length = getLength(prevPoint, nextPoint);
			if (length == 0) {
				prevPoint = nextPoint;
				continue;
			}

			long i = 0;
			for (; i * this.cellSize + remainder < length; i++) {
				loc = getIntermediateLoc(prevPoint, nextPoint, length, i * this.cellSize + remainder);
				if (!from.equals(loc)) {
					route.addPoint(loc);
				}
			}
			remainder = i * this.cellSize + remainder - length;
			prevPoint = nextPoint;
		}

		if (!to.equals(loc)) {
			route.addPoint(to);
		}

		return route;
	}

	public double getLength(Location loc1, Location loc2) {
        return LocationUtil.calculateRange(loc1.getLat(), loc1.getLon(), loc2.getLat(), loc2.getLon());
	}
	
	
	public Location getIntermediateLoc(Location loc1, Location loc2, double fractions, long i) {
		double lon = (loc2.getLon() - loc1.getLon())*i/fractions + loc1.getLon();
		double lat = (loc2.getLat() - loc1.getLat())*i/fractions + loc1.getLat();
		return new Location(lon,lat);
	}
	
	
	public double getLength(GHPoint loc1, GHPoint loc2) {
        return LocationUtil.calculateRange(loc1.getLat(), loc1.getLon(), loc2.getLat(), loc2.getLon());
	}
	
	public Location getIntermediateLoc(GHPoint loc1, GHPoint loc2, double length, double i) {
		double lon = (loc2.getLon() - loc1.getLon())*i/length + loc1.getLon();
		double lat = (loc2.getLat() - loc1.getLat())*i/length + loc1.getLat();
		return new Location(lon,lat);
	}

	public boolean hasLocation(String name) {
		return locations.containsKey(name);
	}

	public void addLocation(String name, Location location) {
		locations.put(name, location);
	}
}
