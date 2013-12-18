//
// VW Java Tomcat BlazeDS webapp
//
// Chris Kennedy 2009 (C)
//

import vw.videoResult;

import java.util.List;
import java.util.ArrayList;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.ResourceBundle;

public class vw {
	public String DBtype;
	public String DBhost;
	public String DBport;
	public String DBusr;
	public String DBpwd;
	public Integer ResultLimit;
	private String DB;
	private String DBurl;
	private String sql;
	
	// Main AMF RemoteObject function from actionscript code
	public List getVideoDB(String clientSearch) {
		try {
			ResourceBundle vwCfg = ResourceBundle.getBundle("vw");

			// Database Type
			try {
				DBtype = vwCfg.getString("DBtype");
			} catch(Exception e) {
				DBtype = "mysql";
			}
			
			// Database Host
			try {
				DBhost = vwCfg.getString("DBhost");
			} catch(Exception e) {
				DBtype = "localhost";
			}
			
			// Database Port
			try {
				DBport = vwCfg.getString("DBport");
			} catch(Exception e) {
				DBport = "1521";
			}
			
			// Database User
			try {
				DBusr = vwCfg.getString("DBusr");
			} catch(Exception e) {
				DBusr = "vw";
			}
			
			// Database Password
			try {
				DBpwd = vwCfg.getString("DBpwd");
			} catch(Exception e) {
				DBpwd = "videowall";
			}
			
			// Database Result Limit
			try {
				ResultLimit = (Integer) vwCfg.getObject("ResultLimit");
			} catch(Exception e) {
				ResultLimit = 10000;
			}
		} catch(Exception e) {
			e.printStackTrace();	
		}

		chooseDB(DBtype, clientSearch);
		return getSQLResults();  
	}  

	// Set DB Type, either mysql or oracle supported
	private void chooseDB(String db, String clientSearch) {
		if (db.equals("mysql")) {
			// for MySQL
			DB = "com.mysql.jdbc.Driver";
			DBurl = "jdbc:mysql://" + DBhost + "/vw";
			sql = "SELECT id, location, image, annotation FROM videos " +
				"WHERE (UCASE(annotation) REGEXP UCASE('" + clientSearch + "') " +
				"OR UCASE(location) REGEXP UCASE('" + clientSearch + "') " +
				"OR UCASE(image) REGEXP UCASE('" + clientSearch + "')) " +
				"AND id > ? AND id <= ? ORDER BY id";
		} else if (db.equals("oracle")) {
			// for Oracle
			DB = "oracle.jdbc.driver.OracleDriver";
			DBurl = "jdbc:oracle:thin:@" + DBhost + ":" + DBport + ":vw";
			sql = "SELECT id, location, image, annotation FROM videos " +
				"WHERE (REGEXP_INSTR(annotation, " + clientSearch + ", 1, 1, 0, 'i') " +
				"OR REGEXP_INSTR(location, " + clientSearch + ", 1, 1, 0, 'i') " +
				"OR REGEXP_INSTR(image, " + clientSearch + ", 1, 1, 0, 'i')) " +
				"AND id > ? AND id <= ? ORDER BY id";
		} else
			 System.out.println("Unknown DB Type: '" + db + "'");

		return;
	}

	// Make SQL Query get results
	private List<videoResult> getSQLResults() {
		Connection c = null;
                List<videoResult> list = new ArrayList<videoResult>();

		try {
                        Class.forName(DB);
                } catch (Exception e) {
                        e.printStackTrace();
                }

                try {
                        c = DriverManager.getConnection(DBurl, DBusr, DBpwd);
                        PreparedStatement stmt = c.prepareStatement(sql);
			stmt.setInt(1, 0);
			stmt.setInt(2, ResultLimit);
                        ResultSet rs = stmt.executeQuery();

                        while (rs.next()) {
                                videoResult ce = new videoResult(
					rs.getString("location"),
					rs.getString("image"),
					rs.getString("annotation")
				);
                                list.add(ce);
                        }
                } catch (SQLException e) {
                        e.printStackTrace();
                } finally {
                        try {
				if (c != null)
					c.close();
                        } catch (Exception ignored) {
                        }
                }
		return list;
	}
}

