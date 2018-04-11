# PUCRS code for the MAPC of 2017

To start developing and contributing to this repository, open Eclipse, and select from the toolbar:

File > Import > Git > Projects from Git > Clone URI

Copy https://github.com/smart-pucrs/mapc2017-pucrs.git and paste it on the URI field.

The rest should autocomplete. Add your github credentials in the Authentication fields.   
Next > Tick master > Next > Select destination folder, do not tick clonesubmodules, remote name: origin > Next > Receiving objects (after that select import existing Eclipse projects) > Next > Tick macontest2017 and search for nested projects, do not tick add project to working sets > Finish

Right click on the project and select Team to access git commands (commit, push, and pull).

Pull whenever you see new commits in order to keep your local version up to date.

If you only wish to run the current code, then download the zip, extract it to a folder, and import that folder as an existing project to Eclipse.


To run the simulation with one round, right-click test/pucrs.agentcontest2017/ScenarioRun1sim.java file, "Run as", "jUnit Test".

To run the simulation with three rounds, right-click test/pucrs.agentcontest2017/ScenarioRun3sims.java file, "Run as", "jUnit Test".

To run the simulation with one round and two teams, right-click test/pucrs.agentcontest2017/ScenarioRun1sim2teams.java file, "Run as", "jUnit Test". This will start the server and Team A. Then, to start Team B, right-click pucrs-mapc2017B.jcm, "Run JaCaMo Application".

To watch the match click [this link](http://localhost:8000/).

To start the match, press enter on the Eclipse console.
