package portal;

import java.sql.*; // JDBC stuff.
import java.util.Map;
import java.util.Objects;
import java.util.Properties;
import javax.tools.JavaFileObject;



public class PortalConnection {

    // For connecting to the portal database on your local machine
    static final String DATABASE = "jdbc:postgresql://localhost/portal";
    static final String USERNAME = "postgres";
    static final String PASSWORD = "postgres";
    
    // For connecting to the chalmers database server (from inside chalmers)
    // static final String DATABASE = "jdbc:postgresql://ate.ita.chalmers.se/";
    // static final String USERNAME = "tda357_nnn";
    // static final String PASSWORD = "yourPasswordGoesHere";

    //SQLINSERT CODE a bunch of them isnt needed but better be safe then sorry
    private static final String SQL_INSERT = "INSERT INTO Registrations(student, Course) VALUES (?, ?)";
    private static final String SQL_DELETE = "DELETE FROM Registrations WHERE student = ? AND course = ?";
    private static final String SQL_SELECT = "SELECT STUDENT FROM Registrations WHERE student = ? AND course = ?";
    private static final String SQL_SELECT_INFO = "SELECT * FROM BasicInformation WHERE IDNR = ?";
    private static final String SQL_SELECT_FINISHED = "SELECT * FROM FinishedCourses WHERE student = ?";
    private static final String SQL_SELECT_REGISTERED = "SELECT * FROM Registered WHERE student = ?";
    private static final String SQL_SELECT_WAITINGLIST = "SELECT * FROM WaitIngList WHERE student = ?";
    private static final String SQL_SELECT_PATHTOGRADUTATE = "SELECT * FROM PathToGraduation WHERE student = ?";
    private static final String SQL_DELETE_ALL = "DELETE * FROM Registrations";
    private static final String SQL_JSON = "with\r\n" + 
    		"     temp1 AS (SELECT json_build_object('course', Courses.NAME,'code', taken.course, 'credits', Courses.credits, 'grade', taken.grade) AS FINISHED, Taken.STUDENT FROM taken LEFT OUTER JOIN Courses ON CODE = Taken.course where GRADE not like 'U'),\r\n" + 
    		"     temp2 AS (SELECT JSON_BUILD_OBJECT('course', Courses.NAME,'code', registrations.course, 'status', registrations.status, 'position', CourseQueuePositions.place) AS REGISTERED, Registrations.STUDENT FROM Registrations left outer join Courses on CODE = COURSE left outer join CourseQueuePositions on Registrations.STUDENT = CourseQueuePositions.student AND CourseQueuePositions.course = CODE),\r\n" + 
    		"     temp7 AS (SELECT PathToGraduation.qualified AS canGraduate, PathToGraduation.student FROM pathtograduation)\r\n" + 
    		"select json_build_object(\r\n" + 
    		"    'student',IDNR,\r\n" + 
    		"    'name', NAME,\r\n" + 
    		"    'login', LOGIN,\r\n" + 
    		"    'program', PROGRAM,\r\n" + 
    		"    'branch', BRANCH,\r\n" + 
    		"    'finished', (SELECT coalesce(jsonb_agg(FINISHED), '[]') FROM temp1 WHERE IDNR = temp1.student),\r\n" + 
    		"    'registered', (SELECT coalesce(jsonb_agg(REGISTERED), '[]') FROM temp2 WHERE IDNR = temp2.STUDENT),\r\n" + 
    		"    'seminarCourses', (select PathToGraduation.seminarCourses FROM PathToGraduation WHERE IDNR = PathToGraduation.student),\r\n" + 
    		"    'mathCredits', (select mathCredits from PathToGraduation WHERE IDNR = PathToGraduation.student),\r\n" + 
    		"    'researchCredits', (SELECT PathToGraduation.researchCredits FROM PathToGraduation WHERE IDNR = PathToGraduation.student),\r\n" + 
    		"    'totalCredits', (SELECT PathToGraduation.researchCredits FROM PathToGraduation WHERE IDNR = PathToGraduation.student),\r\n" + 
    		"    'canGraduate' ,(SELECT canGraduate FROM TEMP7 WHERE IDNR = TEMP7.student)) AS StudentInformation\r\n" + 
    		"FROM BasicInformation WHERE IDNR = ?\r\n" + 
    		"group by BasicInformation.IDNR, NAME, LOGIN, PROGRAM, BRANCH";
    
  
  

    // This is the JDBC connection object you will be using in your methods.
    private Connection conn;

    public PortalConnection() throws SQLException, ClassNotFoundException {
        this(DATABASE, USERNAME, PASSWORD);  
    }

    // Initializes the connection, no need to change anything here
    public PortalConnection(String db, String user, String pwd) throws SQLException, ClassNotFoundException {
        Class.forName("org.postgresql.Driver");
        Properties props = new Properties();
        props.setProperty("user", user);
        props.setProperty("password", pwd);
        conn = DriverManager.getConnection(db, props);
    }


    // Register a student on a course, returns a tiny JSON document (as a String)
    public String register(String student, String courseCode){
    	try(
    		PreparedStatement ps = conn.prepareStatement(SQL_INSERT)){
    		//puts student and courseCode as sid and code(dont need theese but there for fun)
    		String sid = student;
			String code = courseCode;
			ps.setString(1,sid);
			ps.setString(2,code);
			int rs = ps.executeUpdate();
			//checks return of execute update since it always returns something when it executed the statement
			 if(rs > 0 ) {
		        	System.out.println("You are now registered to the course, Course was :" + courseCode);
		        }else {
		        	System.out.println("You were not registered for the course : " + courseCode);
		        }
			
		//if you get raise exception take the message and print it out
        } catch (SQLException e) {
           return "{\"success\":false, \"error\":\""+getError(e)+"\"}";
        }
    	//returns a tiny JSON FILE AS STRING
    	return "{\"success\":true}";
    
    }
      


    // Unregister a student from a course, returns a tiny JSON document (as a String)
    public String unregister(String student, String courseCode) throws SQLException{
    	//puts student and courseCode as sid and code(dont need theese but there for fun)
    	String sid = student;
		String code = courseCode;
    	String query = "DELETE FROM Registrations WHERE student= '" +sid+ "' AND course='" +code+ "'";
    			try (Statement s = conn.createStatement();){
    			int r = s.executeUpdate(query);
    			//print out how many deletions
    			System.out.println("Deleted "+r+" registrations.");
    			//if you were registered to the course it will be printed out 
    			 if(r > 0 ) {
 		        	System.out.println("You are now removed from the course, Course was :" + courseCode);
 		        }else {
 		        	System.out.println("You were not registered for the course : " + courseCode);
 		        	return "{\"Removed\":false}";
 		        }
    			 
    			}catch (SQLException e) {
    	               return "{\"success\":false, \"error\":\""+getError(e)+"\"}";
    	           	
                }
    	
    	return "{\"success\":true}";
    	}
    	
    	
    

    // Return a JSON document containing lots of information about a student, it should validate against the schema found in information_schema.json
	public String getInfo(String student) throws SQLException{
		try(PreparedStatement st = conn.prepareStatement(SQL_JSON);){
			String sid = student;
	    	st.setString(1,sid);
	    	ResultSet rs = st.executeQuery();
    	if(rs.next())
            return rs.getString("studentinformation");
          else
            return "{\"student\":\"does not exist :(\"}"; 
          
    }
    }
            

    // This is a hack to turn an SQLException into a JSON string error message. No need to change.
    public static String getError(SQLException e){
       String message = e.getMessage();
       int ix = message.indexOf('\n');
       if (ix > 0) message = message.substring(0, ix);
       message = message.replace("\"","\\\"");
       return message;
    }
}